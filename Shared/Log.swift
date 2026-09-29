import OSLog

/// 콘솔·기기 로그에서 subsystem 을 번들 ID 로 걸러 본다.
enum Log {
    static let timer = Logger(subsystem: Bundle.main.bundleIdentifier ?? AppConfig.displayName, category: "timer")
}
