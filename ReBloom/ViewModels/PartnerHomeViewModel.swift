import SwiftUI
import SwiftData

@Observable
final class PartnerHomeViewModel {
    // MARK: - Data
    var profiles: [UserProfile] = []
    var moodLogs: [MoodLog] = []
    var missions: [PartnerMission] = []
    var loveNotes: [LoveNote] = []

    // MARK: - State
    var showProfile = false
    var showRecoverySheet = false
    var showHeartNotes = false
    var heartScore: Double = 0

    // MARK: - Computed
    var profile: UserProfile? { profiles.first }

    var daysPostpartum: Int { profile?.daysPostpartum ?? 1 }

    var motherName: String {
        let n = profile?.partnerName ?? ""; return n.isEmpty ? "She" : n
    }

    var babyName: String {
        let n = profile?.babyName ?? ""; return n.isEmpty ? "your baby" : n
    }

    var actualMoodLogs: [MoodLog] {
        moodLogs.filter { $0.mood != "journal" && !$0.mood.isEmpty }
    }

    var latestMood: String { actualMoodLogs.first?.mood ?? "" }

    var motherNotes: [LoveNote] {
        loveNotes.filter { $0.senderRole == "wife" }
    }

    var hasNewMissions: Bool { missions.contains { $0.isNewForPartner } }
    var hasUnreadNotes: Bool { motherNotes.contains { !$0.isRead } }

    var missionsCompleted: Int { missions.filter { $0.isCompleted }.count }
    var missionsTotal: Int { missions.count }
    var missionProgress: CGFloat {
        guard missionsTotal > 0 else { return 0 }
        return CGFloat(missionsCompleted) / CGFloat(missionsTotal)
    }

    // MARK: - Load Data
    func load(modelContext: ModelContext) {
        profiles = (try? modelContext.fetch(FetchDescriptor<UserProfile>())) ?? []

        var moodDescriptor = FetchDescriptor<MoodLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        moodLogs = (try? modelContext.fetch(moodDescriptor)) ?? []

        var missionDescriptor = FetchDescriptor<PartnerMission>(sortBy: [SortDescriptor(\.date)])
        missions = (try? modelContext.fetch(missionDescriptor)) ?? []

        var noteDescriptor = FetchDescriptor<LoveNote>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        loveNotes = (try? modelContext.fetch(noteDescriptor)) ?? []

        let score = min(1.0, Double(missionsCompleted + actualMoodLogs.count) / 20.0)
        heartScore = score
    }

    // MARK: - Actions
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

    func markNotesAsRead(modelContext: ModelContext) {
        for note in motherNotes where !note.isRead {
            note.isRead = true
        }
        try? modelContext.save()
    }

    // MARK: - Mood Details
    struct MoodInfo { let label: String; let supportHint: String; let bgColors: [Color] }

    func moodDetails(_ emoji: String) -> MoodInfo {
        switch emoji {
        case "😔": return MoodInfo(label: "Feeling Sad",          supportHint: "She needs quiet presence. Take the baby.",      bgColors: [Color(hex: "E8D5F5"), Color(hex: "D4B8E8")])
        case "😰": return MoodInfo(label: "Feeling Anxious",      supportHint: "Don't try to fix it — just listen.",             bgColors: [Color(hex: "FFF3C4"), Color(hex: "FFE08A")])
        case "😐": return MoodInfo(label: "Getting Through It",   supportHint: "A small act of care goes a long way.",           bgColors: [Color(hex: "D4E8F5"), Color(hex: "B8D4ED")])
        case "🙂": return MoodInfo(label: "Doing Okay",           supportHint: "Keep the positive energy going today.",          bgColors: [Color(hex: "D4EDD8"), Color(hex: "B8E0BE")])
        case "😊": return MoodInfo(label: "Feeling Good",         supportHint: "She's having a good day — celebrate it!",        bgColors: [Color(hex: "FFF3C4"), Color(hex: "FFD93D").opacity(0.6)])
        default:   return MoodInfo(label: "No mood yet",          supportHint: "Check in on her today.",                         bgColors: [Color(hex: "EBF2FC"), Color(hex: "D4E4F5")])
        }
    }

