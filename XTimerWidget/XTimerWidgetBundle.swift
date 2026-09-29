import SwiftUI
import WidgetKit

@main
struct XTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        PresetWidget()
        LockPresetWidget()
        LockRowWidget()
        TimerStatusWidget()
        PresetControl()
        TimerLiveActivity()
    }
}
