import AppIntents
import SwiftUI
import WidgetKit

enum HomeWidgetSize {
    case small, medium, large
}

/// 홈 화면 위젯 본문.
struct HomeWidgetView: View {
    var size: HomeWidgetSize
    var timer: RunningTimer?
    var presets: [Int]

    var body: some View {
        Group {
            switch size {
            case .small:
                if let timer {
                    RunningPanel(timer: timer, numberSize: 40, stopSize: 28)
                } else {
                    PresetChips(presets: presets, columns: 3, running: nil)
                        .frame(maxHeight: .infinity)
                }
            case .medium:
                if let timer {
                    HStack(spacing: 18) {
                        RunningPanel(timer: timer, numberSize: 40, stopSize: 28)
                        PresetChips(presets: presets, columns: 3, running: timer)
                            .frame(width: 138)
                            .frame(maxHeight: .infinity)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        Eyebrow(text: AppConfig.wordmark)
                        Spacer(minLength: 12)
                        PresetChips(presets: presets, columns: presets.count, running: nil)
                    }
                }
            case .large:
                VStack(alignment: .leading, spacing: 0) {
                    if let timer {
                        RunningPanel(timer: timer, numberSize: 64, stopSize: 34)
                    } else {
                        Eyebrow(text: AppConfig.wordmark)
                        Spacer(minLength: 0)
                    }
                    Spacer(minLength: 18)
                    PresetChips(presets: presets, columns: 3, running: timer)
                }
            }
        }
        .foregroundStyle(Theme.ink)
    }
}

/// 도는 동안: 머리글과 끝내기, 남은 시간, 막대, 경과·종료.
struct RunningPanel: View {
    var timer: RunningTimer
    var numberSize: CGFloat
    var stopSize: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Eyebrow(text: timer.title)
                Spacer(minLength: 8)
                StopChip(alarmID: timer.alarmID, diameter: stopSize)
            }
            Spacer(minLength: 4)
            LiveTime(interval: timer.interval, countsDown: true)
                .font(Theme.number(numberSize))
                .minimumScaleFactor(0.6)
                .widgetAccentable()
            TimerBar(interval: timer.interval)
                .padding(.top, 6)
            TimerMetaRow(interval: timer.interval, endDate: timer.endDate, size: 11)
                .padding(.top, 8)
        }
    }
}

/// 프리셋 원들. 원은 칸 폭에 맞춰 정원을 유지하고, 누르는 영역은 칸 전체다.
struct PresetChips: View {
    var presets: [Int]
    var columns: Int
    var running: RunningTimer?
    var spacing: CGFloat = 8

    var body: some View {
        let rows = stride(from: 0, to: presets.count, by: max(columns, 1)).map {
            Array(presets[$0..<min($0 + columns, presets.count)])
        }
        Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
            ForEach(rows.indices, id: \.self) { row in
                GridRow {
                    ForEach(rows[row].indices, id: \.self) { column in
                        let minutes = rows[row][column]
                        Button(intent: StartTimerIntent(minutes: minutes)) {
                            GlassChip(minutes: minutes, selected: running?.matches(minutes: minutes) == true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct GlassChip: View {
    var minutes: Int
    var selected: Bool
    private static let numberRatio: CGFloat = 0.38

    var body: some View {
        Circle()
            .fill(selected ? AnyShapeStyle(Theme.ink) : AnyShapeStyle(.white.opacity(0.1)))
            .overlay(
                Circle().strokeBorder(
                    LinearGradient(colors: [.white.opacity(selected ? 0 : 0.4), .white.opacity(0.04)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.8
                )
            )
            .overlay(
                // 숫자는 원 지름에 비례한다. 작은 위젯과 큰 위젯에서 같은 비율로 보인다.
                GeometryReader { proxy in
                    Text("\(minutes)")
                        .font(.system(size: proxy.size.width * Self.numberRatio,
                                      weight: selected ? .semibold : .medium, design: .rounded).monospacedDigit())
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(selected ? .black : Theme.ink)
                        .widgetAccentable()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
                .padding(4)
            )
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
    }
}
