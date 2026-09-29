import AppIntents
import SwiftUI
import WidgetKit

struct TimerEntry: TimelineEntry {
    var date: Date
    var timer: RunningTimer?
}

struct TimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimerEntry { TimerEntry(date: .now) }

    func getSnapshot(in context: Context, completion: @escaping (TimerEntry) -> Void) {
        completion(TimerEntry(date: .now, timer: SharedStore.current))
    }

    /// 도는 동안 한 칸, 끝나는 순간 프리셋 화면으로 돌아가는 한 칸.
    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerEntry>) -> Void) {
        guard let timer = SharedStore.current, !timer.isFinished() else {
            completion(Timeline(entries: [TimerEntry(date: .now)], policy: .never))
            return
        }
        completion(Timeline(
            entries: [TimerEntry(date: .now, timer: timer), TimerEntry(date: timer.endDate)],
            policy: .never
        ))
    }
}

/// 홈 화면 위젯: 누르면 앱을 열지 않고 바로 시작한다.
struct PresetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PresetWidget", provider: TimerProvider()) { entry in
            PresetWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("X-Timer")
        .description("누르면 바로 시작합니다.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct PresetWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: TimerEntry

    var body: some View {
        switch family {
        case .systemMedium:
            HStack(spacing: 12) {
                if let timer = entry.timer {
                    RunningSummary(timer: timer).frame(maxWidth: .infinity)
                }
                PresetButtons(columns: entry.timer == nil ? 6 : 3, selected: entry.timer?.minutes)
            }
        case .systemLarge:
            VStack(spacing: 16) {
                if let timer = entry.timer {
                    RunningSummary(timer: timer).frame(maxHeight: .infinity)
                }
                PresetButtons(columns: 3, selected: entry.timer?.minutes)
            }
        default:
            if let timer = entry.timer {
                RunningSummary(timer: timer)
            } else {
                PresetButtons(columns: 3, selected: nil)
            }
        }
    }
}

struct PresetButtons: View {
    var columns: Int
    var selected: Int?

    var body: some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            ForEach(Array(stride(from: 0, to: TimerPreset.allCases.count, by: columns)), id: \.self) { row in
                GridRow {
                    ForEach(TimerPreset.allCases[row..<min(row + columns, TimerPreset.allCases.count)], id: \.self) { preset in
                        Button(intent: StartTimerIntent(preset: preset)) {
                            Text(preset.label)
                                .font(.system(.title3, design: .rounded).weight(.bold))
                                .minimumScaleFactor(0.6)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .foregroundStyle(selected == preset.minutes ? .black : .white)
                                .background(
                                    Circle().fill(selected == preset.minutes ? TimerService.tint : Color.white.opacity(0.14))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct RunningSummary: View {
    var timer: RunningTimer

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(timer.minutes)분").font(.caption.weight(.semibold)).foregroundStyle(TimerService.tint)
                Spacer()
                Button(intent: StopTimerIntent(alarmID: timer.alarmID.uuidString)) {
                    Image(systemName: "stop.fill").font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
            Text(timerInterval: timer.interval, countsDown: true)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            HStack(spacing: 4) {
                Text("경과")
                Text(timerInterval: timer.interval, countsDown: false).monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            ProgressView(timerInterval: timer.interval, countsDown: true) { EmptyView() } currentValueLabel: { EmptyView() }
                .tint(TimerService.tint)
            Text("\(timer.endDate, style: .time) 종료")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
    }
}

/// 잠금 화면 위젯: 남은 시간과 진행을 보여 준다.
struct TimerStatusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TimerStatusWidget", provider: TimerProvider()) { entry in
            TimerStatusView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("X-Timer 상태")
        .description("남은 시간을 잠금 화면에 보여 줍니다.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct TimerStatusView: View {
    @Environment(\.widgetFamily) private var family
    var entry: TimerEntry

    var body: some View {
        if let timer = entry.timer {
            switch family {
            case .accessoryCircular:
                ProgressView(timerInterval: timer.interval, countsDown: true) {
                    EmptyView()
                } currentValueLabel: {
                    Text("\(timer.minutes)")
                }
                .progressViewStyle(.circular)
            case .accessoryInline:
                Text(timerInterval: timer.interval, countsDown: true)
            default:
                VStack(alignment: .leading, spacing: 2) {
                    Text(timerInterval: timer.interval, countsDown: true)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .monospacedDigit()
                    ProgressView(timerInterval: timer.interval, countsDown: true) { EmptyView() } currentValueLabel: { EmptyView() }
                }
            }
        } else {
            switch family {
            case .accessoryInline:
                Label("X-Timer", systemImage: "timer")
            default:
                Image(systemName: "timer").font(.title2)
            }
        }
    }
}