    // MARK: - Baby Milestones
    struct BabyMilestone { let icon: String; let fact: String }

    func babyMilestone(for day: Int) -> BabyMilestone {
        switch day {
        case 1...3:   return BabyMilestone(icon: "👁️", fact: "Can see 20–30 cm — just far enough to see your face clearly.")
        case 4...7:   return BabyMilestone(icon: "👂", fact: "Already recognizes your voice from the womb. She knows you.")
        case 8...14:  return BabyMilestone(icon: "🤲", fact: "Starting to grip your finger when you touch her palm.")
        case 15...21: return BabyMilestone(icon: "😴", fact: "Sleeping 16–17 hours a day — completely normal and healthy.")
        case 22...28: return BabyMilestone(icon: "😊", fact: "First social smiles may appear around now. Watch for them.")
        case 29...42: return BabyMilestone(icon: "👀", fact: "Starting to track moving objects and turn toward your voice.")
        case 43...56: return BabyMilestone(icon: "🗣️", fact: "Making cooing sounds — respond back and she'll do more.")
        case 57...84: return BabyMilestone(icon: "💪", fact: "Tummy time is building neck and shoulder strength daily.")
        default:       return BabyMilestone(icon: "🌱", fact: "Every day she grows and changes. So do you — as a father.")
        }
    }

    // MARK: - Postpartum Tips
    struct PostpartumAction { let icon: String; let title: String; let detail: String }
    struct PostpartumTip {
        let icon: String; let title: String; let subtitle: String
        let body: String; let actions: [PostpartumAction]
    }

