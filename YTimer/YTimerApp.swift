import AppIntents
import SwiftUI

@main
struct YTimerApp: App {
    @State private var store = TimerStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .preferredColorScheme(.dark)
        }
    }
}

/// 단축어·Siri·액션 버튼에서 부른다. 분은 Siri 가 되묻는다.
struct YTimerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTimerIntent(),
            phrases: ["\(.applicationName) 타이머 시작", "\(.applicationName) 시작"],
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
