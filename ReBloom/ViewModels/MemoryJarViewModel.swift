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
    var isLoading = false
    var errorMessage: String?

    // MARK: - Computed
    var profile: UserProfile? { profiles.first }
    var isEmpty: Bool { memories.isEmpty && !isLoading }

    // MARK: - Load Data
    func load(modelContext: ModelContext) {
        let memoryDescriptor = FetchDescriptor<Memory>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        memories = (try? modelContext.fetch(memoryDescriptor)) ?? []

        let profileDescriptor = FetchDescriptor<UserProfile>()
        profiles = (try? modelContext.fetch(profileDescriptor)) ?? []
    }

    // MARK: - Actions
    func saveMemory(_ memory: Memory, modelContext: ModelContext, syncManager: SyncManager) {
        modelContext.insert(memory)
        try? modelContext.save()
        toastMessage = "Memory saved 🫙✨"
        showToast = true
        load(modelContext: modelContext)
        
        // Always sync to Supabase
        Task {
            do {
                try await syncManager.syncMemories(modelContext: modelContext)
            } catch {
                print("[MemoryJar] Sync failed: \(error)")
            }
        }
    }
    
    func shareMemoryWithPartner(_ memory: Memory, modelContext: ModelContext, syncManager: SyncManager) {
        memory.isSharedWithPartner = true
        memory.isNewForPartner = true
        memory.sharedBy = profile?.role ?? "wife"
        try? modelContext.save()
        
        toastMessage = "Sent to \(profile?.partnerName ?? "Partner") 💙"
        showToast = true
        
        // Sync to Supabase
        Task {
            do {
                try await syncManager.syncMemories(modelContext: modelContext)
            } catch {
                print("[MemoryJar] Share sync failed: \(error)")
            }
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
