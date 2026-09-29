import SwiftUI

struct PresetGrid: View {
    var presets: [Int]
    var selected: Int?
    var onSelect: (Int) -> Void
    var columns = 3

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns), spacing: 12) {
                ForEach(Array(presets.enumerated()), id: \.offset) { index, minutes in
                    Button { onSelect(minutes) } label: {
                        PresetChipLabel(minutes: minutes, isSelected: selected == index)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(selected == index ? .regular.tint(.white).interactive() : .regular.interactive(), in: .circle)
                }
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: selected)
    }
}

struct PresetChipLabel: View {
    var minutes: Int
    var isSelected: Bool

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                VStack(spacing: 0) {
                    Text("\(minutes)")
                        .font(Theme.number(28, weight: .regular))
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
}

/// 프리셋 편집: 칸을 고르고 아래 휠로 분을 정한다.
struct PresetEditor: View {
    @Environment(TimerStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var slot = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                PresetGrid(presets: store.presets, selected: slot, onSelect: { minutes in
                    slot = store.presets.firstIndex(of: minutes) ?? slot
                })
                .frame(maxWidth: 320)

                Picker("분", selection: Binding(
                    get: { store.presets[slot] },
                    set: { store.setPreset($0, at: slot) }
                )) {
                    ForEach(TimerLimits.presetMinutes, id: \.self) { Text("\($0)분").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(height: 180)

                Text("홈 화면 위젯에도 같은 프리셋이 나옵니다. 잠금 화면 위젯은 위젯을 길게 눌러 따로 정합니다.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(24)
            .navigationTitle("프리셋 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("기본값") { store.resetPresets() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료", systemImage: "checkmark") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
    }
}
