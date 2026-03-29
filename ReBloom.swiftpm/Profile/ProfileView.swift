import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("onboardingDone") private var onboardingDone = false
    @Query private var profiles: [UserProfile]
    @Query private var moodLogs: [MoodLog]
    @Query private var missions: [PartnerMission]
    @Query private var notes: [LoveNote]
    @Query private var exerciseLogs: [ExerciseLog]
    @Query private var memories: [Memory]

    @State private var showResetConfirm = false

    @State private var isEditing = false

    
    @State private var editName = ""
    @State private var editPartnerName = ""
    @State private var editBabyName = ""
    @State private var editBabyBirthDate = Date()

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            List {
                
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: profile?.role == "partner"
                                        ? [.partnerPrimary, .partnerSecondary]
                                        : [.motherPrimary, .motherSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text(profile?.role == "partner" ? "💙" : "🌸")
                                    .font(.title)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            if isEditing {
                                TextField("Your name", text: $editName)
                                    .font(.title3.weight(.semibold))
                                    .fontDesign(.rounded)
                            } else {
                                Text(profile?.name ?? "")
                                    .font(.title3.weight(.semibold))
                                    .fontDesign(.rounded)
                            }
                            Text(profile?.role == "partner" ? "Partner" : "Mom")
                                .font(.subheadline)
                                .fontDesign(.rounded)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                
                Section("Baby") {
                    if isEditing {
                        LabeledContent {
                            TextField("Baby's name", text: $editBabyName)
                                .fontDesign(.rounded)
                                .multilineTextAlignment(.trailing)
                        } label: {
                            Text("Name")
                                .fontDesign(.rounded)
                        }
                        LabeledContent {
                            DatePicker("", selection: $editBabyBirthDate, displayedComponents: .date)
                                .labelsHidden()
                        } label: {
                            Text("Birthday")
                                .fontDesign(.rounded)
                        }
                    } else {
                        LabeledContent {
                            Text(profile?.babyName ?? "")
                                .fontDesign(.rounded)
                        } label: {
                            Text("Name")
                                .fontDesign(.rounded)
                        }
                        LabeledContent {
                            Text(profile?.babyBirthDate ?? Date(), style: .date)
                                .fontDesign(.rounded)
                        } label: {
                            Text("Birthday")
                                .fontDesign(.rounded)
                        }
                    }
                    LabeledContent {
                        Text("Week \(profile?.weeksPostpartum ?? 1)")
                            .fontDesign(.rounded)
                            .foregroundStyle(profile?.role == "partner" ? Color.partnerPrimary : Color.motherPrimary)
                    } label: {
                        Text("Postpartum")
                            .fontDesign(.rounded)
                    }
                }

                
                Section("Partner") {
                    if isEditing {
                        LabeledContent {
                            TextField("Partner's name", text: $editPartnerName)
                                .fontDesign(.rounded)
                                .multilineTextAlignment(.trailing)
                        } label: {
                            Text("Name")
                                .fontDesign(.rounded)
                        }
                    } else {
                        LabeledContent {
                            Text(profile?.partnerName ?? "")
                                .fontDesign(.rounded)
                        } label: {
                            Text("Name")
                                .fontDesign(.rounded)
                        }
                    }
                }

                
                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Reset ReBloom")
                                .fontDesign(.rounded)
                        }
                    }
                    .confirmationDialog(
                        "Reset ReBloom?",
                        isPresented: $showResetConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Reset Everything", role: .destructive) {
                            resetApp()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will delete all your data and restart onboarding.")
                            .fontDesign(.rounded)
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            isEditing = false
                        }
                    } else {
                        Button("Edit") {
                            loadProfileForEditing()
                            isEditing = true
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button("Done") {
                            saveProfile()
                            isEditing = false
                        }
                        .fontWeight(.semibold)
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private func loadProfileForEditing() {
        guard let p = profile else { return }
        editName = p.name
        editPartnerName = p.partnerName
        editBabyName = p.babyName
        editBabyBirthDate = p.babyBirthDate
    }

    private func saveProfile() {
        guard let p = profile else { return }
        p.name = editName
        p.partnerName = editPartnerName
        p.babyName = editBabyName
        p.babyBirthDate = editBabyBirthDate
        try? modelContext.save()
    }

    private func resetApp() {
        for profile in profiles { modelContext.delete(profile) }
        for log in moodLogs { modelContext.delete(log) }
        for mission in missions { modelContext.delete(mission) }
        for note in notes { modelContext.delete(note) }
        for log in exerciseLogs { modelContext.delete(log) }
        for memory in memories { modelContext.delete(memory) }
        
        try? modelContext.save()
        onboardingDone = false
        dismiss()
    }

}
