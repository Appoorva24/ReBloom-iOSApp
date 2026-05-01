import SwiftUI
import SwiftData

@Observable
final class MemoryJarViewModel {
    // MARK: - Data
    var memories: [Memory] = []
    var profiles: [UserProfile] = []

    // MARK: - State
    var showAddSheet = false
    var selectedMemory: Memory? = nil
    var showToast = false
    var toastMessage = ""

    // MARK: - Computed
    var profile: UserProfile? { profiles.first }

    // MARK: - Load Data
    func load(modelContext: ModelContext) {
        var memoryDescriptor = FetchDescriptor<Memory>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        memories = (try? modelContext.fetch(memoryDescriptor)) ?? []

        let profileDescriptor = FetchDescriptor<UserProfile>()
        profiles = (try? modelContext.fetch(profileDescriptor)) ?? []
    }

    // MARK: - Actions
    func saveMemory(_ memory: Memory, modelContext: ModelContext, syncManager: SyncManager? = nil) {
        modelContext.insert(memory)
        try? modelContext.save()
        toastMessage = "Memory saved 🫙✨"
        showToast = true
        load(modelContext: modelContext)
        
        // TODO: Queue Supabase sync
        if let sync = syncManager {
            Task { try? await sync.syncMemories(modelContext: modelContext) }
        }
    }

    func shareToast() {
        toastMessage = "Sent to \(profile?.partnerName ?? "Partner") 💙"
        showToast = true
    }

    func groupedByDate(_ items: [Memory]) -> [String: [Memory]] {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMMM yyyy"
        return Dictionary(grouping: items) { fmt.string(from: $0.date) }
    }
}
