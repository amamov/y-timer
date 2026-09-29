import AppIntents
import SwiftUI
import WidgetKit

/// 제어 센터·잠금 화면 하단 버튼·액션 버튼에 둘 수 있는 한 칸짜리 버튼.
struct PresetControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(kind: "PresetControl", intent: PresetControlConfiguration.self) { configuration in
            ControlWidgetButton(action: StartTimerIntent(preset: configuration.preset)) {
                Label("\(configuration.preset.minutes)분 타이머", systemImage: "timer")
            }
        }
        .displayName("X-Timer 시작")
        .description("정한 시간으로 바로 타이머를 시작합니다.")
    }
}

struct PresetControlConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "X-Timer 시간"

    @Parameter(title: "시간", default: .m10)
    var preset: TimerPreset

    func perform() async throws -> some IntentResult { .result() }
}
