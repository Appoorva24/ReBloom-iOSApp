import SwiftUI
import SwiftData
import AVFoundation

struct MotherMissionsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = MotherMissionsViewModel()

    @State private var missionRecorder = VoiceRecorderManager()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.motherBgTop, .motherBgBottom],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            FloatingOrb(color: .motherSecondary, size: 180).position(x: 60,  y: 140)
            FloatingOrb(color: .motherLavender,  size: 150).position(x: 320, y: 380)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {

                    // Quick Missions
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Quick Missions")
                            .font(.title3.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundStyle(Color.motherTextHeading)

                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                            spacing: 12
                        ) {
                            ForEach(vm.missionChips, id: \.label) { chip in
                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    vm.sendMission(title: chip.label, modelContext: modelContext)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                        withAnimation { vm.showToast = false }
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(chip.emoji)
                                            .font(.title3)
                                            .frame(width: 42, height: 42)
                                            .background(Color.motherRose.opacity(0.10))
                                            .clipShape(Circle())
                                        Text(chip.label)
                                            .font(.subheadline.weight(.semibold))
                                            .fontDesign(.rounded)
                                            .foregroundStyle(Color.motherTextHeading)
                                            .multilineTextAlignment(.leading)
                                            .lineLimit(2)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .shadow(color: Color.motherPrimary.opacity(0.08), radius: 6, x: 0, y: 3)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(Color.motherRose.opacity(0.15), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Custom Mission
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Custom Mission")
                            .font(.title3.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundStyle(Color.motherTextHeading)

                        VStack(spacing: 12) {
                            TextField("e.g. Run me a bath tonight…", text: $vm.customMission, axis: .vertical)
                                .lineLimit(3...5)
                                .font(.body)
                                .fontDesign(.rounded)
                                .padding(14)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(
                                            vm.customMission.isEmpty
                                                ? Color.motherRose.opacity(0.15)
                                                : Color.motherRose.opacity(0.45),
                                            lineWidth: 1.5
                                        )
                                )
                                .shadow(color: Color.motherPrimary.opacity(0.06), radius: 4, x: 0, y: 2)

                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                vm.sendMission(title: vm.customMission, modelContext: modelContext)
                                vm.customMission = ""
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                    withAnimation { vm.showToast = false }
                                }
                            } label: {
                                Text("Send Mission")
                                    .font(.subheadline.weight(.bold))
                                    .fontDesign(.rounded)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        vm.customMission.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                            ? AnyShapeStyle(Color.motherRose.opacity(0.35))
                                            : AnyShapeStyle(LinearGradient(
                                                colors: [.motherRose, .motherDeepRose],
                                                startPoint: .leading, endPoint: .trailing
                                            ))
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .disabled(vm.customMission.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                            HStack(spacing: 10) {
                                Rectangle().fill(Color.secondary.opacity(0.15)).frame(height: 1)
                                Text("or send a voice note")
                                    .font(.caption)
                                    .fontDesign(.rounded)
                                    .foregroundStyle(.secondary)
                                    .fixedSize()
                                Rectangle().fill(Color.secondary.opacity(0.15)).frame(height: 1)
                            }

                            VoiceMessageView(recorder: missionRecorder, tintColor: Color.motherRose, onSaveVoice: nil, onSendVoice: { data in
                                vm.sendVoiceMission(data: data, modelContext: modelContext)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                    withAnimation { vm.showToast = false }
                                }
                            })
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .navigationTitle("For \(vm.partnerName)")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { vm.load(modelContext: modelContext) }
        .overlay(alignment: .bottom) {
            if vm.showToast {
                ToastView(message: vm.toastMessage)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.4), value: vm.showToast)
    }
}
