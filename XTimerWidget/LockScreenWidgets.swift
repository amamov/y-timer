import AppIntents
import SwiftUI
import WidgetKit

enum PresetRow: String, AppEnum {
    case short, long

    var presets: [TimerPreset] { self == .short ? [.m5, .m10, .m15] : [.m30, .m60, .m100] }

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "프리셋 묶음"
    static let caseDisplayRepresentations: [PresetRow: DisplayRepresentation] = [
        .short: "5 · 10 · 15분", .long: "30 · 60 · 100분",
    ]
}

struct LockPresetConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "X-Timer 시간"

    @Parameter(title: "시간", default: .m10)
    var preset: TimerPreset
}

struct LockRowConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "X-Timer 프리셋"

    @Parameter(title: "프리셋", default: .short)
    var row: PresetRow
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
        ConfiguredEntry(date: .now, timer: SharedStore.current, configuration: configuration)
    }

    func timeline(for configuration: Config, in context: Context) async -> Timeline<ConfiguredEntry<Config>> {
        guard let timer = SharedStore.current, !timer.isFinished() else {
            return Timeline(entries: [ConfiguredEntry(date: .now, configuration: configuration)], policy: .never)
        }
        return Timeline(entries: [
            ConfiguredEntry(date: .now, timer: timer, configuration: configuration),
            ConfiguredEntry(date: timer.endDate, configuration: configuration),
        ], policy: .never)
    }
}

/// 잠금 화면 원형: 누르면 정해 둔 시간으로 바로 시작, 도는 동안은 남은 시간 링.
struct LockPresetWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "LockPresetWidget", intent: LockPresetConfiguration.self,
                               provider: ConfiguredProvider<LockPresetConfiguration>()) { entry in
            LockPresetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("X-Timer 바로 시작")
        .description("잠금 화면에서 누르면 바로 시작합니다.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct LockPresetView: View {
    var entry: ConfiguredEntry<LockPresetConfiguration>

    var body: some View {
        if let timer = entry.timer {
            RunningRing(timer: timer)
        } else {
            let preset = entry.configuration.preset
            Button(intent: StartTimerIntent(preset: preset)) {
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: -2) {
                        Text(preset.label).font(.system(.title2, design: .rounded).weight(.bold))
                        Text("분").font(.caption2)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}

/// 잠금 화면 직사각형: 세 개를 나란히 두고 하나를 누르면 바로 시작.
struct LockRowWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "LockRowWidget", intent: LockRowConfiguration.self,
                               provider: ConfiguredProvider<LockRowConfiguration>()) { entry in
            LockRowView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("X-Timer 프리셋 세 개")
        .description("잠금 화면에서 세 가지 시간 중 하나를 눌러 바로 시작합니다.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct LockRowView: View {
    var entry: ConfiguredEntry<LockRowConfiguration>

    var body: some View {
        if let timer = entry.timer {
            HStack(spacing: 8) {
                RunningRing(timer: timer)
                VStack(alignment: .leading, spacing: 0) {
                    Text(timerInterval: timer.interval, countsDown: true)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .monospacedDigit()
                    Text("\(timer.endDate, style: .time) 종료").font(.caption2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(spacing: 6) {
                ForEach(entry.configuration.row.presets, id: \.self) { preset in
                    Button(intent: StartTimerIntent(preset: preset)) {
                        ZStack {
                            AccessoryWidgetBackground().clipShape(Circle())
                            Text(preset.label)
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct RunningRing: View {
    var timer: RunningTimer

    var body: some View {
        ProgressView(timerInterval: timer.interval, countsDown: true) {
            EmptyView()
        } currentValueLabel: {
            Text("\(timer.minutes)")
        }
        .progressViewStyle(.circular)
    }
}
