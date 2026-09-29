import SwiftUI

struct ContentView: View {
    @Environment(TimerStore.self) private var store
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        @Bindable var store = store
        // 가로(스탠바이 등)에서는 다이얼과 프리셋을 나란히 둔다.
        let layout = verticalSizeClass == .compact
            ? AnyLayout(HStackLayout(spacing: 40))
            : AnyLayout(VStackLayout(spacing: 40))

        ZStack {
            Backdrop()
            layout {
                Dial(timer: store.current, onStop: store.stop)
                PresetGrid(selected: store.current?.minutes, onSelect: store.start)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
        }
        .foregroundStyle(Theme.ink)
        .task { await store.requestAuthorization() }
        .alert("알림", isPresented: .constant(store.errorMessage != nil)) {
            Button("확인") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}

/// 검은 바탕 위 흐린 흰 빛. 유리가 비칠 거리를 만든다.
struct Backdrop: View {
    var body: some View {
        ZStack {
            Color.black
            Circle()
                .fill(.white.opacity(0.16))
                .frame(width: 420)
                .blur(radius: 140)
                .offset(x: -110, y: -260)
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 360)
                .blur(radius: 130)
                .offset(x: 150, y: 300)
        }
        .ignoresSafeArea()
    }
}

struct Dial: View {
    var timer: RunningTimer?
    var onStop: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            TimelineView(.periodic(from: .now, by: 0.25)) { context in
                DialFace(timer: timer, now: context.date)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 340, maxHeight: .infinity)

            Button(action: onStop) {
                Label("끝내기", systemImage: "stop.fill")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .capsule)
            .opacity(timer == nil ? 0 : 1)
            .disabled(timer == nil)
            .animation(.smooth, value: timer == nil)
        }
    }
}

struct DialFace: View {
    var timer: RunningTimer?
    var now: Date

    var body: some View {
        let total = timer.map { $0.endDate.timeIntervalSince($0.startDate) } ?? 1
        let remaining = timer.map { max(0, $0.endDate.timeIntervalSince(now)) } ?? 0
        let elapsed = timer.map { min(total, now.timeIntervalSince($0.startDate)) } ?? 0

        ZStack {
            Circle().fill(.clear).glassEffect(.regular, in: .circle)
            Circle()
                .inset(by: 22)
                .stroke(Theme.track, lineWidth: 6)
            Circle()
                .inset(by: 22)
                .trim(from: 0, to: remaining / total)
                .stroke(Theme.ink, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: .white.opacity(0.5), radius: 8)
                .animation(.linear(duration: 0.25), value: remaining)
            Ticks().padding(40)

            VStack(spacing: 10) {
                if let timer {
                    Text("\(timer.minutes)분")
                        .font(Theme.caption)
                        .tracking(2)
                        .foregroundStyle(Theme.secondary)
                    Text(Duration.seconds(remaining.rounded(.up)).clock)
                        .font(Theme.number(64))
                        .contentTransition(.numericText(countsDown: true))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text("경과 \(Duration.seconds(elapsed.rounded(.down)).clock)")
                        Text("·")
                        Text("\(timer.endDate, style: .time) 종료")
                    }
                    .font(.system(size: 13, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.secondary)
                } else {
                    Text("X-TIMER")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .tracking(5)
                        .foregroundStyle(Theme.secondary)
                    Text("시간을 고르세요")
                        .font(.system(size: 22, weight: .light, design: .rounded))
                }
            }
            .padding(56)
        }
    }
}

/// 다이얼 안쪽의 60칸 눈금.
struct Ticks: View {
    var body: some View {
        GeometryReader { proxy in
            let r = min(proxy.size.width, proxy.size.height) / 2
            ForEach(0..<60, id: \.self) { i in
                Capsule()
                    .fill(.white.opacity(i % 5 == 0 ? 0.35 : 0.12))
                    .frame(width: i % 5 == 0 ? 2 : 1, height: i % 5 == 0 ? 8 : 4)
                    .offset(y: -r + 4)
                    .rotationEffect(.degrees(Double(i) * 6))
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
    }
}

struct PresetGrid: View {
    var selected: Int?
    var onSelect: (TimerPreset) -> Void

    var body: some View {
        GlassEffectContainer(spacing: 14) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
                ForEach(TimerPreset.allCases, id: \.self) { preset in
                    let isSelected = selected == preset.minutes
                    Button { onSelect(preset) } label: {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                VStack(spacing: 0) {
                                    Text(preset.label)
                                        .font(Theme.number(30, weight: .regular))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                    Text("분")
                                        .font(Theme.caption)
                                        .opacity(0.6)
                                }
                                .foregroundStyle(isSelected ? .black : .white)
                            }
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .glassEffect(isSelected ? .regular.tint(.white).interactive() : .regular.interactive(), in: .circle)
                }
            }
        }
        .frame(maxWidth: 360)
        .sensoryFeedback(.impact(weight: .medium), trigger: selected)
    }
}
