import AlarmKit
import AppIntents

/// LiveActivityIntent 라서 위젯에서 눌러도 앱을 열지 않고 앱 프로세스에서 돈다.
struct StartTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "타이머 시작"
    static let description = IntentDescription("정한 시간으로 바로 타이머를 시작합니다.")
    // 잠금 화면에서 눌러도 Face ID 없이 바로 돈다.
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    @Parameter(title: "시간", default: .m10)
    var preset: TimerPreset

    init() {}
    init(preset: TimerPreset) { self.preset = preset }

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$preset) 타이머 시작")
    }

    func perform() async throws -> some IntentResult {
        try await TimerService.start(preset)
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
