import SwiftUI

/// 12시에서 시계 방향으로 fraction 만큼 채운 부채꼴.
struct Sector: Shape {
    var fraction: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let clamped = min(max(fraction, 0), 1)
        var path = Path()
        guard clamped > 0 else { return path }
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: .degrees(-90),
                    endAngle: .degrees(-90 + 360 * clamped), clockwise: false)
        path.closeSubpath()
        return path
    }
}

/// 시계 판 한 바퀴가 60분인 다이얼. 60분을 넘는 몫은 바깥 링으로 보인다.
struct TimeDial: View {
    var minutes: Double
    var wedge: Color = Theme.ink
    var face: Color = .white.opacity(0.07)
    var showsTicks = true
    /// 가운데 숫자를 얹을 때는 중심점을 뺀다.
    var showsCap = true
    /// 강조할 때 바깥에 흰 링을 두른다.
    var highlighted = false

    static let lapMinutes = 60.0
    private let majorTicks = 12

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let ring = max(size * 0.045, 1.5)
            let inset = ring * 2.2
            ZStack {
                Circle().fill(face)
                Circle().strokeBorder(highlighted ? Theme.ink : Theme.hairline, lineWidth: highlighted ? ring : 0.6)
                if showsTicks {
                    ForEach(0..<majorTicks, id: \.self) { i in
                        Capsule()
                            .fill(.white.opacity(i % 3 == 0 ? 0.45 : 0.2))
                            .frame(width: max(size * 0.012, 0.8), height: size * (i % 3 == 0 ? 0.07 : 0.045))
                            .offset(y: -size / 2 + inset + size * 0.04)
                            .rotationEffect(.degrees(Double(i) * 360 / Double(majorTicks)))
                    }
                }
                Sector(fraction: min(minutes, Self.lapMinutes) / Self.lapMinutes)
                    .fill(wedge)
                    .padding(inset)
                if minutes > Self.lapMinutes {
                    Circle()
                        .trim(from: 0, to: min((minutes - Self.lapMinutes) / Self.lapMinutes, 1))
                        .stroke(wedge, style: StrokeStyle(lineWidth: ring, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(ring / 2)
                }
                if showsCap {
                    Circle()
                        .fill(.black)
                        .overlay(Circle().strokeBorder(Theme.hairline, lineWidth: 0.6))
                        .frame(width: size * 0.09, height: size * 0.09)
                }
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

extension RunningTimer {
    /// date 시점에 남은 분.
    func remainingMinutes(at date: Date) -> Double {
        max(0, endDate.timeIntervalSince(date)) / TimeInterval(TimerLimits.secondsPerMinute)
    }
}
