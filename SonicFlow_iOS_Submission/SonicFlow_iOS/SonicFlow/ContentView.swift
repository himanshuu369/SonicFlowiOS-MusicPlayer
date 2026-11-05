import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var model = AudioPlayerModel()
    @State private var showingImporter = false
    @State private var sliderValue: Double = 0
    @State private var isScrubbing = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.035, green: 0.045, blue: 0.09),
                                    Color(red: 0.10, green: 0.045, blue: 0.17)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    albumArtwork
                    trackInfo
                    progressSection
                    playbackControls
                    visualizerSection
                    importButton
                    if let message = model.errorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .multilineTextAlignment(.center)
                    }
                    Text("SONICFLOW  •  NATIVE AUDIO EXPERIENCE")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.32))
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .fileImporter(isPresented: $showingImporter,
                      allowedContentTypes: [.audio, .mp3, .mpeg4Audio, .wav],
                      allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first { model.importAudio(from: url) }
            case .failure(let error):
                model.errorMessage = "Import failed: \(error.localizedDescription)"
            }
        }
        .onChange(of: model.currentTime) { value in
            if !isScrubbing { sliderValue = value }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("SONICFLOW")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(3)
                Text("YOUR SOUND, IN MOTION")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
            Image(systemName: "waveform")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.cyan)
                .padding(12)
                .background(.white.opacity(0.07), in: Circle())
        }
        .foregroundStyle(.white)
    }

    private var albumArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34)
                .fill(LinearGradient(colors: [Color(red: 0.20, green: 0.14, blue: 0.42),
                                              Color(red: 0.04, green: 0.55, blue: 0.65),
                                              Color(red: 0.46, green: 0.15, blue: 0.48)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle()
                .stroke(.white.opacity(0.13), lineWidth: 1)
                .padding(26)
            Circle()
                .stroke(.white.opacity(0.18), lineWidth: 1)
                .padding(52)
            Image(systemName: "music.note")
                .font(.system(size: 76, weight: .light))
                .foregroundStyle(.white.opacity(0.92))
                .shadow(color: .black.opacity(0.25), radius: 18, y: 8)
            VStack {
                HStack {
                    Label("NOW PLAYING", systemImage: "dot.radiowaves.left.and.right")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.22), in: Capsule())
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .padding(22)
        }
        .frame(height: 280)
        .shadow(color: .purple.opacity(0.24), radius: 28, y: 14)
    }

    private var trackInfo: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text(model.trackName)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .foregroundStyle(.white)
                Text("LOCAL AUDIO • PERSONAL LIBRARY")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.42))
            }
            Spacer()
            Image(systemName: "heart")
                .font(.system(size: 20))
                .foregroundStyle(.white.opacity(0.65))
                .padding(12)
                .background(.white.opacity(0.07), in: Circle())
        }
    }

    private var progressSection: some View {
        VStack(spacing: 8) {
            Slider(value: Binding(get: {
                isScrubbing ? sliderValue : model.currentTime
            }, set: { newValue in
                isScrubbing = true
                sliderValue = newValue
            }), in: 0...max(model.duration, 1), onEditingChanged: { editing in
                if !editing {
                    model.seek(to: sliderValue)
                    isScrubbing = false
                }
            })
            .tint(.cyan)
            HStack {
                Text(timeString(isScrubbing ? sliderValue : model.currentTime))
                Spacer()
                Text("-" + timeString(max(0, model.duration - (isScrubbing ? sliderValue : model.currentTime))))
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.48))
        }
    }

    private var playbackControls: some View {
        HStack(spacing: 30) {
            Button { model.skipBackward() } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            Button { model.stop() } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Button { model.playPause() } label: {
                Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(Color(red: 0.04, green: 0.07, blue: 0.12))
                    .frame(width: 70, height: 70)
                    .background(LinearGradient(colors: [.cyan, Color(red: 0.48, green: 0.78, blue: 1)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: Circle())
                    .shadow(color: .cyan.opacity(0.32), radius: 18, y: 7)
            }
            Button { model.skipForward() } label: {
                Image(systemName: "goforward.15")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }

    private var visualizerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("LIVE AUDIO VISUALIZERS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(.white.opacity(0.72))
                Spacer()
                Circle().fill(model.isPlaying ? .green : .gray).frame(width: 6, height: 6)
                Text(model.isPlaying ? "LIVE" : "STANDBY")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.45))
            }
            visualizerCard(title: "WAVEFORM", subtitle: "Signal amplitude history") {
                WaveformView(values: model.waveform)
            }
            visualizerCard(title: "LEVEL METER", subtitle: "Live RMS energy") {
                EqualizerView(values: model.levels)
            }
            visualizerCard(title: "FREQUENCY SPECTRUM", subtitle: "Direct-DFT magnitude bins") {
                SpectrumView(values: model.spectrum)
            }
        }
    }

    private func visualizerCard<Content: View>(title: String, subtitle: String,
                                                @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.35))
            }
            content()
        }
        .padding(15)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.07), lineWidth: 1))
    }

    private var importButton: some View {
        Button { showingImporter = true } label: {
            Label("IMPORT AUDIO FILE", systemImage: "plus.circle.fill")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func timeString(_ value: Double) -> String {
        guard value.isFinite else { return "0:00" }
        let seconds = max(0, Int(value))
        return "\(seconds / 60):" + String(format: "%02d", seconds % 60)
    }
}
