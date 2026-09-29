import AppIntents
import SwiftUI
import WidgetKit

enum HomeWidgetSize {
    case small, medium, large
}

/// 홈 화면 위젯 본문. date 는 타임라인 칸의 시각으로, 다이얼이 이 시각 기준으로 그려진다.
struct HomeWidgetView: View {
    var size: HomeWidgetSize
    var date: Date
    var timer: RunningTimer?
    var presets: [Int]

    var body: some View {
        Group {
            switch (size, timer) {
            case (.small, let timer?):
                SmallRunning(timer: timer, date: date)
            case (.small, nil):
                PresetTiles(presets: presets, columns: 3, running: nil)
                    .frame(maxHeight: .infinity)
            case (.medium, let timer?):
                HStack(spacing: 16) {
                    TimeDial(minutes: timer.remainingMinutes(at: date))
                    RunningDetails(timer: timer, numberSize: 40)
                }
            case (.medium, nil):
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow(text: AppConfig.wordmark)
                    Spacer(minLength: 10)
                    PresetTiles(presets: presets, columns: presets.count, running: nil)
                    Spacer(minLength: 0)
                }
            case (.large, let timer?):
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 18) {
                        TimeDial(minutes: timer.remainingMinutes(at: date))
                            .frame(width: 150)
                        RunningDetails(timer: timer, numberSize: 48)
                    }
                    .frame(height: 150)
                    Spacer(minLength: 16)
                    PresetTiles(presets: presets, columns: 3, running: timer)
                }
            case (.large, nil):
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow(text: AppConfig.wordmark)
                    PresetTiles(presets: presets, columns: 3, running: nil)
                        .frame(maxHeight: .infinity)
                }
            }
        }
        .foregroundStyle(Theme.ink)
    }
}

/// 작은 위젯이 돌 때: 다이얼 위에 남은 시간, 모서리에 끝내기.
struct SmallRunning: View {
    var timer: RunningTimer
    var date: Date

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 6) {
                TimeDial(minutes: timer.remainingMinutes(at: date))
                LiveTime(interval: timer.interval, countsDown: true, alignment: .center)
                    .font(Theme.number(24, weight: .regular))
                    .widgetAccentable()
            }
            StopChip(alarmID: timer.alarmID, diameter: 26)
                .offset(x: 4, y: -4)
        }
    }
}

/// 다이얼 옆: 머리글과 끝내기, 남은 시간, 경과·종료.
struct RunningDetails: View {
    var timer: RunningTimer
    var numberSize: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Eyebrow(text: timer.title)
                Spacer(minLength: 8)
                StopChip(alarmID: timer.alarmID, diameter: 28)
            }
            Spacer(minLength: 4)
            LiveTime(interval: timer.interval, countsDown: true)
                .font(Theme.number(numberSize))
                .minimumScaleFactor(0.6)
                .widgetAccentable()
            TimerMetaRow(interval: timer.interval, endDate: timer.endDate, size: 11)
                .padding(.top, 6)
        }
    }
}

/// 프리셋 타일: 60분 시계 판에 그 시간만큼 부채꼴을 깔고, 가운데 숫자.
struct PresetTiles: View {
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
                            PresetTile(minutes: minutes, selected: running?.matches(minutes: minutes) == true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct PresetTile: View {
    var minutes: Int
    var selected: Bool
    private static let numberRatio: CGFloat = 0.34

    var body: some View {
        TimeDial(
            minutes: Double(minutes),
            wedge: .white.opacity(0.24),
            face: .white.opacity(0.07),
            showsTicks: false,
            showsCap: false,
            highlighted: selected
        )
        .overlay(
            GeometryReader { proxy in
                Text("\(minutes)")
                    .font(.system(size: proxy.size.width * Self.numberRatio, weight: .semibold, design: .rounded).monospacedDigit())
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(Theme.ink)
                    .shadow(color: .black.opacity(0.6), radius: 2)
                    .widgetAccentable()
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .padding(4)
        )
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}
