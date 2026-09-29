import AlarmKit
import Observation
import SwiftUI

@MainActor
@Observable
final class TimerStore {
    private(set) var current: RunningTimer? = RunningTimer.current
    private(set) var presets: [Int] = PresetStore.minutes
    private(set) var settings: AlarmSettings = AlarmSettings.current
    private(set) var selection: WidgetSelection = WidgetSelection.current
    var errorMessage: String?

    private var isDemo: Bool {
        #if DEBUG
        // 시뮬레이터에서 도는 화면을 확인할 때만 쓴다: -demoRunning
        ProcessInfo.processInfo.arguments.contains("-demoRunning")
        #else
        false
        #endif
    }

    init() {
        IntentLiterals.verify()
        if isDemo {
            let duration = TimerFormat.seconds(minutes: TimerLimits.defaultPresets[2])
            let start = Date.now.addingTimeInterval(-duration * 0.28)
            current = RunningTimer(alarmID: UUID(), duration: duration, startDate: start, endDate: start.addingTimeInterval(duration))
            return
        }
        Task { await observeAlarms() }
    }

    func start(minutes: Int) {
        start(duration: TimerFormat.seconds(minutes: minutes))
    }

    func start(duration: TimeInterval) {
        Log.timer.info("app start tapped duration=\(duration, privacy: .public)")
        Task {
            do {
                try await TimerService.start(duration: duration)
                current = RunningTimer.current
            } catch let error as TimerServiceError {
                errorMessage = String(localized: error.localizedStringResource)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func stop() {
        TimerService.stop()
        current = nil
    }

    func setPreset(_ minutes: Int, at index: Int) {
        guard presets.indices.contains(index) else { return }
        presets[index] = TimerLimits.clampMinutes(minutes)
        PresetStore.minutes = presets
    }

    func resetPresets() {
        PresetStore.reset()
        presets = PresetStore.minutes
    }

    func updateSelection(_ change: (inout WidgetSelection) -> Void) {
        change(&selection)
        WidgetSelection.current = selection
    }

    func updateSettings(_ change: (inout AlarmSettings) -> Void) {
        change(&settings)
        AlarmSettings.current = settings
    }

    func requestAuthorization() async {
        guard !isDemo else { return }
        _ = await TimerService.requestAuthorization()
    }

    /// 잠금 화면이나 알림에서 끝내거나 '다시'를 누른 경우도 앱 상태에 맞춘다.
    private func observeAlarms() async {
        for await alarms in AlarmManager.shared.alarmUpdates {
            let saved = RunningTimer.current
            if let saved, !alarms.contains(where: { $0.id == saved.alarmID }) {
                RunningTimer.current = nil
                current = nil
            } else {
                current = saved
            }
        }
    }
}
