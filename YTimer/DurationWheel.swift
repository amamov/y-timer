import SwiftUI

/// 기본 시계 앱처럼 시·분·초를 굴려서 맞춘다.
struct DurationWheel: View {
    @Binding var seconds: Int

    private let perMinute = TimerLimits.secondsPerMinute
    private var perHour: Int { perMinute * perMinute }

    var body: some View {
        HStack(spacing: 0) {
            column(value: hours, range: 0...TimerLimits.maxHours, unit: "시간")
            column(value: minutes, range: 0...(perMinute - 1), unit: "분")
            column(value: secs, range: 0...(perMinute - 1), unit: "초")
        }
        .frame(height: 170)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }

    private var hours: Binding<Int> {
        Binding(get: { seconds / perHour }, set: { seconds = $0 * perHour + seconds % perHour })
    }

    private var minutes: Binding<Int> {
        Binding(get: { seconds % perHour / perMinute },
                set: { seconds = seconds / perHour * perHour + $0 * perMinute + seconds % perMinute })
    }

    private var secs: Binding<Int> {
        Binding(get: { seconds % perMinute }, set: { seconds = seconds - seconds % perMinute + $0 })
    }

    private func column(value: Binding<Int>, range: ClosedRange<Int>, unit: String) -> some View {
        Picker(unit, selection: value) {
            ForEach(range, id: \.self) { number in
                Text("\(number)")
                    .font(Theme.number(22, weight: .regular))
                    .tag(number)
            }
        }
        .pickerStyle(.wheel)
        .overlay {
            Text(unit)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.secondary)
                .offset(x: 34)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .clipped()
    }
}
