// 알림음 파일(.caf)과 목록(sounds.json)을 만든다.
// 사용법: swift scripts/make-sounds.swift YTimer/Sounds
// 알람 소리는 30초를 넘으면 안 되므로 각 소리는 LENGTH 초로 맞춘다.
import AVFoundation
import Foundation

let sampleRate = 44_100.0
let length = 12.0

struct Tone {
    var frequency: Double
    var start: Double
    var duration: Double
    var gain: Double = 0.35
    var partials: [(ratio: Double, gain: Double)] = [(1, 1)]
    var decay: Double = 6
}

struct Sound: Encodable {
    var id: String
    var name: String
    var file: String { "\(id).caf" }
    var tones: [Tone]

    enum CodingKeys: String, CodingKey { case id, name, file }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(file, forKey: .file)
    }
}

/// period 초마다 pattern 을 되풀이해 length 를 채운다.
func repeating(every period: Double, _ pattern: [Tone]) -> [Tone] {
    stride(from: 0.0, to: length, by: period).flatMap { offset in
        pattern.map { var t = $0; t.start += offset; return t }
    }
}

let bell: [(Double, Double)] = [(1, 1), (2.4, 0.5), (3.0, 0.35), (4.5, 0.2)]
let sounds = [
    Sound(id: "glass", name: "유리", tones: repeating(every: 1.2, [
        Tone(frequency: 1760, start: 0, duration: 0.6, partials: [(1, 1), (1.5, 0.4)], decay: 9),
        Tone(frequency: 2349, start: 0.18, duration: 0.6, partials: [(1, 1), (1.5, 0.3)], decay: 9),
    ])),
    Sound(id: "pulse", name: "펄스", tones: repeating(every: 1.0, [0.0, 0.16, 0.32].map {
        Tone(frequency: 880, start: $0, duration: 0.1, gain: 0.3, decay: 1)
    })),
    Sound(id: "bell", name: "종", tones: repeating(every: 2.4, [
        Tone(frequency: 523, start: 0, duration: 2.3, gain: 0.3, partials: bell, decay: 2.2),
    ])),
    Sound(id: "rise", name: "상승", tones: repeating(every: 1.6, [523.25, 659.25, 783.99].enumerated().map {
        Tone(frequency: $0.element, start: Double($0.offset) * 0.16, duration: 0.5, gain: 0.3, decay: 5)
    })),
    Sound(id: "digital", name: "디지털", tones: repeating(every: 1.0, [0.0, 0.14].map {
        Tone(frequency: 2000, start: $0, duration: 0.08, gain: 0.22, partials: [(1, 1), (3, 0.3), (5, 0.1)], decay: 1)
    })),
    Sound(id: "silent", name: "소리 없음", tones: []),
]

func render(_ tones: [Tone]) -> [Float] {
    var samples = [Float](repeating: 0, count: Int(length * sampleRate))
    for tone in tones {
        let first = Int(tone.start * sampleRate)
        let count = Int(tone.duration * sampleRate)
        let attack = Int(0.004 * sampleRate)
        for i in 0..<count where first + i < samples.count {
            let t = Double(i) / sampleRate
            let envelope = min(1, Double(i) / Double(attack)) * exp(-tone.decay * t)
                * min(1, Double(count - i) / Double(attack))
            let wave = tone.partials.reduce(0.0) { $0 + $1.gain * sin(2 * .pi * tone.frequency * $1.ratio * t) }
            samples[first + i] += Float(tone.gain * envelope * wave)
        }
    }
    return samples.map { max(-1, min(1, $0)) }
}

let folder = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
for sound in sounds {
    let samples = render(sound.tones)
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
    buffer.frameLength = buffer.frameCapacity
    samples.withUnsafeBufferPointer { buffer.floatChannelData![0].update(from: $0.baseAddress!, count: samples.count) }
    let file = try AVAudioFile(forWriting: folder.appendingPathComponent(sound.file), settings: [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVSampleRateKey: sampleRate,
        AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsFloatKey: false,
    ])
    try file.write(from: buffer)
}
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
try encoder.encode(sounds).write(to: folder.appendingPathComponent("sounds.json"))
print("\(sounds.count)개 소리를 \(folder.path) 에 만들었습니다.")
