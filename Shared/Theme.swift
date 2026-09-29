import SwiftUI

/// 흑백만 쓴다. 강조는 흰색의 불투명도로만 준다.
enum Theme {
    static let ink = Color.white
    static let track = Color.white.opacity(0.12)
    static let hairline = Color.white.opacity(0.22)
    static let secondary = Color.white.opacity(0.55)

    static func number(_ size: CGFloat, weight: Font.Weight = .light) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }

    static let caption = Font.system(size: 11, weight: .semibold, design: .rounded)
}

extension Duration {
    /// 1시간 이상이면 시:분:초, 아니면 분:초.
    var clock: String {
        formatted(.time(pattern: components.seconds >= 3600 ? .hourMinuteSecond : .minuteSecond))
    }
}
