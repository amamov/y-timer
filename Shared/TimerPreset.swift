import AppIntents

/// 그래비티 타이머의 여섯 면과 같은 프리셋.
enum TimerPreset: Int, CaseIterable, AppEnum {
    case m5 = 5, m10 = 10, m15 = 15, m30 = 30, m60 = 60, m100 = 100

    var minutes: Int { rawValue }
    var duration: TimeInterval { TimeInterval(rawValue * 60) }
    var label: String { "\(rawValue)" }

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "타이머 시간"
    static let caseDisplayRepresentations: [TimerPreset: DisplayRepresentation] = [
        .m5: "5분", .m10: "10분", .m15: "15분", .m30: "30분", .m60: "60분", .m100: "100분",
    ]
}
