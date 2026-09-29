import AlarmKit
import AppIntents

// LiveActivityIntent 라서 위젯에서 눌러도 앱을 열지 않고 앱 프로세스에서 돈다.
// 잠금 화면에서 눌러도 Face ID 없이 돌도록 authenticationPolicy 를 연다.

struct StartTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "타이머 시작"
    static let description = IntentDescription("정한 분만큼 바로 타이머를 시작합니다.")
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    // App Intents 는 기본값과 범위를 리터럴로만 받는다. TimerLimits 와 같은지는 IntentLiterals.verify() 가 확인한다.
    @Parameter(
        title: "분",
        default: 10,
        inclusiveRange: (1, 999),
        requestValueDialog: "몇 분으로 할까요?"
    )
    var minutes: Int

    init() {}
    init(minutes: Int) { self.minutes = minutes }

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$minutes)분 타이머 시작")
    }

    func perform() async throws -> some IntentResult {
        try await TimerService.start(minutes: minutes)
        return .result()
    }
}

/// 알람 화면의 '다시' 버튼. 같은 시간으로 다시 시작한다.
struct RepeatTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "타이머 다시 시작"
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed
    static let isDiscoverable = false

    @Parameter(title: "초")
    var seconds: Int

    init() {}
    init(duration: TimeInterval) { self.seconds = Int(duration) }

    func perform() async throws -> some IntentResult {
        try await TimerService.start(duration: TimeInterval(seconds))
        return .result()
    }
}

struct StopTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "타이머 끝내기"
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    @Parameter(title: "알람 ID")
    var alarmID: String?

    init() {}
    init(alarmID: String) { self.alarmID = alarmID }

    func perform() async throws -> some IntentResult {
        if let alarmID, let id = UUID(uuidString: alarmID) {
            try? AlarmManager.shared.stop(id: id)
        }
        TimerService.stop()
        return .result()
    }
}

/// 인텐트·위젯 설정에 리터럴로 적은 값이 TimerLimits 와 어긋나면 디버그 빌드에서 바로 멈춘다.
enum IntentLiterals {
    static let single = 10
    static let range = (1, 999)

    static func verify() {
        assert(single == TimerLimits.defaultSingle, "StartTimerIntent 기본값이 TimerLimits 와 다릅니다")
        assert(range.0 == TimerLimits.presetMinutes.lowerBound && range.1 == TimerLimits.presetMinutes.upperBound,
               "분 범위가 TimerLimits 와 다릅니다")
    }
}
