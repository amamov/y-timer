import AppIntents
import SwiftUI
import WidgetKit

/// 제어 센터·잠금 화면 하단 버튼·액션 버튼에 둘 수 있는 한 칸짜리 버튼.
struct PresetControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(kind: "PresetControl", intent: PresetControlConfiguration.self) { configuration in
            ControlWidgetButton(action: StartTimerIntent(minutes: configuration.minutes)) {
                Label(TimerFormat.title(TimerFormat.seconds(minutes: configuration.minutes)), systemImage: "timer")
            }
        }
        .displayName("\(AppConfig.displayName) 시작")
        .description("정한 분만큼 바로 타이머를 시작합니다.")
    }
}

struct PresetControlConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "타이머 시간"

    @Parameter(title: "분", default: 10, inclusiveRange: (1, 999))
    var minutes: Int

    func perform() async throws -> some IntentResult { .result() }
}
