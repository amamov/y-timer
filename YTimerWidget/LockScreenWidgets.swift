import AppIntents
import SwiftUI
import WidgetKit

/// 잠금 화면 원형 위젯에서 고르는 시간.
struct LockPresetConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "타이머 시간"

    @Parameter(title: "분", default: 10, inclusiveRange: (1, 999))
    var minutes: Int
}

/// 잠금 화면 직사각형 위젯의 세 칸. 기본은 IntentLiterals.lockRow 와 같다.
struct LockRowConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "타이머 세 칸"

    @Parameter(title: "첫째 (분)", default: 5, inclusiveRange: (1, 999))
    var first: Int

    @Parameter(title: "둘째 (분)", default: 10, inclusiveRange: (1, 999))
    var second: Int

    @Parameter(title: "셋째 (분)", default: 15, inclusiveRange: (1, 999))
    var third: Int

    var minutes: [Int] { [first, second, third] }

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$first)분 · \(\.$second)분 · \(\.$third)분")
    }
}

struct ConfiguredEntry<Config>: TimelineEntry {
    var date: Date
    var timer: RunningTimer?
    var configuration: Config
}

/// TimerProvider 와 같은 규칙: 도는 동안 한 칸, 끝나는 순간 한 칸.
struct ConfiguredProvider<Config: WidgetConfigurationIntent>: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ConfiguredEntry<Config> {
        ConfiguredEntry(date: .now, configuration: Config())
    }

    func snapshot(for configuration: Config, in context: Context) async -> ConfiguredEntry<Config> {
        ConfiguredEntry(date: .now, timer: RunningTimer.current, configuration: configuration)
    }

    func timeline(for configuration: Config, in context: Context) async -> Timeline<ConfiguredEntry<Config>> {
        guard let timer = RunningTimer.current, !timer.isFinished() else {
            return Timeline(entries: [ConfiguredEntry(date: .now, configuration: configuration)], policy: .never)
        }
        return Timeline(entries: [
            ConfiguredEntry(date: .now, timer: timer, configuration: configuration),
            ConfiguredEntry(date: timer.endDate, configuration: configuration),
        ], policy: .never)
    }
}

/// 잠금 화면 원형: 한 칸.
struct LockPresetWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "LockPresetWidget", intent: LockPresetConfiguration.self,
                               provider: ConfiguredProvider<LockPresetConfiguration>()) { entry in
            LockSingleView(minutes: entry.configuration.minutes, timer: entry.timer)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName(AppConfig.displayName)
        .description("한 칸")
        .supportedFamilies([.accessoryCircular])
    }
}

/// 잠금 화면 직사각형: 세 칸.
struct LockRowWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "LockRowWidget", intent: LockRowConfiguration.self,
                               provider: ConfiguredProvider<LockRowConfiguration>()) { entry in
            LockRowView(minutes: entry.configuration.minutes, timer: entry.timer)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName(AppConfig.displayName)
        .description("세 칸")
        .supportedFamilies([.accessoryRectangular])
    }
}
