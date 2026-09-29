#if DEBUG
import AlarmKit
import SwiftUI
import WidgetKit

/// 시뮬레이터에서 위젯 모양을 실제 크기로 확인한다: -demoGallery 1|2|3
/// 크기는 402pt 폭 아이폰의 위젯 크기를 따른다.
struct WidgetGallery: View {
    var page: Int

    private let small = CGSize(width: 170, height: 170)
    private let medium = CGSize(width: 364, height: 170)
    private let large = CGSize(width: 364, height: 382)
    private let rectangular = CGSize(width: 172, height: 76)
    private let circular = CGSize(width: 76, height: 76)
    private let contentMargin: CGFloat = 16

    private var timer: RunningTimer {
        let duration = TimerFormat.seconds(minutes: TimerLimits.defaultPresets[0])
        let start = Date.now.addingTimeInterval(-3)
        return RunningTimer(alarmID: UUID(), duration: duration, startDate: start, endDate: start.addingTimeInterval(duration))
    }

    private var state: AlarmPresentationState {
        let t = timer
        return AlarmPresentationState(alarmID: t.alarmID, mode: .countdown(.init(
            totalCountdownDuration: t.duration, previouslyElapsedDuration: 0, startDate: t.startDate, fireDate: t.endDate
        )))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch page {
                case 1:
                    lockScreen {
                        LiveActivityPanel(duration: timer.duration, state: state)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .frame(width: 370)
                            .background(.black.opacity(0.55), in: .rect(cornerRadius: 24))
                    }
                    lockScreen {
                        HStack(spacing: 16) {
                            accessory(rectangular) { LockRowView(minutes: TimerLimits.defaultLockRow, timer: nil) }
                            accessory(circular) { LockSingleView(minutes: TimerLimits.defaultSingle, timer: nil) }
                        }
                        HStack(spacing: 16) {
                            accessory(rectangular) { LockRowView(minutes: TimerLimits.defaultLockRow, timer: timer) }
                            accessory(circular) { LockSingleView(minutes: TimerLimits.defaultSingle, timer: timer) }
                        }
                    }
                    ZStack {
                        Capsule().fill(.black).frame(width: 370, height: 150)
                        IslandExpandedBottom(state: state).padding(.horizontal, 30).frame(width: 370)
                    }
                case 2:
                    HStack(spacing: 20) {
                        home(small) { HomeWidgetView(size: .small, timer: nil, presets: TimerLimits.defaultPresets) }
                        home(small) { HomeWidgetView(size: .small, timer: timer, presets: TimerLimits.defaultPresets) }
                    }
                    .scaleEffect(0.9)
                    home(medium) { HomeWidgetView(size: .medium, timer: nil, presets: TimerLimits.defaultPresets) }
                    home(medium) { HomeWidgetView(size: .medium, timer: timer, presets: TimerLimits.defaultPresets) }
                default:
                    home(large) { HomeWidgetView(size: .large, timer: timer, presets: TimerLimits.defaultPresets) }
                    home(large) { HomeWidgetView(size: .large, timer: nil, presets: TimerLimits.defaultPresets) }
                        .scaleEffect(0.8)
                }
            }
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity)
        }
        .background(Color(white: 0.35))
        .foregroundStyle(Theme.ink)
    }

    private func home(_ size: CGSize, @ViewBuilder content: () -> some View) -> some View {
        content()
            .padding(contentMargin)
            .frame(width: size.width, height: size.height)
            .background(WidgetGlassBackground())
            .clipShape(.rect(cornerRadius: 24))
    }

    private func accessory(_ size: CGSize, @ViewBuilder content: () -> some View) -> some View {
        content()
            .frame(width: size.width, height: size.height)
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.08)))
    }

    private func lockScreen(@ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 16) { content() }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(LinearGradient(colors: [Color(white: 0.45), Color(white: 0.2)], startPoint: .top, endPoint: .bottom))
    }
}
#endif
