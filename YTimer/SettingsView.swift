import AVFoundation
import SwiftUI

/// sounds.json 에 적힌 앱 내장 알림음.
struct AlarmSound: Decodable, Identifiable, Hashable {
    var id: String
    var name: String
    var file: String

    static let catalog: [AlarmSound] = {
        guard let url = Bundle.main.url(forResource: "sounds", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([AlarmSound].self, from: data)) ?? []
    }()
}

/// 설정 화면에서 고를 때 미리 들려준다. 무음 모드여도 들리게 playback 으로 튼다.
@MainActor
final class SoundPreview {
    static let shared = SoundPreview()
    private var player: AVAudioPlayer?
    private let previewLength: TimeInterval = 3

    func play(_ sound: AlarmSound?) {
        player?.stop()
        guard let sound, let url = Bundle.main.url(forResource: sound.file, withExtension: nil) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
        let current = player
        Task {
            try? await Task.sleep(for: .seconds(previewLength))
            if current === self.player { self.player?.stop() }
        }
    }

    func stop() { player?.stop() }
}

struct SettingsView: View {
    @Environment(TimerStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("알림음") {
                    soundRow(name: "시스템 기본", file: nil)
                    ForEach(AlarmSound.catalog) { sound in
                        soundRow(name: sound.name, file: sound.file, preview: sound)
                    }
                }

                Section {
                    Toggle("'다시' 버튼", isOn: Binding(
                        get: { store.settings.offersRepeat },
                        set: { value in store.updateSettings { $0.offersRepeat = value } }
                    ))
                    .tint(Theme.secondary)
                }
            }
            .tint(Theme.ink)
            .scrollContentBackground(.hidden)
            .background(Backdrop())
            .navigationTitle("알람 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료", systemImage: "checkmark") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear { SoundPreview.shared.stop() }
    }

    private func soundRow(name: String, file: String?, preview: AlarmSound? = nil) -> some View {
        Button {
            store.updateSettings { $0.soundFile = file }
            SoundPreview.shared.play(preview)
        } label: {
            HStack {
                Text(name).foregroundStyle(Theme.ink)
                Spacer()
                if store.settings.soundFile == file {
                    Image(systemName: "checkmark").font(.body.weight(.semibold))
                }
            }
        }
    }
}
