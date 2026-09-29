import AppIntents
import SwiftUI

@main
struct XTimerApp: App {
    @State private var store = TimerStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .preferredColorScheme(.dark)
        }
    }
}

/// 단축어·Siri·액션 버튼에서 "X-Timer 10분" 처럼 부른다.
struct XTimerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTimerIntent(),
            phrases: [
                "\(.applicationName) \(\.$preset) 시작",
                "\(.applicationName) \(\.$preset)",
            ],
            shortTitle: "타이머 시작",
            systemImageName: "timer"
        )
        AppShortcut(
            intent: StopTimerIntent(),
            phrases: ["\(.applicationName) 끝내기"],
            shortTitle: "타이머 끝내기",
            systemImageName: "stop.fill"
        )
    }
}
