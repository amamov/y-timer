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
                Section {
                    soundRow(name: "시스템 기본", file: nil)
                    ForEach(AlarmSound.catalog) { sound in
                        soundRow(name: sound.name, file: sound.file, preview: sound)
                    }
                } header: {
                    Text("알림음")
                } footer: {
                    Text("누르면 미리 들려줍니다.")
                }

                Section {
                    Toggle("'다시' 버튼", isOn: Binding(
                        get: { store.settings.offersRepeat },
                        set: { value in store.updateSettings { $0.offersRepeat = value } }
                    ))
                    .tint(Theme.secondary)
                } header: {
                    Text("끝났을 때")
                } footer: {
                    Text("알람 화면에서 누르면 같은 시간으로 다시 시작합니다.")
                }

                Section {
                    infoRow("무음 모드와 집중 모드에서도 울립니다", systemImage: "bell.and.waves.left.and.right")
                    infoRow("진동은 iOS 설정 > 사운드 및 햅틱을 따릅니다", systemImage: "iphone.radiowaves.left.and.right")
                } header: {
                    Text("무음 모드")
                } footer: {
                    Text("진동만 원하면 알림음을 '소리 없음'으로 고르세요. 진동 패턴은 iOS 가 정하며 앱에서 바꿀 수 없습니다.")
                }

                Section {
                    LabeledContent("버전", value: AppConfig.version)
                    LabeledContent("만든 사람", value: AppConfig.author)
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

    private func infoRow(_ text: String, systemImage: String) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: systemImage).foregroundStyle(Theme.ink)
        }
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
