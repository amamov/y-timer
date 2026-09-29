import ActivityKit
import AlarmKit
import SwiftUI
import WidgetKit

/// AlarmKit 이 띄우는 Live Activity. 잠금 화면, 상시표시, 다이내믹 아일랜드, 스탠바이에 뜬다.
struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<YTimerMetadata>.self) { context in
            LiveActivityPanel(duration: context.attributes.metadata?.duration, state: context.state)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .activityBackgroundTint(.black.opacity(0.55))
                .activitySystemActionForegroundColor(Theme.ink)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Eyebrow(text: context.attributes.metadata.map { TimerFormat.title($0.duration) } ?? AppConfig.wordmark)
                        .padding(.leading, 6)
                        .padding(.top, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    StopChip(alarmID: context.state.alarmID, diameter: 34)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    IslandExpandedBottom(state: context.state)
                        .padding(.horizontal, 6)
                }
            } compactLeading: {
                IslandRing(state: context.state)
            } compactTrailing: {
                IslandRemaining(state: context.state)
                    .font(.system(size: 15, weight: .semibold, design: .rounded).monospacedDigit())
                    .frame(width: 48)
            } minimal: {
                IslandRing(state: context.state)
            }
            .keylineTint(Theme.ink)
        }
    }
}
