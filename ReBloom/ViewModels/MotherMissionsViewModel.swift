import SwiftUI
import SwiftData

@Observable
final class MotherMissionsViewModel {
    // MARK: - Data
    var profiles: [UserProfile] = []

    // MARK: - State
    var customMission = ""
    var showToast = false
    var toastMessage = ""
    var isLoading = false
    var errorMessage: String?

    // MARK: - Computed
    var profile: UserProfile? { profiles.first }
    var partnerName: String { profile?.partnerName ?? "Partner" }
    var currentWeek: Int { Calendar.current.component(.weekOfYear, from: Date()) }

    let missionChips: [(emoji: String, label: String)] = [
        ("🍼", "Take the baby"),
        ("🍽️", "Cook dinner"),
        ("🤗", "I need a hug"),
        ("💆", "Give me 20 mins"),
        ("🛒", "Go grocery run"),
        ("💤", "Let me sleep in")
    ]

    // MARK: - Load Data
    func load(modelContext: ModelContext) {
        let profileDescriptor = FetchDescriptor<UserProfile>()
        profiles = (try? modelContext.fetch(profileDescriptor)) ?? []
    }

    // MARK: - Actions
    func sendMission(title: String, modelContext: ModelContext, syncManager: SyncManager) {
        let mission = PartnerMission(
            missionTitle: title,
            missionDescription: "",
            isCompleted: false,
            weekNumber: currentWeek
        )
        modelContext.insert(mission)
        try? modelContext.save()
        showToastMessage("Sent to \(partnerName)! 💙")
        
        // Always sync to Supabase
        Task {
            do {
                try await syncManager.syncMissions(modelContext: modelContext)
            } catch {
                print("[MotherMissions] Mission sync failed: \(error)")
            }
        }
    }

    func sendVoiceMission(data: Data, modelContext: ModelContext, syncManager: SyncManager) {
        let encoded = "[VOICE:\(data.base64EncodedString())]"
        let mission = PartnerMission(
            missionTitle: "🎙️ Voice Mission",
            missionDescription: encoded,
            isCompleted: false,
            weekNumber: currentWeek,
            isNewForPartner: true
        )
        modelContext.insert(mission)
        try? modelContext.save()
        showToastMessage("Voice mission sent! 💙")
        
        // Always sync to Supabase
        Task {
            do {
                try await syncManager.syncMissions(modelContext: modelContext)
            } catch {
                print("[MotherMissions] Voice mission sync failed: \(error)")
            }
        }
    }

    func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true
    }
}
