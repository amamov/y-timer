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

/// 끝났을 때의 동작.
struct AlarmSettings: Codable, Equatable {
    /// 앱에 든 소리 파일 이름. nil 이면 시스템 기본음.
    var soundFile: String?
    /// 알람 화면에 '다시' 버튼을 둔다. 누르면 같은 시간으로 다시 시작한다.
    var offersRepeat = true

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
