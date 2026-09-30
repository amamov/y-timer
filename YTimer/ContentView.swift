import SwiftUI

enum TimerMode: String, CaseIterable, Identifiable {
    case presets, custom
    var id: Self { self }

    var title: String {
        switch self {
        case .presets: "프리셋"
        case .custom: "직접"
        }
    }
}

struct ContentView: View {
    @Environment(TimerStore.self) private var store
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("timerMode") private var mode = TimerMode.presets
    @State private var showsSettings = false
    @State private var showsPresetEditor = false

    var body: some View {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-demoGallery"), args.indices.contains(i + 1), let page = Int(args[i + 1]) {
            WidgetGallery(page: page)
        } else {
            main
        }
        #else
        main
        #endif
    }

    @ViewBuilder private var main: some View {
        @Bindable var store = store
        // 가로(스탠바이 등)에서는 다이얼과 조작부를 나란히 둔다.
        let layout = verticalSizeClass == .compact
            ? AnyLayout(HStackLayout(spacing: 36))
            : AnyLayout(VStackLayout(spacing: 22))

        ZStack {
            Backdrop()
            VStack(spacing: 18) {
                Header(onSettings: { showsSettings = true })
                layout {
                    Dial(timer: store.current, onStop: store.stop)
                    Controls(mode: $mode, onEditPresets: { showsPresetEditor = true })
                }
                Signature()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
        }
        .foregroundStyle(Theme.ink)
        .task { await store.requestAuthorization() }
        // 타이머가 도는 동안 앱이 떠 있으면 화면이 꺼지지 않는다. 멈추거나 앱을 벗어나면 원래대로.
        .onChange(of: keepsAwake, initial: true) { _, awake in
            UIApplication.shared.isIdleTimerDisabled = awake
        }
        #if DEBUG
        // 시뮬레이터에서 시트 화면을 확인할 때만 쓴다: -demoSheet settings|presets
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            guard let i = args.firstIndex(of: "-demoSheet"), args.indices.contains(i + 1) else { return }
            showsSettings = args[i + 1] == "settings"
            showsPresetEditor = args[i + 1] == "presets"
        }
        #endif
        .sheet(isPresented: $showsSettings) { SettingsView() }
        .sheet(isPresented: $showsPresetEditor) { PresetEditor() }
        .alert("알림", isPresented: .constant(store.errorMessage != nil)) {
            Button("확인") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}

extension ContentView {
    private var keepsAwake: Bool {
        store.settings.keepsScreenOn && store.current != nil && scenePhase == .active
    }
}

struct Header: View {
    var onSettings: () -> Void

    var body: some View {
        HStack {
            Text(AppConfig.wordmark)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .tracking(5)
                .foregroundStyle(Theme.secondary)
            Spacer()
            Button(action: onSettings) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
            .accessibilityLabel("알람 설정")
        }
    }
}

struct Controls: View {
    @Environment(TimerStore.self) private var store
    @Binding var mode: TimerMode
    var onEditPresets: () -> Void
    @AppStorage("customSeconds") private var customSeconds = TimerLimits.defaultPresets[0] * TimerLimits.secondsPerMinute

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Picker("방식", selection: $mode) {
                    ForEach(TimerMode.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                if mode == .presets {
                    Button(action: onEditPresets) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 36, height: 32)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .accessibilityLabel("프리셋 편집")
                }
            }

            switch mode {
            case .presets:
                PresetGrid(
                    presets: store.presets,
                    selected: Set(store.presets.indices.filter { store.current?.matches(minutes: store.presets[$0]) == true }),
                    onSelect: { store.start(minutes: store.presets[$0]) }
                )
            case .custom:
                VStack(spacing: 14) {
                    DurationWheel(seconds: $customSeconds)
                        .frame(height: 180)
                        .glassEffect(.regular, in: .rect(cornerRadius: 28))
                    Button { store.start(duration: TimeInterval(customSeconds)) } label: {
                        Label("시작", systemImage: "play.fill")
                            .font(Theme.label)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.tint(.white).interactive(), in: .capsule)
                    .disabled(customSeconds == 0)
                    .opacity(customSeconds == 0 ? 0.4 : 1)
                }
            }
        }
        .frame(maxWidth: 330)
        .animation(.smooth, value: mode)
    }
}

struct Signature: View {
    var body: some View {
        Text("designed by \(AppConfig.author)")
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .tracking(1.5)
            .foregroundStyle(Theme.faint)
    }
}
