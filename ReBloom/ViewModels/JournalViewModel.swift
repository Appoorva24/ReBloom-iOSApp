import SwiftUI
import SwiftData

@Observable
final class JournalViewModel {
    // MARK: - Data
    var profiles: [UserProfile] = []
    var journalEntries: [MoodLog] = []

    // MARK: - State
    var entryText = ""
    var showToast = false
    var toastMessage = ""
    var entryToDelete: MoodLog?
    var showDeleteConfirmation = false

    // MARK: - Computed
    var profile: UserProfile? { profiles.first }
    var partnerName: String { profile?.partnerName ?? "Partner" }

    // MARK: - Load Data
    func load(modelContext: ModelContext) {
        let profileDescriptor = FetchDescriptor<UserProfile>()
        profiles = (try? modelContext.fetch(profileDescriptor)) ?? []

        let predicate = #Predicate<MoodLog> { $0.mood == "journal" }
        var descriptor = FetchDescriptor<MoodLog>(predicate: predicate, sortBy: [SortDescriptor(\.date, order: .reverse)])
        journalEntries = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Actions
    func saveToJournal(modelContext: ModelContext) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let log = MoodLog(
            id: UUID(),
            date: Date(),
            mood: "journal",
            energyLevel: 0,
            journalNote: entryText
        )

        modelContext.insert(log)
        try? modelContext.save()

        toastMessage = "Saved to your journal 🌸"
        showToast = true

        entryText = ""
        load(modelContext: modelContext)
    }

    func shareWithPartner(modelContext: ModelContext, syncManager: SyncManager? = nil) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let note = LoveNote(
            id: UUID(),
            date: Date(),
            senderRole: "wife",
            noteText: entryText,
            isRead: false
        )

        modelContext.insert(note)
        try? modelContext.save()

        toastMessage = "Shared with \(partnerName)"
        showToast = true

        entryText = ""
        
        // TODO: Queue Supabase sync
        if let sync = syncManager {
            Task { try? await sync.syncLoveNotes(modelContext: modelContext) }
        }
    }

    func sendVoiceMessage(_ data: Data, modelContext: ModelContext, syncManager: SyncManager? = nil) {
        let encoded = "[VOICE:\(data.base64EncodedString())]"
        let note = LoveNote(
            id: UUID(),
            date: Date(),
            senderRole: "wife",
            noteText: encoded,
            isRead: false
        )

        modelContext.insert(note)
        try? modelContext.save()

        toastMessage = "Voice note sent to \(partnerName)!"
        showToast = true
        
        if let sync = syncManager {
            Task { try? await sync.syncLoveNotes(modelContext: modelContext) }
        }
    }

    func saveVoiceToJournal(_ data: Data, modelContext: ModelContext) {
        let encoded = "[VOICE:\(data.base64EncodedString())]"
        let log = MoodLog(
            id: UUID(),
            date: Date(),
            mood: "journal",
            energyLevel: 0,
            journalNote: encoded
        )

        modelContext.insert(log)
        try? modelContext.save()

        toastMessage = "Voice note saved to journal 🌸"
        showToast = true
        load(modelContext: modelContext)
    }

    func deleteEntry(_ entry: MoodLog, modelContext: ModelContext) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        modelContext.delete(entry)
        try? modelContext.save()

        toastMessage = "Entry deleted"
        showToast = true

        entryToDelete = nil
        load(modelContext: modelContext)
    }
}
