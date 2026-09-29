import AppIntents
import SwiftUI
import WidgetKit

// 잠금 화면에서는 버튼 label 을 눌러야만 인텐트가 돌고, 그 밖을 누르면 앱이 열린다.
// 그래서 배경은 버튼 바깥에 두고 label 이 칸 전체를 채우게 한다.
// 참고: https://github.com/home-assistant/iOS/pull/5647

/// 잠금 화면 원형: 한 칸.
struct LockSingleView: View {
    var minutes: Int
    var timer: RunningTimer?

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let timer {
                LockRing(timer: timer)
            } else {
                Button(intent: StartTimerIntent(minutes: minutes)) {
                    VStack(spacing: -2) {
                        Text("\(minutes)")
                            .font(.system(size: 24, weight: .semibold, design: .rounded).monospacedDigit())
                            .minimumScaleFactor(0.6)
                        Text("분")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .opacity(0.7)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// 잠금 화면 직사각형: 세 칸.
struct LockRowView: View {
    var minutes: [Int]
    var timer: RunningTimer?

    var body: some View {
        if let timer {
            HStack(spacing: 10) {
                LockRing(timer: timer)
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 1) {
                    LiveTime(interval: timer.interval, countsDown: true)
                        .font(.system(size: 26, weight: .semibold, design: .rounded).monospacedDigit())
                        .minimumScaleFactor(0.6)
                    Text("\(timer.endDate, style: .time) 종료")
                        .font(.system(size: 11, weight: .medium, design: .rounded).monospacedDigit())
                        .opacity(0.7)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else {
            HStack(spacing: 6) {
                ForEach(minutes.indices, id: \.self) { index in
                    ZStack {
                        AccessoryWidgetBackground().clipShape(Circle())
                        Button(intent: StartTimerIntent(minutes: minutes[index])) {
                            Text("\(minutes[index])")
                                .font(.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit())
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .padding(4)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// 남은 비율 링. 가운데는 남은 시간.
struct LockRing: View {
    var timer: RunningTimer

    var body: some View {
        ProgressView(timerInterval: timer.interval, countsDown: true) {
            EmptyView()
        } currentValueLabel: {
            Text(timerInterval: timer.interval, countsDown: true)
                .font(.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
        }
        .progressViewStyle(.circular)
    }
}
