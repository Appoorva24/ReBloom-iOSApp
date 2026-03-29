import SwiftUI

struct VoiceMessageView: View {
    @Bindable var recorder: VoiceRecorderManager
    @Environment(\.openURL) private var openURL
    var tintColor: Color
    var onSaveVoice: ((Data) -> Void)? = nil
    var onSendVoice: ((Data) -> Void)? = nil

    @State private var waveformAnimating  = false
    @State private var pulsingGlow        = false
    @State private var showDeleteConfirm  = false

    var body: some View {
        Group {
            if !recorder.isRecording && !recorder.hasRecording {
                stateA_idle
            } else if recorder.isRecording {
                stateB_recording
            } else {
                stateC_hasRecording
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .alert("Microphone Access Needed", isPresented: $recorder.showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

   
    private var stateA_idle: some View {
        Button {
            recorder.requestPermission { granted in
                if granted { recorder.startRecording() }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .foregroundStyle(tintColor)
                Text("Tap to Record Voice")
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .foregroundStyle(tintColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(tintColor, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

   
    private var stateB_recording: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(tintColor)
                        .frame(width: 4, height: waveformAnimating ? 32 : 8)
                        .animation(
                            .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                            value: waveformAnimating
                        )
                }
            }

            Text("Recording \(recorder.formattedDuration(recorder.recordingDuration))")
                .font(.headline)
                .fontDesign(.rounded)
                .foregroundStyle(tintColor)

            Text("Tap to stop")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fontDesign(.rounded)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { recorder.stopRecording() }
        .shadow(color: .red.opacity(pulsingGlow ? 0.3 : 0.1), radius: 12)
        .onAppear {
            waveformAnimating = true
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulsingGlow = true
            }
        }
        .onDisappear {
            waveformAnimating = false
            pulsingGlow = false
        }
    }

    
    private var stateC_hasRecording: some View {
        VStack(spacing: 14) {
           
            HStack(spacing: 12) {
                Button {
                    if recorder.isPlaying { recorder.stopPlayback() }
                    else { recorder.startPlayback() }
                } label: {
                    Image(systemName: recorder.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(tintColor)
                }
                .buttonStyle(.plain)

                ProgressView(value: recorder.playbackProgress)
                    .tint(tintColor)

                Text(recorder.formattedDuration(recorder.recordingDuration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontDesign(.rounded)
            }

            Divider()
                .padding(.vertical, 2)

            
            VStack(spacing: 10) {
               
                HStack(spacing: 10) {
                    if let onSaveVoice = onSaveVoice {
                        Button {
                            if let data = recorder.recordingData {
                                onSaveVoice(data)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                recorder.deleteRecording()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Save")
                                    .font(.subheadline.weight(.semibold))
                                    .fontDesign(.rounded)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(tintColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    if let onSendVoice = onSendVoice {
                        Button {
                            if let data = recorder.recordingData {
                                onSendVoice(data)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                recorder.deleteRecording()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Send")
                                    .font(.subheadline.weight(.semibold))
                                    .fontDesign(.rounded)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(tintColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                
                HStack(spacing: 10) {
                    Button {
                        recorder.deleteRecording()
                        recorder.requestPermission { granted in
                            if granted { recorder.startRecording() }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Re-record")
                                .font(.caption.weight(.semibold))
                                .fontDesign(.rounded)
                        }
                        .foregroundStyle(tintColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(tintColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(tintColor.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Button { showDeleteConfirm = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Delete")
                                .font(.caption.weight(.semibold))
                                .fontDesign(.rounded)
                        }
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("Delete Recording?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                        Button("Delete", role: .destructive) { recorder.deleteRecording() }
                    }
                }
            }
        }
    }
}
