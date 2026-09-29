import Foundation
import WidgetKit

/// 앱과 위젯이 App Group 으로 함께 읽고 쓰는 값.
enum SharedDefaults {
    enum Key: String {
        case runningTimer, presets, alarmSettings
    }

    private static var store: UserDefaults { UserDefaults(suiteName: AppConfig.appGroup) ?? .standard }

    static func value<T: Decodable>(_ key: Key, as type: T.Type = T.self) -> T? {
        guard let data = store.data(forKey: key.rawValue) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    /// 쓰고 나면 위젯이 새 값을 그리도록 다시 불러온다.
    static func set<T: Encodable>(_ value: T?, for key: Key) {
        if let value, let data = try? JSONEncoder().encode(value) {
            store.set(data, forKey: key.rawValue)
        } else {
            store.removeObject(forKey: key.rawValue)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