    func postpartumTip(for day: Int) -> PostpartumTip {
        switch day {
        case 1...3:
            return PostpartumTip(icon: "🩸", title: "Heaviest Bleeding Days",
                subtitle: "Her body is expelling the uterine lining",
                body: "Postpartum bleeding is heaviest in the first 3 days — like a very heavy period with clots. She may have strong cramps as the uterus contracts. Exhaustion is extreme. She is also producing colostrum, the first milk, which takes enormous energy.",
                actions: [
                    PostpartumAction(icon: "🛏️", title: "Let her rest completely", detail: "She should not be lifting, cooking, or doing chores. Handle everything."),
                    PostpartumAction(icon: "💧", title: "Keep her hydrated", detail: "She needs far more water than usual. Bring it without being asked."),
                    PostpartumAction(icon: "🤫", title: "Keep the environment calm", detail: "Low noise, minimal visitors. Her body and nervous system need quiet.")
                ])
        case 4...7:
            return PostpartumTip(icon: "🤱", title: "Milk Coming In",
                subtitle: "Breast engorgement — painful and emotional",
                body: "Her milk is transitioning from colostrum to full milk. Engorgement can be extremely painful — breasts become hard, swollen, and tender. She may feel overwhelmed by feeding schedules. Night sweats are common as her body sheds pregnancy fluids.",
                actions: [
                    PostpartumAction(icon: "💧", title: "Water after every feed", detail: "Breastfeeding is deeply dehydrating. A large glass every time she feeds."),
                    PostpartumAction(icon: "👶", title: "Take the baby between feeds", detail: "Even 20 uninterrupted minutes helps her body and mind reset."),
                    PostpartumAction(icon: "🤐", title: "No advice about feeding", detail: "No suggestions, no comments. Support whatever she decides.")
                ])
        case 8...14:
            return PostpartumTip(icon: "🧠", title: "Baby Blues Peak",
                subtitle: "Hormones crashing — she may cry without knowing why",
                body: "After birth, progesterone and estrogen drop sharply. This hormonal crash peaks around days 3–10 and causes intense crying, mood swings, and feeling disconnected. This is completely normal. Baby blues typically pass within 2 weeks.",
                actions: [
                    PostpartumAction(icon: "💬", title: "Don't try to fix the tears", detail: "Say: 'I'm here. You don't need to explain.' Hold the space for her."),
                    PostpartumAction(icon: "🏠", title: "Handle all household decisions", detail: "She should not think about anything practical right now."),
                    PostpartumAction(icon: "👀", title: "Watch for PPD signs", detail: "If it doesn't improve by week 2–3, gently encourage her to speak to her doctor.")
                ])
        case 15...21:
            return PostpartumTip(icon: "🩹", title: "Healing, Slowly",
                subtitle: "Stitches still tender, hormones still shifting",
                body: "Whether perineal stitches or C-section incision, they are still healing and very tender. Movement can be painful. She may not look like she's struggling — but the physical healing is still ongoing inside.",
                actions: [
                    PostpartumAction(icon: "🪑", title: "Help her sit comfortably", detail: "A donut cushion helps enormously. Ask before assuming she's okay."),
                    PostpartumAction(icon: "🚫", title: "No rushing 'back to normal'", detail: "No comments about going out or being active yet."),
                    PostpartumAction(icon: "🧴", title: "Handle personal care", detail: "Help her reach things, draw a warm bath, manage medications.")
                ])
        case 22...28:
            return PostpartumTip(icon: "💙", title: "PPD Risk Window",
                subtitle: "1 in 5 mothers experience postpartum depression",
                body: "PPD symptoms often become visible around weeks 3–4. Signs include persistent sadness, feeling like a bad mother, or disconnection from baby. It is a medical condition — not weakness, not failure. Very treatable with early support.",
                actions: [
                    PostpartumAction(icon: "💬", title: "Ask gently and listen fully", detail: "'How are you really feeling this week?' — sit down and truly listen."),
                    PostpartumAction(icon: "🏥", title: "Support her doctor check-in", detail: "Her 6-week appointment is coming. Make sure it happens."),
                    PostpartumAction(icon: "🤝", title: "Remind her she isn't alone", detail: "PPD is very common and very treatable. You are in this together.")
                ])
        case 29...42:
            return PostpartumTip(icon: "🔄", title: "Body Slowly Rebuilding",
                subtitle: "Core weak, joints loose, sleep debt accumulating",
                body: "The relaxin hormone is still present. Her core muscles are weak and may have separated. Sleep debt is building. She may feel dizzy or exhausted for no obvious reason — but the recovery is very real.",
                actions: [
                    PostpartumAction(icon: "🏋️", title: "Handle all heavy lifting", detail: "No groceries or anything heavy. Her core physically cannot handle it yet."),
                    PostpartumAction(icon: "😴", title: "Prioritize her sleep", detail: "Take a night feed when you can. One extra cycle changes her whole day."),
                    PostpartumAction(icon: "🌿", title: "Let her set the pace", detail: "No timeline. No expectation of bouncing back. Recovery is not linear.")
                ])
        case 43...56:
            return PostpartumTip(icon: "💬", title: "Isolation Setting In",
                subtitle: "Support fades — but she still needs it",
                body: "By week 6–8, most friends stop checking in. The world assumes she's back to normal — but she isn't. She may feel isolated and frustrated. Her identity is also shifting as she figures out who she is now.",
                actions: [
                    PostpartumAction(icon: "📍", title: "Plan something just for her", detail: "A walk, her favourite food, one hour completely to herself."),
                    PostpartumAction(icon: "👥", title: "Encourage connection", detail: "A postnatal group or friend visit — human contact helps enormously."),
                    PostpartumAction(icon: "🗣️", title: "Ask about her, not just baby", detail: "'How are you doing?' She is a whole person, not just a mother.")
                ])
        default:
            return PostpartumTip(icon: "☀️", title: "Fourth Trimester Continues",
                subtitle: "Recovery doesn't stop at 3 months",
                body: "Sleep debt, hormonal shifts, and emotional adjustment continue for months. The world may have moved on — but she is still healing, physically and emotionally.",
                actions: [
                    PostpartumAction(icon: "🔁", title: "Keep showing up", detail: "Consistency matters more than grand gestures. She notices."),
                    PostpartumAction(icon: "💬", title: "Keep checking in genuinely", detail: "Even when everything looks fine, 'How are you, really?' still matters."),
                    PostpartumAction(icon: "🌸", title: "Celebrate how far you've come", detail: "Look back at day 1. Both of you have grown more than you realise.")
                ])
        }
    }
}
