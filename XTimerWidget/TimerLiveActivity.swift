import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

/// AlarmKit 이 띄우는 Live Activity 의 모양. 잠금 화면, 상시표시, 다이내믹 아일랜드, 스탠바이에 뜬다.
struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<XTimerMetadata>.self) { context in
            LockScreenTimerView(minutes: context.attributes.metadata?.minutes, state: context.state)
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
                .activityBackgroundTint(.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let minutes = context.attributes.metadata?.minutes ?? 0
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("\(minutes)분")
                        .font(Theme.caption)
                        .tracking(2)
                        .foregroundStyle(Theme.secondary)
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    StopButton(alarmID: context.state.alarmID)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    TimerBody(state: context.state, large: false)
                        .padding(.horizontal, 6)
                }
            } compactLeading: {
                ProgressRing(state: context.state)
            } compactTrailing: {
                RemainingText(state: context.state)
                    .font(.system(size: 15, weight: .semibold, design: .rounded).monospacedDigit())
                    .frame(maxWidth: 52)
            } minimal: {
                ProgressRing(state: context.state)
            }
            .keylineTint(.white)
        }
    }
}

/// 원래 시작 시각. 일시정지가 있었어도 fireDate 에서 전체 길이를 빼면 된다.
private func interval(_ countdown: AlarmPresentationState.Mode.Countdown) -> ClosedRange<Date> {
    countdown.fireDate.addingTimeInterval(-countdown.totalCountdownDuration)...countdown.fireDate
}

struct LockScreenTimerView: View {
    var minutes: Int?
    var state: AlarmPresentationState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("X-TIMER · \(minutes ?? 0)분")
                    .font(Theme.caption)
                    .tracking(2)
                    .foregroundStyle(Theme.secondary)
                Spacer()
                StopButton(alarmID: state.alarmID)
            }
            TimerBody(state: state, large: true)
        }
        .foregroundStyle(.white)
    }
}

struct TimerBody: View {
    var state: AlarmPresentationState
    var large: Bool

    var body: some View {
        switch state.mode {
        case .countdown(let countdown):
            let range = interval(countdown)
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .lastTextBaseline) {
                    Text(timerInterval: range, countsDown: true)
                        .font(Theme.number(large ? 58 : 44))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 3) {
                        HStack(spacing: 4) {
                            Text("경과")
                            Text(timerInterval: range, countsDown: false)
                        }
                        Text("\(countdown.fireDate, style: .time) 종료")
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.secondary)
                }
                ProgressView(timerInterval: range, countsDown: true) { EmptyView() } currentValueLabel: { EmptyView() }
                    .tint(.white)
            }
        case .paused(let paused):
            Text("일시정지 · \(Duration.seconds(paused.totalCountdownDuration - paused.previouslyElapsedDuration).clock) 남음")
                .font(.system(size: 22, weight: .light, design: .rounded))
        case .alert:
            Text("끝났습니다")
                .font(.system(size: large ? 40 : 30, weight: .light, design: .rounded))
        @unknown default:
            EmptyView()
        }
    }
}

struct RemainingText: View {
    var state: AlarmPresentationState

    var body: some View {
        if case .countdown(let countdown) = state.mode {
            Text(timerInterval: interval(countdown), countsDown: true)
                .multilineTextAlignment(.trailing)
        } else {
            Text("끝")
        }
    }
}

struct ProgressRing: View {
    var state: AlarmPresentationState

    var body: some View {
        if case .countdown(let countdown) = state.mode {
            ProgressView(timerInterval: interval(countdown), countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.circular)
            .tint(.white)
        } else {
            Image(systemName: "bell.fill").foregroundStyle(.white)
        }
    }
}

struct StopButton: View {
    var alarmID: UUID

    var body: some View {
        Button(intent: StopTimerIntent(alarmID: alarmID.uuidString)) {
            Image(systemName: "stop.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Circle().fill(.white.opacity(0.16)))
                .overlay(Circle().strokeBorder(Theme.hairline, lineWidth: 0.7))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
