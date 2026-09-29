import SwiftUI
import WidgetKit

@main
struct YTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        PresetWidget()
        LockPresetWidget()
        LockRowWidget()
        TimerStatusWidget()
        PresetControl()
        TimerLiveActivity()
    }
}
