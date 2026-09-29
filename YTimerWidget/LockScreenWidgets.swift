import SwiftUI
import WidgetKit

// 잠금 화면 위젯은 앱의 프리셋 편집에서 고른 칸을 쓴다.

/// 잠금 화면 원형: 한 칸.
struct LockPresetWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockSingleWidget", provider: TimerProvider()) { entry in
            LockSingleView(minutes: entry.selection.singleMinutes(in: entry.presets), date: entry.date, timer: entry.timer)
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
        StaticConfiguration(kind: "LockRowStaticWidget", provider: TimerProvider()) { entry in
            LockRowView(minutes: entry.selection.rowMinutes(in: entry.presets), date: entry.date, timer: entry.timer)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName(AppConfig.displayName)
        .description("세 칸")
        .supportedFamilies([.accessoryRectangular])
    }
}
