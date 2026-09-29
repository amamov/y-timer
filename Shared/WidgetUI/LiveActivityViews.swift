import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

extension AlarmPresentationState.Mode.Countdown {
    /// 원래 시작 시각부터 끝까지. 일시정지가 있었어도 fireDate 에서 전체 길이를 빼면 된다.
    var interval: ClosedRange<Date> {
        fireDate.addingTimeInterval(-totalCountdownDuration)...fireDate
    }
}

/// 잠금 화면·상시표시·스탠바이의 Live Activity.
struct LiveActivityPanel: View {
    var duration: TimeInterval?
    var state: AlarmPresentationState

    private var eyebrow: String {
        [AppConfig.wordmark, duration.map(TimerFormat.title)].compactMap { $0 }.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Eyebrow(text: eyebrow)
                    headline
                }
                StopChip(alarmID: state.alarmID, diameter: 40)
            }
            if case .countdown(let countdown) = state.mode {
                TimerBar(interval: countdown.interval)
                    .padding(.top, 10)
                TimerMetaRow(interval: countdown.interval, endDate: countdown.fireDate)
                    .padding(.top, 8)
            }
        }
        .foregroundStyle(Theme.ink)
    }

    @ViewBuilder private var headline: some View {
        switch state.mode {
        case .countdown(let countdown):
            LiveTime(interval: countdown.interval, countsDown: true)
                .font(Theme.number(52))
        case .paused(let paused):
            Text(TimerFormat.clock(paused.totalCountdownDuration - paused.previouslyElapsedDuration))
                .font(Theme.number(52))
                .foregroundStyle(Theme.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .alert:
            Text("끝")
                .font(Theme.number(52))
                .frame(maxWidth: .infinity, alignment: .leading)
        @unknown default:
            EmptyView()
        }
    }
}

/// 다이내믹 아일랜드를 펼쳤을 때 아래 칸.
struct IslandExpandedBottom: View {
    var state: AlarmPresentationState

    var body: some View {
        if case .countdown(let countdown) = state.mode {
            VStack(alignment: .leading, spacing: 0) {
                LiveTime(interval: countdown.interval, countsDown: true)
                    .font(Theme.number(40))
                TimerBar(interval: countdown.interval)
                    .padding(.top, 6)
                TimerMetaRow(interval: countdown.interval, endDate: countdown.fireDate, size: 11)
                    .padding(.top, 6)
            }
            .foregroundStyle(Theme.ink)
        } else {
            Text("끝")
                .font(Theme.number(40))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// 다이내믹 아일랜드를 접었을 때 오른쪽 남은 시간.
struct IslandRemaining: View {
    var state: AlarmPresentationState

    var body: some View {
        if case .countdown(let countdown) = state.mode {
            LiveTime(interval: countdown.interval, countsDown: true, alignment: .trailing)
        } else {
            Text("끝")
        }
    }
}

/// 다이내믹 아일랜드의 작은 링.
struct IslandRing: View {
    var state: AlarmPresentationState

    var body: some View {
        if case .countdown(let countdown) = state.mode {
            ProgressView(timerInterval: countdown.interval, countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.circular)
            .tint(Theme.ink)
        } else {
            Image(systemName: "bell.fill").foregroundStyle(Theme.ink)
        }
    }
}
