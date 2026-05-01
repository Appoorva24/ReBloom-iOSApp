import SwiftUI
import SwiftData

@Observable
final class MissionsViewModel {
    // MARK: - Data
    var missions: [PartnerMission] = []

    // MARK: - State
    var expandedId: UUID?
    var ringProgress: CGFloat = 0

    // MARK: - Computed
    var completedCount: Int { missions.filter { $0.isCompleted }.count }
    var totalCount: Int { missions.count }

    var progressValue: CGFloat {
        guard totalCount > 0 else { return 0 }
        return CGFloat(completedCount) / CGFloat(totalCount)
    }

    // MARK: - Load Data
    func load(modelContext: ModelContext) {
        var descriptor = FetchDescriptor<PartnerMission>(sortBy: [SortDescriptor(\.date)])
        missions = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Actions
    func markMissionsAsSeen(modelContext: ModelContext) {
        for mission in missions where mission.isNewForPartner {
            mission.isNewForPartner = false
        }
        try? modelContext.save()
    }

    func markComplete(_ mission: PartnerMission, modelContext: ModelContext, syncManager: SyncManager? = nil) {
        withAnimation(.spring(duration: 0.35, bounce: 0.4)) {
            mission.isCompleted = true
            try? modelContext.save()
        }
        load(modelContext: modelContext)
        
        if let sync = syncManager {
            Task { try? await sync.syncMissions(modelContext: modelContext) }
        }
    }

    func toggleExpanded(_ missionId: UUID) {
        withAnimation(.spring(duration: 0.35, bounce: 0.4)) {
            if expandedId == missionId {
                expandedId = nil
            } else {
                expandedId = missionId
            }
        }
    }
}
