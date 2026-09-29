import AppIntents
import SwiftUI
import WidgetKit

struct TimerEntry: TimelineEntry {
    var date: Date
    var timer: RunningTimer?
    var presets = PresetStore.minutes
    var selection = WidgetSelection.current
}

struct TimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimerEntry { TimerEntry(date: .now) }

    func getSnapshot(in context: Context, completion: @escaping (TimerEntry) -> Void) {
        completion(TimerEntry(date: .now, timer: RunningTimer.current))
    }

    /// 도는 동안은 다이얼이 줄어드는 칸들, 끝나는 순간 프리셋 화면으로 돌아가는 한 칸.
    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerEntry>) -> Void) {
        guard let timer = RunningTimer.current, !timer.isFinished() else {
            completion(Timeline(entries: [TimerEntry(date: .now)], policy: .never))
            return
        }
        let range = TimerLimits.dialStepRange
        let step = min(max(timer.duration / Double(TimerLimits.dialSteps), range.lowerBound), range.upperBound)
        let dates = stride(from: Date.now, to: timer.endDate, by: step)
        completion(Timeline(
            entries: dates.map { TimerEntry(date: $0, timer: timer) } + [TimerEntry(date: timer.endDate)],
            policy: .never
        ))
    }
}

/// 홈 화면 위젯: 앱에서 정한 프리셋.
struct PresetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PresetWidget", provider: TimerProvider()) { entry in
            PresetWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) { WidgetGlassBackground() }
        }
        .configurationDisplayName(AppConfig.displayName)
        .description("프리셋")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct PresetWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: TimerEntry

    var body: some View {
        HomeWidgetView(size: size, date: entry.date, timer: entry.timer, presets: entry.presets)
    }

    private var size: HomeWidgetSize {
        switch family {
        case .systemMedium: .medium
        case .systemLarge: .large
        default: .small
        }
    }
}

/// 잠금 화면 시계 위 한 줄: 남은 시간.
struct TimerStatusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TimerStatusWidget", provider: TimerProvider()) { entry in
            Group {
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
            .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName(AppConfig.displayName)
        .description("남은 시간")
        .supportedFamilies([.accessoryInline])
    }
}
