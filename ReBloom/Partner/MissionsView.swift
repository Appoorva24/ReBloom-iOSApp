import SwiftUI
import SwiftData

struct MissionsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = MissionsViewModel()

    @State private var appeared = true

    var body: some View {
        ZStack {
            LinearGradient(colors: [.partnerBgTop, .partnerBgBottom], startPoint: .top, endPoint: .bottom).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    
                    progressCard
                        .cardAppear(index: 0, appeared: appeared)

                    
                    ForEach(Array(vm.missions.enumerated()), id: \.element.id) { index, mission in
                        missionCard(mission)
                            .cardAppear(index: index + 1, appeared: appeared)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Missions")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            vm.load(modelContext: modelContext)

            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                vm.ringProgress = vm.progressValue
            }
            
            vm.markMissionsAsSeen(modelContext: modelContext)
        }
    }

 
    private var progressCard: some View {
        PartnerNativeCard {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.partnerSecondary.opacity(0.15), lineWidth: 14)

                    Circle()
                        .trim(from: 0, to: vm.ringProgress)
                        .stroke(
                            LinearGradient(
                                colors: [.partnerPrimary, .partnerSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(vm.completedCount)")
                            .font(.title.weight(.bold))
                            .fontDesign(.rounded)
                        Text("of \(vm.totalCount)")
                            .font(.caption)
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 110, height: 110)

                Text("This week's missions 💙")
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }


    private func missionCard(_ mission: PartnerMission) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                vm.toggleExpanded(mission.id)
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: mission.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(mission.isCompleted ? Color.partnerSuccess : Color.partnerPrimary)

                    Text(mission.missionTitle)
                        .font(.headline)
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                        .strikethrough(mission.isCompleted)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(vm.expandedId == mission.id ? 180 : 0))
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if vm.expandedId == mission.id {
                VStack(alignment: .leading, spacing: 12) {
                    if mission.missionDescription.hasPrefix("[VOICE:") {
                        let base64 = String(mission.missionDescription.dropFirst(7).dropLast(1))
                        if let data = Data(base64Encoded: base64) {
                            VoicePlaybackView(data: data, tintColor: Color.partnerPrimary)
                                .padding(.vertical, 8)
                        }
                    } else if !mission.missionDescription.isEmpty {
                        Text(mission.missionDescription)
                            .font(.body)
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                    }

                    if !mission.isCompleted {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            vm.markComplete(mission, modelContext: modelContext)
                        } label: {
                            Text("Mark Complete ✓")
                                .font(.headline)
                                .fontDesign(.rounded)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.partnerPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.partnerPrimary.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
