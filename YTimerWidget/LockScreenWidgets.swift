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

// 잠금 화면에서는 버튼 label 을 눌러야만 인텐트가 돌고, 그 밖을 누르면 앱이 열린다.
// 그래서 배경은 버튼 바깥에 두고 label 이 칸 전체를 채우게 한다.
// 참고: https://github.com/home-assistant/iOS/pull/5647

/// 잠금 화면 원형: 누르면 정해 둔 시간으로 바로 시작, 도는 동안은 남은 시간 링.
struct LockPresetWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "LockPresetWidget", intent: LockPresetConfiguration.self,
                               provider: ConfiguredProvider<LockPresetConfiguration>()) { entry in
            LockPresetView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("\(AppConfig.displayName) 바로 시작")
        .description("잠금 화면에서 누르면 잠금 해제 없이 바로 시작합니다.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct LockPresetView: View {
    var entry: ConfiguredEntry<LockPresetConfiguration>

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let timer = entry.timer {
                RunningRing(timer: timer)
            } else {
                let minutes = entry.configuration.minutes
                Button(intent: StartTimerIntent(minutes: minutes)) {
                    VStack(spacing: -3) {
                        Text("\(minutes)")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .minimumScaleFactor(0.6)
                        Text("분").font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }
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
        .configurationDisplayName("\(AppConfig.displayName) 세 칸")
        .description("세 칸의 분을 직접 정하고, 잠금 화면에서 눌러 잠금 해제 없이 바로 시작합니다.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct LockRowView: View {
    var entry: ConfiguredEntry<LockRowConfiguration>

    var body: some View {
        if let timer = entry.timer {
            HStack(spacing: 10) {
                RunningRing(timer: timer)
                VStack(alignment: .leading, spacing: 0) {
                    Text(timerInterval: timer.interval, countsDown: true)
                        .font(.system(size: 26, weight: .semibold, design: .rounded).monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("\(timer.endDate, style: .time) 종료")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .opacity(0.7)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(spacing: 6) {
                ForEach(Array(entry.configuration.minutes.enumerated()), id: \.offset) { _, minutes in
                    ZStack {
                        AccessoryWidgetBackground().clipShape(Circle())
                        Button(intent: StartTimerIntent(minutes: minutes)) {
                            Text("\(minutes)")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .minimumScaleFactor(0.6)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
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
            Text(timerInterval: timer.interval, countsDown: true)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .progressViewStyle(.circular)
    }
}
