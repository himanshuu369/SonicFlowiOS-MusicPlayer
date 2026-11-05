# SonicFlow — Native iOS Music Player

A SwiftUI music player for iOS 16+ using AVFoundation. It supports importing local audio files, playback controls, seeking, and three live visualizations driven by audio output: waveform history, level bars, and a frequency-bin spectrum.

## Important build note
This repository contains the native Swift source code. It must be opened and built with Xcode on macOS. It has not been compiled or device-tested in this environment.

## Create the Xcode project
1. On a Mac, open Xcode and choose **File → New → Project → iOS → App**.
2. Product Name: `SonicFlow`; Interface: `SwiftUI`; Language: `Swift`.
3. Set the deployment target to **iOS 16.0**.
4. Replace the generated Swift files with the files in the `SonicFlow/` folder in this repository. Add `AudioPlayerModel.swift` and `VisualizerViews.swift` to the app target if Xcode does not add them automatically.
5. In the app target's **Signing & Capabilities**, select a development team if running on a physical iPhone.
6. Build and run on an iOS 16+ simulator or device.

## Use
1. Tap **Import audio**.
2. Select an audio file from Files (for example, an MP3, M4A, or WAV file).
3. Use play/pause, previous/next controls (next/previous are placeholders for a future playlist; currently they stop playback because no playlist is bundled), or drag the progress slider to seek.
4. The waveform, level bars, and spectrum respond to the live audio output.

## Implementation
- **SwiftUI** for the interface and animations.
- **AVAudioEngine / AVAudioPlayerNode / AVAudioFile** for playback.
- An output tap samples the audio signal and calculates waveform samples, RMS level groups, and a lightweight DFT spectrum.
- Audio analysis runs in the audio tap callback; published UI values are delivered to the main queue.
- Audio session interruptions are observed and playback is paused.

## Limitations / next steps
- No commercial music is bundled. The user imports audio they have rights to use.
- The previous/next buttons are visual controls only until a playlist is added.
- The lightweight DFT is intended for UI visualization, not professional audio analysis.
- Verify audio formats, interruption behavior, and performance on a real device before production release.
