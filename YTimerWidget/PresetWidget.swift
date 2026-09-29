import AppIntents
import SwiftUI
import WidgetKit

struct TimerEntry: TimelineEntry {
    var date: Date
    var timer: RunningTimer?
    var presets = PresetStore.minutes
}

struct TimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimerEntry { TimerEntry(date: .now) }

    func getSnapshot(in context: Context, completion: @escaping (TimerEntry) -> Void) {
        completion(TimerEntry(date: .now, timer: RunningTimer.current))
    }

    /// 도는 동안 한 칸, 끝나는 순간 프리셋 화면으로 돌아가는 한 칸.
    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerEntry>) -> Void) {
        guard let timer = RunningTimer.current, !timer.isFinished() else {
            completion(Timeline(entries: [TimerEntry(date: .now)], policy: .never))
            return
        }
        completion(Timeline(
            entries: [TimerEntry(date: .now, timer: timer), TimerEntry(date: timer.endDate)],
            policy: .never
        ))
    }
}

/// 홈 화면 위젯: 앱에서 정한 프리셋. 누르면 앱을 열지 않고 바로 시작한다.
struct PresetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PresetWidget", provider: TimerProvider()) { entry in
            PresetWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetGlassBackground() }
        }
        .configurationDisplayName(AppConfig.displayName)
        .description("프리셋")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// 검은 유리판. 위쪽에 흰 빛이 살짝 번진다.
struct WidgetGlassBackground: View {
    var body: some View {
        ZStack {
            Color.black
            RadialGradient(colors: [.white.opacity(0.16), .clear], center: .topLeading, startRadius: 0, endRadius: 260)
            LinearGradient(colors: [.white.opacity(0.06), .clear], startPoint: .top, endPoint: .center)
        }
    }
}

struct PresetWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: TimerEntry
    private let columns = 3

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                HStack(spacing: 14) {
                    if let timer = entry.timer {
                        RunningSummary(timer: timer, compact: true)
                            .frame(maxWidth: .infinity)
                    }
                    PresetButtons(presets: entry.presets, columns: columns, running: entry.timer)
                        .frame(maxWidth: .infinity)
                }
            case .systemLarge:
                VStack(spacing: 18) {
                    if let timer = entry.timer {
                        RunningSummary(timer: timer, compact: false)
                    } else {
                        IdleHeader()
                    }
                    PresetButtons(presets: entry.presets, columns: columns, running: entry.timer)
                }
            default:
                if let timer = entry.timer {
                    RunningSummary(timer: timer, compact: true)
                } else {
                    PresetButtons(presets: entry.presets, columns: columns, running: nil)
                }
            }
        }
        .foregroundStyle(.white)
    }
}

struct IdleHeader: View {
    var body: some View {
        Text(AppConfig.wordmark)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .tracking(4)
            .foregroundStyle(Theme.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// 유리 버튼. 누른 칸 전체가 버튼이 되도록 label 이 칸을 꽉 채운다.
struct GlassChip: View {
    var minutes: Int
    var selected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(selected ? AnyShapeStyle(.white) : AnyShapeStyle(.white.opacity(0.10)))
            Circle()
                .strokeBorder(
                    LinearGradient(colors: [.white.opacity(selected ? 0 : 0.45), .white.opacity(0.05)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.8
                )
            Text("\(minutes)")
                .font(.system(size: 20, weight: selected ? .semibold : .regular, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .foregroundStyle(selected ? .black : .white)
                .widgetAccentable()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}

struct PresetButtons: View {
    var presets: [Int]
    var columns: Int
    var running: RunningTimer?

    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(Array(stride(from: 0, to: presets.count, by: columns)), id: \.self) { row in
                GridRow {
                    ForEach(Array(presets[row..<min(row + columns, presets.count)].enumerated()), id: \.offset) { _, minutes in
                        Button(intent: StartTimerIntent(minutes: minutes)) {
                            GlassChip(minutes: minutes, selected: running?.matches(minutes: minutes) == true)
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
    var compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 10) {
            HStack {
                Text(timer.title)
                    .font(Theme.caption)
                    .tracking(2)
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
                Spacer()
                Button(intent: StopTimerIntent(alarmID: timer.alarmID.uuidString)) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(.white.opacity(0.14)))
                        .overlay(Circle().strokeBorder(Theme.hairline, lineWidth: 0.6))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
            Text(timerInterval: timer.interval, countsDown: true)
                .font(Theme.number(compact ? 40 : 64))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .widgetAccentable()
            ProgressView(timerInterval: timer.interval, countsDown: true) { EmptyView() } currentValueLabel: { EmptyView() }
                .tint(.white)
            HStack(spacing: 4) {
                Text("경과")
                Text(timerInterval: timer.interval, countsDown: false)
                Spacer(minLength: 4)
                Text("\(timer.endDate, style: .time)")
            }
            .font(.system(size: 11, weight: .medium, design: .rounded).monospacedDigit())
            .foregroundStyle(Theme.secondary)
            .lineLimit(1)
        }
    }
}

/// 잠금 화면 시계 위 한 줄: 남은 시간.
struct TimerStatusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TimerStatusWidget", provider: TimerProvider()) { entry in
            TimerStatusView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName(AppConfig.displayName)
        .description("남은 시간")
        .supportedFamilies([.accessoryInline])
    }
}

struct TimerStatusView: View {
    var entry: TimerEntry

    var body: some View {
        if let timer = entry.timer {
            Label {
                Text(timerInterval: timer.interval, countsDown: true)
            } icon: {
                Image(systemName: "timer")
            }
        } else {
            Label(AppConfig.displayName, systemImage: "timer")
        }
    }
}
