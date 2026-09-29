import AlarmKit
import Observation
import SwiftUI

@MainActor
@Observable
final class TimerStore {
    private(set) var current: RunningTimer? = SharedStore.current
    var errorMessage: String?

    init() {
        Task { await observeAlarms() }
    }

    func start(_ preset: TimerPreset) {
        Task {
            do {
                try await TimerService.start(preset)
                current = SharedStore.current
            } catch {
                errorMessage = String(localized: (error as? TimerServiceError)?.localizedStringResource
                    ?? "타이머를 시작하지 못했습니다.")
            }
        }
    }

    func stop() {
        TimerService.stop()
        current = nil
    }

    func requestAuthorization() async {
        _ = await TimerService.requestAuthorization()
    }

    /// 잠금 화면이나 알림에서 끝낸 경우도 앱 상태에 맞춘다.
    private func observeAlarms() async {
        for await alarms in AlarmManager.shared.alarmUpdates {
            if let current, !alarms.contains(where: { $0.id == current.alarmID }) {
                TimerService.clear()
                self.current = nil
            } else {
                current = SharedStore.current
            }
        }
    }
}
