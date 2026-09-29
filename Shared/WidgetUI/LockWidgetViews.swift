import AppIntents
import SwiftUI
import WidgetKit

// 잠금 화면에서는 버튼 label 을 눌러야만 인텐트가 돌고, 그 밖을 누르면 앱이 열린다.
// 그래서 배경은 버튼 바깥에 두고 label 이 칸 전체를 채우게 한다. label 안에는 GeometryReader 를 두지 않는다.
// 참고: https://github.com/home-assistant/iOS/pull/5647

/// 잠금 화면 원형: 한 칸. 대기 중에는 그 시간의 부채꼴, 도는 동안은 줄어드는 부채꼴.
struct LockSingleView: View {
    var minutes: Int
    var date: Date
    var timer: RunningTimer?

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let timer {
                TimeDial(minutes: timer.remainingMinutes(at: date), face: .clear, showsTicks: false)
                    .padding(6)
            } else {
                TimeDial(minutes: Double(minutes), wedge: .white.opacity(0.35), face: .clear, showsTicks: false, showsCap: false)
                    .padding(6)
                Button(intent: StartTimerIntent(minutes: minutes)) {
                    Text("\(minutes)")
                        .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                        .minimumScaleFactor(0.6)
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
    var date: Date
    var timer: RunningTimer?

    var body: some View {
        if let timer {
            HStack(spacing: 10) {
                TimeDial(minutes: timer.remainingMinutes(at: date), face: .white.opacity(0.15), showsTicks: false)
                    .frame(width: 50, height: 50)
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
                        TimeDial(minutes: Double(minutes[index]), wedge: .white.opacity(0.35), face: .clear, showsTicks: false, showsCap: false)
                            .padding(4)
                        Button(intent: StartTimerIntent(minutes: minutes[index])) {
                            Text("\(minutes[index])")
                                .font(.system(size: 19, weight: .bold, design: .rounded).monospacedDigit())
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
