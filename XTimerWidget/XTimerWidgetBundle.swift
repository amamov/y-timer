import SwiftUI
import WidgetKit

@main
struct XTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        PresetWidget()
        TimerStatusWidget()
        PresetControl()
        TimerLiveActivity()
    }
}
