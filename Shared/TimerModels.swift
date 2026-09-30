import Foundation

/// 지금 도는 타이머. 하나만 돈다.
struct RunningTimer: Codable, Equatable {
    var alarmID: UUID
    var duration: TimeInterval
    var startDate: Date
    var endDate: Date

    var interval: ClosedRange<Date> { startDate...endDate }
    var title: String { TimerFormat.title(duration) }
    func isFinished(at date: Date = .now) -> Bool { date >= endDate }
    func matches(minutes: Int) -> Bool { duration == TimerFormat.seconds(minutes: minutes) }

    static var current: RunningTimer? {
        get { SharedDefaults.value(.runningTimer) }
        set { SharedDefaults.set(newValue, for: .runningTimer) }
    }
}

/// 앱에서 고치는 프리셋(분 단위). 홈 화면 위젯도 이 값을 쓴다.
enum PresetStore {
    static var minutes: [Int] {
        get {
            let saved: [Int] = SharedDefaults.value(.presets) ?? TimerLimits.defaultPresets
            return saved.count == TimerLimits.presetSlots ? saved : TimerLimits.defaultPresets
        }
        set { SharedDefaults.set(newValue.map(TimerLimits.clampMinutes), for: .presets) }
    }

    static func reset() { SharedDefaults.set(Optional<[Int]>.none, for: .presets) }
}

/// 잠금 화면 위젯이 쓸 프리셋 칸. 칸 번호로 가리키므로 프리셋 값을 고치면 위젯도 따라간다.
struct WidgetSelection: Codable, Equatable {
    /// 세 칸 위젯. 고른 순서대로 쌓이고, 넘치면 가장 먼저 고른 칸이 빠진다.
    var row = TimerLimits.defaultLockRowSlots
    /// 한 칸 위젯.
    var single = TimerLimits.defaultSingleSlot

    static var current: WidgetSelection {
        get { SharedDefaults.value(.widgetSelection) ?? WidgetSelection() }
        set { SharedDefaults.set(newValue, for: .widgetSelection) }
    }

    /// 위젯에는 프리셋 순서대로 놓는다.
    func rowMinutes(in presets: [Int]) -> [Int] {
        row.sorted().filter(presets.indices.contains).map { presets[$0] }
    }

    func singleMinutes(in presets: [Int]) -> Int {
        presets.indices.contains(single) ? presets[single] : TimerLimits.defaultSingle
    }

    mutating func toggleRow(_ slot: Int) {
        if let index = row.firstIndex(of: slot) {
            guard row.count > 1 else { return }
            row.remove(at: index)
        } else {
            row.append(slot)
            if row.count > TimerLimits.lockRowCount { row.removeFirst() }
        }
    }
}

/// 알람과 화면 동작.
struct AlarmSettings: Codable, Equatable {
    /// 앱에 든 소리 파일 이름. nil 이면 시스템 기본음.
    var soundFile: String?
    /// 알람 화면에 '다시' 버튼을 둔다. 누르면 같은 시간으로 다시 시작한다.
    var offersRepeat = true
    /// 타이머가 도는 동안 앱이 떠 있으면 화면이 꺼지지 않게 한다.
    var keepsScreenOn = true

    init() {}

    /// 항목이 늘어도 예전에 저장한 설정을 그대로 읽는다. 없는 항목만 기본값이 된다.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AlarmSettings()
        soundFile = try container.decodeIfPresent(String.self, forKey: .soundFile)
        offersRepeat = try container.decodeIfPresent(Bool.self, forKey: .offersRepeat) ?? defaults.offersRepeat
        keepsScreenOn = try container.decodeIfPresent(Bool.self, forKey: .keepsScreenOn) ?? defaults.keepsScreenOn
    }

    static var current: AlarmSettings {
        get { SharedDefaults.value(.alarmSettings) ?? AlarmSettings() }
        set { SharedDefaults.set(newValue, for: .alarmSettings) }
    }
}

enum TimerFormat {
    static func seconds(minutes: Int) -> TimeInterval {
        TimeInterval(minutes * TimerLimits.secondsPerMinute)
    }

    /// "1시간 30분", "10분", "45초" 처럼 기기 언어로.
    static func title(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        return formatter.string(from: seconds) ?? ""
    }

    /// 1시간 이상이면 시:분:초, 아니면 분:초.
    static func clock(_ seconds: TimeInterval) -> String {
        let duration = Duration.seconds(seconds)
        let hours = TimeInterval(TimerLimits.secondsPerMinute * TimerLimits.secondsPerMinute)
        return duration.formatted(.time(pattern: seconds >= hours ? .hourMinuteSecond : .minuteSecond))
    }
}
