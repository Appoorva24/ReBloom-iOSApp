import SwiftUI
import SwiftData

@Observable
final class PartnerMemoriesViewModel {
    // MARK: - Data
    var allMemories: [Memory] = []
    var profiles: [UserProfile] = []

    // MARK: - State
    var showAddSheet = false
    var selectedMemory: Memory? = nil
    var showToast = false
    var toastMessage = ""

    // MARK: - Computed
    var profile: UserProfile? { profiles.first }

    var memories: [Memory] {
        allMemories.filter { $0.sharedBy == "husband" || $0.isSharedWithPartner }
    }

    // MARK: - Load Data
    func load(modelContext: ModelContext) {
        var memoryDescriptor = FetchDescriptor<Memory>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        allMemories = (try? modelContext.fetch(memoryDescriptor)) ?? []

        let profileDescriptor = FetchDescriptor<UserProfile>()
        profiles = (try? modelContext.fetch(profileDescriptor)) ?? []
    }

    // MARK: - Actions
    func saveMemory(_ memory: Memory, modelContext: ModelContext) {
        modelContext.insert(memory)
        try? modelContext.save()
        toastMessage = "Memory saved 🫙✨"
        showToast = true
        load(modelContext: modelContext)
    }

    func markMemoriesAsSeen(modelContext: ModelContext) {
        for memory in allMemories where memory.isNewForPartner {
            memory.isNewForPartner = false
        }
        try? modelContext.save()
    }

    func groupedByDate(_ items: [Memory]) -> [String: [Memory]] {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMMM yyyy"
        return Dictionary(grouping: items) { fmt.string(from: $0.date) }
    }
}
