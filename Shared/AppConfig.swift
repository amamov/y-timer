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
    static let defaultLockRow = Array(defaultPresets.prefix(3))
    static let defaultSingle = defaultPresets[1]

    static func clampMinutes(_ minutes: Int) -> Int {
        min(max(minutes, presetMinutes.lowerBound), presetMinutes.upperBound)
    }
}
