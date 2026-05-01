import SwiftUI
import SwiftData

@Observable
final class HomeDashboardViewModel {
    // MARK: - Data
    var profiles: [UserProfile] = []
    var moodLogs: [MoodLog] = []
    var exerciseLogs: [ExerciseLog] = []
    var completedMissions: [PartnerMission] = []
    var allLoveNotes: [LoveNote] = []

    // MARK: - State
    var selectedMood = ""
    var moodTheme: MoodTheme = .unset
    var showToast = false
    var toastMessage = "Saved 🩷"
    var showProfile = false
    var showMoodPicker = false
    var heartScore: Double = 0
    var affirmationIndex = 0
    var activeNavTarget: NavigationTarget? = nil

    // MARK: - Computed
    var profile: UserProfile? { profiles.first }

    let affirmations: [String] = [
        "You were made for this. Even on the hardest days. 🩷",
        "Healing is not linear. Every day forward counts. 🩷",
        "You are enough, exactly as you are right now. 🩷",
        "Rest is not laziness — it is how you heal. 🩷",
        "Your baby is so lucky to have a mama like you. 🩷",
        "It is okay to not be okay. You are still doing great. 🩷",
        "You carried life. Give yourself so much grace. 🩷",
        "Asking for help is strength, not weakness. 🩷",
        "Today you showed up. That alone is enough. 🩷",
        "Your love for your baby is already perfect. 🩷",
        "This season is hard. It will not last forever. 🩷",
        "You are not alone in this journey, mama. 🩷",
        "Bloom at your own pace. There is no rush. 🩷",
        "Every small step is still a step forward. 🩷",
        "You are stronger than you know, braver than you feel. 🩷",
        "Motherhood is the hardest and most beautiful thing. 🩷",
        "Your body created a miracle. Be gentle with it now. 🩷",
        "The love you give every day matters more than you know. 🩷"
    ]

    var todayAffirmation: String {
        affirmations[affirmationIndex % affirmations.count]
    }

    // MARK: - Load Data
    func load(modelContext: ModelContext) {
        let profileDescriptor = FetchDescriptor<UserProfile>()
        profiles = (try? modelContext.fetch(profileDescriptor)) ?? []

        var moodDescriptor = FetchDescriptor<MoodLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        moodLogs = (try? modelContext.fetch(moodDescriptor)) ?? []

        var exerciseDescriptor = FetchDescriptor<ExerciseLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        exerciseLogs = (try? modelContext.fetch(exerciseDescriptor)) ?? []

        let missionPredicate = #Predicate<PartnerMission> { $0.isCompleted }
        var missionDescriptor = FetchDescriptor<PartnerMission>(predicate: missionPredicate, sortBy: [SortDescriptor(\.date, order: .reverse)])
        completedMissions = (try? modelContext.fetch(missionDescriptor)) ?? []

        var noteDescriptor = FetchDescriptor<LoveNote>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        allLoveNotes = (try? modelContext.fetch(noteDescriptor)) ?? []

        affirmationIndex = Int.random(in: 0..<affirmations.count)

        let score = min(1.0, Double(completedMissions.count + moodLogs.count + allLoveNotes.count) / 20.0)
        heartScore = score
    }

    // MARK: - Actions
    func saveMood(_ emoji: String, modelContext: ModelContext, syncManager: SyncManager? = nil) {
        let log = MoodLog(mood: emoji, energyLevel: moodEnergy(emoji))
        modelContext.insert(log)
        try? modelContext.save()
        toastMessage = "Mood saved 💛"
        showToast = true

        // Reload data after save
        load(modelContext: modelContext)
        
        // TODO: Queue Supabase sync
        if let sync = syncManager {
            Task { try? await sync.syncMoodLogs(modelContext: modelContext) }
        }
    }

    func switchRole(modelContext: ModelContext) {
        guard let p = profile else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        p.role = (p.role == "husband") ? "wife" : "husband"
        let tempName = p.name
        p.name = p.partnerName
        p.partnerName = tempName
        try? modelContext.save()
        load(modelContext: modelContext)
    }

    func moodLabel(_ emoji: String) -> String {
        switch emoji {
        case "😔": return "Sad";    case "😰": return "Anxious"
        case "😐": return "Okay";   case "🙂": return "Good"
        case "😊": return "Great";  default:   return ""
        }
    }

    func moodEnergy(_ emoji: String) -> Int {
        switch emoji {
        case "😔": return 1; case "😰": return 2
        case "😐": return 3; case "🙂": return 4
        case "😊": return 5; default:   return 3
        }
    }
}
