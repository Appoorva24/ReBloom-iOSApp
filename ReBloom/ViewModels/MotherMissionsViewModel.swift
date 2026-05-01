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
    func sendMission(title: String, modelContext: ModelContext, syncManager: SyncManager? = nil) {
        let mission = PartnerMission(
            missionTitle: title,
            missionDescription: "",
            isCompleted: false,
            weekNumber: currentWeek
        )
        modelContext.insert(mission)
        try? modelContext.save()
        showToastMessage("Sent to \(partnerName)! 💙")
        
        if let sync = syncManager {
            Task { try? await sync.syncMissions(modelContext: modelContext) }
        }
    }

    func sendVoiceMission(data: Data, modelContext: ModelContext, syncManager: SyncManager? = nil) {
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
        
        if let sync = syncManager {
            Task { try? await sync.syncMissions(modelContext: modelContext) }
        }
    }

    func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true
    }
}
