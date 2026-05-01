import Foundation
import AVFoundation

@Observable
class VoiceRecorderManager: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    var isRecording = false
    var isPlaying = false
    var recordingDuration: TimeInterval = 0
    var playbackProgress: Double = 0
    var permissionGranted = false
    var showPermissionAlert = false
    var hasRecording = false

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var durationTimer: Timer?
    private var playbackTimer: Timer?
    private(set) var recordingURL: URL?
    private(set) var recordingData: Data?

   

    func requestPermission(completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                if granted {
                    do {
                        let session = AVAudioSession.sharedInstance()
                        try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
                        try session.setActive(true)
                        self.permissionGranted = true
                        completion(true)
                    } catch {
                        completion(false)
                    }
                } else {
                    self.showPermissionAlert = true
                    completion(false)
                }
            }
        }
    }

   

    func startRecording() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("bloom_\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.delegate = self
            recorder.record()
            audioRecorder = recorder
            recordingURL = url
            isRecording = true
            recordingDuration = 0

            durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.recordingDuration += 1
            }
        } catch {
            
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        durationTimer?.invalidate()
        durationTimer = nil

        if let url = recordingURL {
            recordingData = try? Data(contentsOf: url)
        }
        hasRecording = true
    }


    func startPlayback() {
        guard let data = recordingData else { return }
        do {
            let player = try AVAudioPlayer(data: data)
            player.delegate = self
            player.play()
            audioPlayer = player
            isPlaying = true

            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self, let player = self.audioPlayer else { return }
                self.playbackProgress = player.currentTime / player.duration
            }
        } catch {
        
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }



    func deleteRecording() {
        stopPlayback()
        audioRecorder = nil
        audioPlayer = nil
        recordingData = nil
        recordingURL = nil
        recordingDuration = 0
        playbackProgress = 0
        hasRecording = false
        isRecording = false
        isPlaying = false
    }



    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        playbackProgress = 0
        playbackTimer?.invalidate()
        playbackTimer = nil
    }


    func formattedDuration(_ t: TimeInterval) -> String {
        let minutes = Int(t) / 60
        let seconds = Int(t) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
