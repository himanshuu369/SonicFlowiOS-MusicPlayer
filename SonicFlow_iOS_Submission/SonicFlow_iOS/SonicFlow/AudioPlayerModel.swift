import AVFoundation
import Combine
import Foundation
import SwiftUI

@MainActor
final class AudioPlayerModel: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var trackName = "Choose a track"
    @Published var waveform: [CGFloat] = Array(repeating: 0.04, count: 48)
    @Published var levels: [CGFloat] = Array(repeating: 0.04, count: 18)
    @Published var spectrum: [CGFloat] = Array(repeating: 0.03, count: 28)
    @Published var errorMessage: String?

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var audioFile: AVAudioFile?
    private var timer: Timer?
    private var seekFrame: AVAudioFramePosition = 0
    private var wasPlayingBeforeSeek = false
    private var tapInstalled = false
    private var isConfigured = false
    private var securityScopedURL: URL?

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        installAudioTap()
        configureAudioSession()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    deinit {
        timer?.invalidate()
        if let securityScopedURL { securityScopedURL.stopAccessingSecurityScopedResource() }
        NotificationCenter.default.removeObserver(self)
    }

    func importAudio(from url: URL) {
        do {
            stop()
            if let securityScopedURL { securityScopedURL.stopAccessingSecurityScopedResource() }
            let didAccess = url.startAccessingSecurityScopedResource()
            securityScopedURL = didAccess ? url : nil
            let file = try AVAudioFile(forReading: url)
            guard file.length > 0, file.processingFormat.sampleRate > 0 else {
                throw NSError(domain: "SonicFlow", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "This audio file is empty or unsupported."])
            }
            audioFile = file
            duration = Double(file.length) / file.processingFormat.sampleRate
            currentTime = 0
            seekFrame = 0
            trackName = url.deletingPathExtension().lastPathComponent
            try startEngineIfNeeded()
            schedule(from: 0, autoplay: false)
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't load this audio file: \(error.localizedDescription)"
        }
    }

    func playPause() {
        guard audioFile != nil else {
            errorMessage = "Import an audio file first."
            return
        }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            do {
                try startEngineIfNeeded()
                if player.isPlaying == false {
                    if currentTime >= duration - 0.05 {
                        seekFrame = 0
                        currentTime = 0
                        schedule(from: 0, autoplay: true)
                    } else {
                        player.play()
                    }
                }
                isPlaying = true
                startTimer()
            } catch {
                errorMessage = "Playback couldn't start: \(error.localizedDescription)"
            }
        }
    }

    func stop() {
        player.stop()
        timer?.invalidate()
        timer = nil
        isPlaying = false
        currentTime = 0
        seekFrame = 0
    }

    func seek(to seconds: Double) {
        guard let file = audioFile else { return }
        let wasPlaying = isPlaying
        let safeSeconds = min(max(seconds, 0), duration)
        let frame = AVAudioFramePosition(safeSeconds * file.processingFormat.sampleRate)
        seekFrame = min(frame, max(0, file.length - 1))
        currentTime = safeSeconds
        schedule(from: seekFrame, autoplay: wasPlaying)
    }

    func skipForward() { seek(to: min(currentTime + 15, duration)) }
    func skipBackward() { seek(to: max(currentTime - 15, 0)) }

    private func configureAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            errorMessage = "Audio session setup failed: \(error.localizedDescription)"
        }
        #endif
    }

    private func startEngineIfNeeded() throws {
        if engine.isRunning { return }
        if !isConfigured {
            engine.prepare()
            isConfigured = true
        }
        try engine.start()
    }

    private func schedule(from frame: AVAudioFramePosition, autoplay: Bool) {
        guard let file = audioFile else { return }
        player.stop()
        let remaining = max(0, file.length - frame)
        guard remaining > 0 else {
            isPlaying = false
            currentTime = duration
            return
        }
        player.scheduleSegment(file, startingFrame: frame,
                               frameCount: AVAudioFrameCount(remaining),
                               at: nil) { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isPlaying = false
                self.currentTime = self.duration
                self.timer?.invalidate()
            }
        }
        if autoplay {
            player.play()
            isPlaying = true
            startTimer()
        } else {
            isPlaying = false
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            guard let self, self.isPlaying, let nodeTime = self.player.lastRenderTime,
                  let playerTime = self.player.playerTime(forNodeTime: nodeTime),
                  let file = self.audioFile else { return }
            let seconds = Double(playerTime.sampleTime) / playerTime.sampleRate
            let base = Double(self.seekFrame) / file.processingFormat.sampleRate
            self.currentTime = min(max(base + seconds, 0), self.duration)
        }
    }

    private func installAudioTap() {
        guard !tapInstalled else { return }
        tapInstalled = true
        let mixer = engine.mainMixerNode
        let format = mixer.outputFormat(forBus: 0)
        mixer.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let channelData = buffer.floatChannelData else { return }
            let frames = Int(buffer.frameLength)
            guard frames > 0 else { return }
            let channels = Int(buffer.format.channelCount)
            var mono = [Float](repeating: 0, count: frames)
            for frame in 0..<frames {
                var sum: Float = 0
                for channel in 0..<channels { sum += channelData[channel][frame] }
                mono[frame] = sum / Float(max(channels, 1))
            }

            let waveform = Self.makeWaveform(mono, count: 48)
            let levels = Self.makeLevels(mono, count: 18)
            let spectrum = Self.makeSpectrum(mono, count: 28)

            DispatchQueue.main.async {
                guard let self else { return }
                self.waveform = waveform
                self.levels = levels
                self.spectrum = spectrum
            }
        }
    }

    private static func makeWaveform(_ samples: [Float], count: Int) -> [CGFloat] {
        guard !samples.isEmpty else { return Array(repeating: 0.03, count: count) }
        return (0..<count).map { index in
            let start = index * samples.count / count
            let end = max(start + 1, (index + 1) * samples.count / count)
            let slice = samples[start..<min(end, samples.count)]
            let peak = slice.map { abs($0) }.max() ?? 0
            return CGFloat(min(max(peak, 0.035), 1))
        }
    }

    private static func makeLevels(_ samples: [Float], count: Int) -> [CGFloat] {
        guard !samples.isEmpty else { return Array(repeating: 0.03, count: count) }
        return (0..<count).map { index in
            let start = index * samples.count / count
            let end = max(start + 1, (index + 1) * samples.count / count)
            let slice = samples[start..<min(end, samples.count)]
            let rms = sqrt(slice.reduce(Float(0)) { $0 + $1 * $1 } / Float(max(slice.count, 1)))
            return CGFloat(min(max(rms * 3.8, 0.035), 1))
        }
    }

    // A compact direct-DFT magnitude estimate over the latest audio buffer.
    private static func makeSpectrum(_ samples: [Float], count: Int) -> [CGFloat] {
        let n = min(samples.count, 256)
        guard n > 8 else { return Array(repeating: 0.03, count: count) }
        let offset = samples.count - n
        return (1...count).map { band in
            let bin = band + 1
            var real: Double = 0
            var imaginary: Double = 0
            for i in 0..<n {
                let window = 0.5 - 0.5 * cos(2.0 * .pi * Double(i) / Double(n - 1))
                let sample = Double(samples[offset + i]) * window
                let angle = 2.0 * .pi * Double(bin * i) / Double(n)
                real += sample * cos(angle)
                imaginary -= sample * sin(angle)
            }
            let magnitude = sqrt(real * real + imaginary * imaginary) / Double(n)
            return CGFloat(min(max(magnitude * 10.0, 0.025), 1))
        }
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        if type == .began {
            player.pause()
            isPlaying = false
        }
    }
}
