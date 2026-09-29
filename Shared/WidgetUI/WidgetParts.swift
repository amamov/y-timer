import AppIntents
import SwiftUI
import WidgetKit

// 위젯·Live Activity 가 함께 쓰는 조각. 앱의 디버그 갤러리에서도 같은 코드로 그린다.
//
// 조판 규칙
// - 한 줄의 글자는 모두 같은 기준선(firstTextBaseline)에 선다.
// - 왼쪽에 붙는 값은 왼쪽 끝선, 오른쪽에 붙는 값은 오른쪽 끝선에 맞춘다.
// - Text(timerInterval:) 은 가장 긴 값만큼 폭을 잡으므로 frame 과 multilineTextAlignment 로 방향을 정해 준다.

/// 남은 시간처럼 1초마다 바뀌는 글자. 폭을 채우고 alignment 쪽에 붙는다.
struct LiveTime: View {
    var interval: ClosedRange<Date>
    var countsDown: Bool
    var alignment: TextAlignment = .leading

    var body: some View {
        Text(timerInterval: interval, countsDown: countsDown)
            .multilineTextAlignment(alignment)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
            .lineLimit(1)
    }

    private var frameAlignment: Alignment {
        switch alignment {
        case .center: .center
        case .trailing: .trailing
        default: .leading
        }
    }
}

/// "경과 0:03 ─────── 오후 11:10 종료" 한 줄.
struct TimerMetaRow: View {
    var interval: ClosedRange<Date>
    var endDate: Date
    var size: CGFloat = 12

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("경과").fixedSize()
            LiveTime(interval: interval, countsDown: false)
            Text("\(endDate, style: .time) 종료").fixedSize()
        }
        .font(.system(size: size, weight: .medium, design: .rounded).monospacedDigit())
        .foregroundStyle(Theme.secondary)
    }
}

/// 흰 막대 진행 표시.
struct TimerBar: View {
    var interval: ClosedRange<Date>

    var body: some View {
        ProgressView(timerInterval: interval, countsDown: true) { EmptyView() } currentValueLabel: { EmptyView() }
            .progressViewStyle(.linear)
            .tint(Theme.ink)
    }
}

/// 머리글: "Y-TIMER · 5분" 처럼 작은 대문자.
struct Eyebrow: View {
    var text: String

    var body: some View {
        Text(text)
            .font(Theme.caption)
            .tracking(1.6)
            .foregroundStyle(Theme.secondary)
            .lineLimit(1)
    }
}

/// 유리 원형 끝내기 버튼.
struct StopChip: View {
    var alarmID: UUID
    var diameter: CGFloat

    var body: some View {
        Button(intent: StopTimerIntent(alarmID: alarmID.uuidString)) {
            Image(systemName: "stop.fill")
                .font(.system(size: diameter * 0.32, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(width: diameter, height: diameter)
                .background(Circle().fill(.white.opacity(0.14)))
                .overlay(Circle().strokeBorder(Theme.hairline, lineWidth: 0.7))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("끝내기")
    }
}

/// 검은 유리판. 왼쪽 위에 흰 빛이 살짝 번진다.
struct WidgetGlassBackground: View {
    var body: some View {
        ZStack {
            Color.black
            RadialGradient(colors: [.white.opacity(0.14), .clear], center: .topLeading, startRadius: 0, endRadius: 280)
        }
    }
}
