import SwiftUI

/// 프리셋 원 여섯 개. 칸 번호로 고르고 알린다.
struct PresetGrid: View {
    var presets: [Int]
    var selected: Set<Int>
    var onSelect: (Int) -> Void
    var columns = 3

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns), spacing: 12) {
                ForEach(presets.indices, id: \.self) { slot in
                    let isSelected = selected.contains(slot)
                    Button { onSelect(slot) } label: {
                        PresetChipLabel(minutes: presets[slot], isSelected: isSelected)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(isSelected ? .regular.tint(.white).interactive() : .regular.interactive(), in: .circle)
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

/// 프리셋 편집에서 무엇을 고치는지.
enum PresetEditTarget: String, CaseIterable, Identifiable {
    case values, lockRow, lockSingle
    var id: Self { self }

    var title: String {
        switch self {
        case .values: "시간"
        case .lockRow: "세 칸"
        case .lockSingle: "한 칸"
        }
    }
}

/// 프리셋 값과, 잠금 화면 위젯이 쓸 칸을 고른다.
struct PresetEditor: View {
    @Environment(TimerStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var target = PresetEditTarget.values
    @State private var slot = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Picker("대상", selection: $target) {
                    ForEach(PresetEditTarget.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                PresetGrid(presets: store.presets, selected: selected, onSelect: select)
                    .frame(maxWidth: 320)

                if target == .values {
                    Picker("분", selection: Binding(
                        get: { store.presets[slot] },
                        set: { store.setPreset($0, at: slot) }
                    )) {
                        ForEach(TimerLimits.presetMinutes, id: \.self) { Text("\($0)분").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 180)
                }
                Spacer(minLength: 0)
            }
            .padding(24)
            .animation(.smooth, value: target)
            .navigationTitle("프리셋")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if target == .values {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("기본값") { store.resetPresets() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료", systemImage: "checkmark") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
    }

    private var selected: Set<Int> {
        switch target {
        case .values: [slot]
        case .lockRow: Set(store.selection.row)
        case .lockSingle: [store.selection.single]
        }
    }

    private func select(_ tapped: Int) {
        switch target {
        case .values: slot = tapped
        case .lockRow: store.updateSelection { $0.toggleRow(tapped) }
        case .lockSingle: store.updateSelection { $0.single = tapped }
        }
    }
}
