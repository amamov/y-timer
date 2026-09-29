import Foundation

/// 식별자와 표시 이름은 project.yml 이 Info.plist 에 넣어 준 값을 읽는다.
enum AppConfig {
    static let appGroup = info("AppGroupIdentifier")
    static let author = info("AppAuthor")
    static let displayName = info("CFBundleDisplayName")

    private static func info(_ key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
    }
}

/// 값의 범위와 기본값. 숫자는 여기에만 둔다.
enum TimerLimits {
    static let presetMinutes = 1...999
    static let presetSlots = 6
    static let maxHours = 23
    static let secondsPerMinute = 60

    static let defaultPresets = [5, 10, 15, 30, 60, 100]
    /// 잠금 화면 위젯은 앱 프리셋 칸 번호로 고른다.
    static let lockRowCount = 3
    static let defaultLockRowSlots = Array(0..<lockRowCount)
    static let defaultSingleSlot = 1
    static let defaultLockRow = defaultLockRowSlots.map { defaultPresets[$0] }
    static let defaultSingle = defaultPresets[defaultSingleSlot]

    /// 위젯 다이얼은 미리 계산한 칸으로 줄어든다. 칸 수와 칸 간격의 범위.
    static let dialSteps = 120
    static let dialStepRange: ClosedRange<TimeInterval> = 5...60

    static func clampMinutes(_ minutes: Int) -> Int {
        min(max(minutes, presetMinutes.lowerBound), presetMinutes.upperBound)
    }
}
