import AlarmKit
import SwiftUI
import WidgetKit

struct XTimerMetadata: AlarmMetadata {
    var minutes: Int
}

enum TimerServiceError: Error, CustomLocalizedStringResourceConvertible {
    case notAuthorized

    var localizedStringResource: LocalizedStringResource {
        "X-Timer 앱을 한 번 열어 알람 권한을 허용해 주세요."
    }
}

/// 타이머는 하나만 돈다. 새로 시작하면 이전 것은 취소한다.
enum TimerService {
    static let tint = Color.orange

    static func requestAuthorization() async -> Bool {
        let manager = AlarmManager.shared
        switch manager.authorizationState {
        case .authorized: return true
        case .denied: return false
        default: return (try? await manager.requestAuthorization()) == .authorized
        }
    }

    static func start(_ preset: TimerPreset) async throws {
        guard await requestAuthorization() else { throw TimerServiceError.notAuthorized }
        let manager = AlarmManager.shared
        for alarm in (try? manager.alarms) ?? [] { try? manager.cancel(id: alarm.id) }

        let presentation = AlarmPresentation(
            alert: .init(title: "\(preset.minutes)분 끝"),
            countdown: .init(title: "\(preset.minutes)분")
        )
        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: XTimerMetadata(minutes: preset.minutes),
            tintColor: tint
        )
        let id = UUID()
        let start = Date.now
        _ = try await manager.schedule(
            id: id,
            configuration: .timer(
                duration: preset.duration,
                attributes: attributes,
                stopIntent: StopTimerIntent(alarmID: id.uuidString)
            )
        )
        SharedStore.current = RunningTimer(
            alarmID: id,
            minutes: preset.minutes,
            startDate: start,
            endDate: start.addingTimeInterval(preset.duration)
        )
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func stop() {
        let manager = AlarmManager.shared
        for alarm in (try? manager.alarms) ?? [] { try? manager.cancel(id: alarm.id) }
        clear()
    }

    static func clear() {
        SharedStore.current = nil
        WidgetCenter.shared.reloadAllTimelines()
    }
}
