import SwiftUI
import SwiftData

@Observable
final class ProfileViewModel {
    // MARK: - Data
    var profiles: [UserProfile] = []
    var moodLogs: [MoodLog] = []
    var missions: [PartnerMission] = []
    var notes: [LoveNote] = []
    var exerciseLogs: [ExerciseLog] = []
    var memories: [Memory] = []

    // MARK: - State
    var showResetConfirm = false
    var isEditing = false
    var editName = ""
    var editPartnerName = ""
    var editBabyName = ""
    var editBabyBirthDate = Date()

    // MARK: - Computed
    var profile: UserProfile? { profiles.first }

    // MARK: - Load Data
    func load(modelContext: ModelContext) {
        profiles = (try? modelContext.fetch(FetchDescriptor<UserProfile>())) ?? []
        moodLogs = (try? modelContext.fetch(FetchDescriptor<MoodLog>())) ?? []
        missions = (try? modelContext.fetch(FetchDescriptor<PartnerMission>())) ?? []
        notes = (try? modelContext.fetch(FetchDescriptor<LoveNote>())) ?? []
        exerciseLogs = (try? modelContext.fetch(FetchDescriptor<ExerciseLog>())) ?? []
        memories = (try? modelContext.fetch(FetchDescriptor<Memory>())) ?? []
    }

    // MARK: - Actions
    func loadProfileForEditing() {
        guard let p = profile else { return }
        editName = p.name
        editPartnerName = p.partnerName
        editBabyName = p.babyName
        editBabyBirthDate = p.babyBirthDate
    }

    func saveProfile(modelContext: ModelContext) {
        guard let p = profile else { return }
        p.name = editName
        p.partnerName = editPartnerName
        p.babyName = editBabyName
        p.babyBirthDate = editBabyBirthDate
        try? modelContext.save()
    }

    func resetApp(modelContext: ModelContext, authManager: AuthManager? = nil, completion: () -> Void) {
        for profile in profiles { modelContext.delete(profile) }
        for log in moodLogs { modelContext.delete(log) }
        for mission in missions { modelContext.delete(mission) }
        for note in notes { modelContext.delete(note) }
        for log in exerciseLogs { modelContext.delete(log) }
        for memory in memories { modelContext.delete(memory) }

        try? modelContext.save()
        authManager?.signOut()
        completion()
    }
}
