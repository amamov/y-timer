import Foundation

/// 앱과 위젯이 App Group 으로 나눠 보는 현재 타이머.
struct RunningTimer: Codable, Equatable {
    var alarmID: UUID
    var minutes: Int
    var startDate: Date
    var endDate: Date

    var interval: ClosedRange<Date> { startDate...endDate }
    func isFinished(at date: Date = .now) -> Bool { date >= endDate }
}

enum SharedStore {
    static let appGroup = "group.com.amamov.xtimer"
    private static let key = "runningTimer"
    private static var defaults: UserDefaults { UserDefaults(suiteName: appGroup) ?? .standard }

    static var current: RunningTimer? {
        get {
            guard let data = defaults.data(forKey: key) else { return nil }
            return try? JSONDecoder().decode(RunningTimer.self, from: data)
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
    }
}
