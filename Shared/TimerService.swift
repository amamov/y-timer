import ActivityKit
import AlarmKit
import SwiftUI

struct YTimerMetadata: AlarmMetadata {
    var duration: TimeInterval
}

enum TimerServiceError: Error, CustomLocalizedStringResourceConvertible {
    case notAuthorized
    case invalidDuration

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notAuthorized: "알람 권한이 없습니다. 설정 > 앱 > \(AppConfig.displayName) 에서 알람을 허용해 주세요."
        case .invalidDuration: "시간을 1초 이상으로 정해 주세요."
        }
    }
}

/// 타이머는 하나만 돈다. 새로 시작하면 이전 것은 취소한다.
enum TimerService {
    static func requestAuthorization() async -> Bool {
        let manager = AlarmManager.shared
        switch manager.authorizationState {
        case .authorized: return true
        case .denied: return false
        default: return (try? await manager.requestAuthorization()) == .authorized
        }
    }

    static func start(minutes: Int) async throws {
        try await start(duration: TimerFormat.seconds(minutes: minutes))
    }

    static func start(duration: TimeInterval) async throws {
        guard duration > 0 else { throw TimerServiceError.invalidDuration }
        guard await requestAuthorization() else { throw TimerServiceError.notAuthorized }
        cancelAll()

        let settings = AlarmSettings.current
        let title = TimerFormat.title(duration)
        let repeatButton = settings.offersRepeat
            ? AlarmButton(text: "다시", textColor: .white, systemImageName: "arrow.clockwise")
            : nil
        let attributes = AlarmAttributes(
            presentation: AlarmPresentation(
                alert: .init(
                    title: "\(title) 끝",
                    secondaryButton: repeatButton,
                    secondaryButtonBehavior: repeatButton == nil ? nil : .custom
                ),
                countdown: .init(title: "\(title)")
            ),
            metadata: YTimerMetadata(duration: duration),
            tintColor: Theme.ink
        )

        let id = UUID()
        let start = Date.now
        _ = try await AlarmManager.shared.schedule(
            id: id,
            configuration: .timer(
                duration: duration,
                attributes: attributes,
                stopIntent: StopTimerIntent(alarmID: id.uuidString),
                secondaryIntent: repeatButton == nil ? nil : RepeatTimerIntent(duration: duration),
                sound: settings.soundFile.map { .named($0) } ?? .default
            )
        )
        RunningTimer.current = RunningTimer(
            alarmID: id,
            duration: duration,
            startDate: start,
            endDate: start.addingTimeInterval(duration)
        )
    }

    static func stop() {
        cancelAll()
        RunningTimer.current = nil
    }

    private static func cancelAll() {
        let manager = AlarmManager.shared
        for alarm in (try? manager.alarms) ?? [] { try? manager.cancel(id: alarm.id) }
    }
}
