import SwiftUI

/// 검은 바탕 위 흐린 흰 빛. 유리가 비칠 거리를 만든다.
struct Backdrop: View {
    var body: some View {
        ZStack {
            Color.black
            Circle()
                .fill(.white.opacity(0.16))
                .frame(width: 420)
                .blur(radius: 140)
                .offset(x: -110, y: -260)
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 360)
                .blur(radius: 130)
                .offset(x: 150, y: 300)
        }
        .ignoresSafeArea()
    }
}

struct Dial: View {
    var timer: RunningTimer?
    var onStop: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            TimelineView(.periodic(from: .now, by: 0.25)) { context in
                DialFace(timer: timer, now: context.date)
            }
            .aspectRatio(1, contentMode: .fit)

            if timer != nil {
                Button(action: onStop) {
                    Label("끝내기", systemImage: "stop.fill")
                        .font(Theme.label)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 11)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .capsule)
                .offset(y: 10)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .frame(maxWidth: 320, maxHeight: .infinity)
        .animation(.smooth, value: timer == nil)
    }
}

struct DialFace: View {
    var timer: RunningTimer?
    var now: Date

    var body: some View {
        let total = timer?.duration ?? 1
        let remaining = timer.map { max(0, $0.endDate.timeIntervalSince(now)) } ?? 0
        let elapsed = timer.map { min(total, now.timeIntervalSince($0.startDate)) } ?? 0

        ZStack {
            Circle().fill(.clear).glassEffect(.regular, in: .circle)
            Circle()
                .inset(by: 20)
                .stroke(Theme.track, lineWidth: 6)
            Circle()
                .inset(by: 20)
                .trim(from: 0, to: remaining / total)
                .stroke(Theme.ink, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: .white.opacity(0.5), radius: 8)
                .animation(.linear(duration: 0.25), value: remaining)
            Ticks().padding(38)

            VStack(spacing: 8) {
                if let timer {
                    Text(timer.title)
                        .font(Theme.caption)
                        .tracking(2)
                        .foregroundStyle(Theme.secondary)
                    Text(TimerFormat.clock(remaining.rounded(.up)))
                        .font(Theme.number(58))
                        .contentTransition(.numericText(countsDown: true))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    VStack(spacing: 2) {
                        Text("경과 \(TimerFormat.clock(elapsed.rounded(.down)))")
                        Text("\(timer.endDate, style: .time) 종료")
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.secondary)
                } else {
                    Text(TimerFormat.clock(0))
                        .font(Theme.number(58))
                        .foregroundStyle(Theme.faint)
                }
            }
            .padding(54)
        }
    }
}

/// 다이얼 안쪽의 60칸 눈금.
struct Ticks: View {
    private let count = 60
    private let majorEvery = 5

    var body: some View {
        GeometryReader { proxy in
            let radius = min(proxy.size.width, proxy.size.height) / 2
            ForEach(0..<count, id: \.self) { i in
                let major = i % majorEvery == 0
                Capsule()
                    .fill(.white.opacity(major ? 0.35 : 0.12))
                    .frame(width: major ? 2 : 1, height: major ? 8 : 4)
                    .offset(y: -radius + 4)
                    .rotationEffect(.degrees(Double(i) * 360 / Double(count)))
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
    }
}
