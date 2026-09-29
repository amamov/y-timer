import SwiftUI

/// 흑백만 쓴다. 강조는 흰색의 불투명도로만 준다.
enum Theme {
    static let ink = Color.white
    static let track = Color.white.opacity(0.12)
    static let hairline = Color.white.opacity(0.22)
    static let secondary = Color.white.opacity(0.55)
    static let faint = Color.white.opacity(0.3)

    static func number(_ size: CGFloat, weight: Font.Weight = .light) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }

    static let caption = Font.system(size: 11, weight: .semibold, design: .rounded)
    static let label = Font.system(size: 15, weight: .semibold, design: .rounded)
}

/// 대문자 앱 이름. "Y-TIMER" 같은 머리글에 쓴다.
extension AppConfig {
    static var wordmark: String { displayName.uppercased() }
}
