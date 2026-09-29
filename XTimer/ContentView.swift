import SwiftUI

struct ContentView: View {
    @Environment(TimerStore.self) private var store
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        @Bindable var store = store
        // 가로(스탠바이 등)에서는 타이머와 프리셋을 나란히 둔다.
        let layout = verticalSizeClass == .compact ? AnyLayout(HStackLayout(spacing: 32)) : AnyLayout(VStackLayout(spacing: 32))
        layout {
            if let timer = store.current {
                RunningView(timer: timer, onStop: store.stop)
            } else {
                Text("X-Timer")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .frame(maxHeight: .infinity)
            }
            PresetGrid(selected: store.current?.minutes, onSelect: store.start)
        }
        .padding(24)
        .task { await store.requestAuthorization() }
        .alert("알림", isPresented: .constant(store.errorMessage != nil)) {
            Button("확인") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}

struct PresetGrid: View {
    var selected: Int?
    var onSelect: (TimerPreset) -> Void

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
            ForEach(TimerPreset.allCases, id: \.self) { preset in
                Button { onSelect(preset) } label: {
                    Circle()
                        .fill(selected == preset.minutes ? TimerService.tint : Color.white.opacity(0.1))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            VStack(spacing: 0) {
                                Text(preset.label)
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                Text("분").font(.caption.weight(.semibold))
                            }
                            .padding(8)
                            .foregroundStyle(selected == preset.minutes ? .black : .primary)
                        }
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.impact, trigger: selected)
            }
        }
    }
}

struct RunningView: View {
    var timer: RunningTimer
    var onStop: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let now = context.date
            let total = timer.endDate.timeIntervalSince(timer.startDate)
            let remaining = max(0, timer.endDate.timeIntervalSince(now))
            let elapsed = min(total, now.timeIntervalSince(timer.startDate))

            VStack(spacing: 24) {
                ZStack {
                    Circle().stroke(Color.white.opacity(0.1), lineWidth: 18)
                    Circle()
                        .trim(from: 0, to: remaining / total)
                        .stroke(TimerService.tint, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: remaining)
                    VStack(spacing: 6) {
                        Text("남은 시간").font(.subheadline).foregroundStyle(.secondary)
                        Text(Duration.seconds(remaining.rounded(.up)), format: .time(pattern: remaining >= 3600 ? .hourMinuteSecond : .minuteSecond))
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText(countsDown: true))
                        Text("경과 \(Duration.seconds(elapsed.rounded(.down)), format: .time(pattern: .minuteSecond))")
                            .font(.title3.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxHeight: .infinity)

                HStack {
                    Label(timer.endDate.formatted(date: .omitted, time: .shortened) + " 종료", systemImage: "flag.checkered")
                    Spacer()
                    Button(role: .destructive, action: onStop) {
                        Label("끝내기", systemImage: "stop.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .font(.headline)
            }
        }
    }
}
