import SwiftUI
import AVFoundation

struct VoicePlaybackView: View {
    var data: Data
    var tintColor: Color

    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var duration: TimeInterval = 0
    @State private var playbackTimer: Timer?

    var body: some View {
        HStack(spacing: 12) {
            Button {
                if isPlaying {
                    stopPlayback()
                } else {
                    startPlayback()
                }
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(tintColor)
            }
            .buttonStyle(.plain)

            ProgressView(value: progress)
                .tint(tintColor)

            Text(formattedDuration(duration))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fontDesign(.rounded)
        }
        .onAppear {
            player = try? AVAudioPlayer(data: data)
            player?.prepareToPlay()
            duration = player?.duration ?? 0
        }
        .onDisappear {
            player?.stop()
            playbackTimer?.invalidate()
        }
    }

    private func startPlayback() {
        player?.currentTime = 0
        player?.play()
        isPlaying = true
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let player else { return }
            if player.isPlaying {
                progress = player.currentTime / player.duration
            } else {
                isPlaying = false
                progress = 0
                playbackTimer?.invalidate()
                playbackTimer = nil
            }
        }
    }

    private func stopPlayback() {
        player?.stop()
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    private func formattedDuration(_ t: TimeInterval) -> String {
        let minutes = Int(t) / 60
        let seconds = Int(t) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
