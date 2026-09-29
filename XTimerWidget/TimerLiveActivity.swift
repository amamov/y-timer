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
                .padding(20)
                .activityBackgroundTint(.black.opacity(0.8))
                .activitySystemActionForegroundColor(TimerService.tint)
        } dynamicIsland: { context in
            let minutes = context.attributes.metadata?.minutes
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("\(minutes ?? 0)분", systemImage: "timer")
                        .font(.headline)
                        .foregroundStyle(TimerService.tint)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    StopButton(alarmID: context.state.alarmID)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    TimerBody(state: context.state, large: false)
                }
            } compactLeading: {
                Image(systemName: "timer").foregroundStyle(TimerService.tint)
            } compactTrailing: {
                RemainingText(state: context.state)
                    .frame(maxWidth: 56)
                    .foregroundStyle(TimerService.tint)
            } minimal: {
                ProgressRing(state: context.state)
            }
            .keylineTint(TimerService.tint)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("\(minutes ?? 0)분 타이머", systemImage: "timer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TimerService.tint)
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
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(timerInterval: range, countsDown: true)
                        .font(.system(size: large ? 52 : 40, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("경과")
                            Text(timerInterval: range, countsDown: false).monospacedDigit()
                        }
                        HStack(spacing: 0) {
                            Text(countdown.fireDate, style: .time)
                            Text(" 종료")
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                ProgressView(timerInterval: range, countsDown: true) { EmptyView() } currentValueLabel: { EmptyView() }
                    .tint(TimerService.tint)
            }
        case .paused(let paused):
            Text("일시정지 · \(Duration.seconds(paused.totalCountdownDuration - paused.previouslyElapsedDuration), format: .time(pattern: .minuteSecond)) 남음")
                .font(.title2.weight(.bold))
        case .alert:
            Text("끝났습니다")
                .font(.system(size: large ? 44 : 32, weight: .bold, design: .rounded))
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
                .monospacedDigit()
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
                Image(systemName: "timer")
            }
            .progressViewStyle(.circular)
            .tint(TimerService.tint)
        } else {
            Image(systemName: "bell.fill").foregroundStyle(TimerService.tint)
        }
    }
}

struct StopButton: View {
    var alarmID: UUID

    var body: some View {
        Button(intent: StopTimerIntent(alarmID: alarmID.uuidString)) {
            Image(systemName: "stop.fill")
                .padding(10)
                .background(Circle().fill(.red.opacity(0.9)))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
    }
}
