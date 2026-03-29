import SwiftUI
import SwiftData
import AVFoundation

enum MoodTheme {
    case sad, anxious, neutral, content, happy, unset

    var petalColors: [Color] {
        switch self {
        case .sad:     return [Color(hex: "FECDD3"), Color(hex: "FFF3C4")]
        case .anxious: return [Color(hex: "FCA5B8"), Color(hex: "FFE69A")]
        case .neutral: return [Color(hex: "F9829E"), Color(hex: "FFD966")]
        case .content: return [Color(hex: "F06292"), Color(hex: "FFC845")]
        case .happy:   return [Color(hex: "E91E73"), Color(hex: "FFB020")]
        case .unset:   return [Color(hex: "F9829E"), Color(hex: "FFD966")]
        }
    }

    var centerColors: [Color] {
        switch self {
        case .sad:     return [Color(hex: "FFF3C4"), Color(hex: "FFB8C6")]
        case .anxious: return [Color(hex: "FFE08A"), Color(hex: "F48FB1")]
        case .neutral: return [Color(hex: "FFCC44"), Color(hex: "EC6B8A")]
        case .content: return [Color(hex: "FFB833"), Color(hex: "E54C7C")]
        case .happy:   return [Color(hex: "FFA010"), Color(hex: "D81B60")]
        case .unset:   return [Color(hex: "FFCC44"), Color(hex: "EC6B8A")]
        }
    }

    var accentColor: Color {
        switch self {
        case .sad:     return Color(hex: "FECDD3")
        case .anxious: return Color(hex: "FCA5B8")
        case .neutral: return Color(hex: "F9829E")
        case .content: return Color(hex: "F06292")
        case .happy:   return Color(hex: "E91E73")
        case .unset:   return Color(hex: "F9829E")
        }
    }

    var flowerScale: CGFloat {
        switch self {
        case .sad:     return 0.7
        case .anxious: return 0.8
        case .neutral: return 0.9
        case .content: return 1.0
        case .happy:   return 1.1
        case .unset:   return 0.9
        }
    }

    static func from(_ emoji: String) -> MoodTheme {
        switch emoji {
        case "😔": return .sad
        case "😰": return .anxious
        case "😐": return .neutral
        case "🙂": return .content
        case "😊": return .happy
        default:   return .unset
        }
    }
}


enum NavigationTarget: Hashable, Identifiable {
    case missions
    case journal
    var id: Self { self }
}


struct HomeDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \MoodLog.date, order: .reverse) private var moodLogs: [MoodLog]
    @Query(sort: \ExerciseLog.date, order: .reverse) private var exerciseLogs: [ExerciseLog]
    @Query(filter: #Predicate<PartnerMission> { $0.isCompleted }, sort: \PartnerMission.date, order: .reverse)
    private var completedMissions: [PartnerMission]
    @Query(sort: \LoveNote.date, order: .reverse) private var allLoveNotes: [LoveNote]

    @State private var appeared             = true
    @State private var selectedMood         = ""
    @State private var moodTheme: MoodTheme = .unset
    @State private var showToast            = false
    @State private var toastMessage         = "Saved 🩷"
    @State private var showProfile          = false


    @State private var petalAppeared: [Bool] = Array(repeating: false, count: 7)
    @State private var flowerRotation: Double = 0
    @State private var showBurst              = false
    @State private var showMoodPicker         = false
    @State private var affirmationVisible     = false
    @State private var heartScore: Double     = 0
    @State private var affirmationIndex       = 0

    @State private var activeNavTarget: NavigationTarget? = nil

    private var profile: UserProfile? { profiles.first }

    private var isDadMode: Binding<Bool> {
        Binding(
            get: { profile?.role == "partner" },
            set: { newValue in
                switchRole()
            }
        )
    }

    private let affirmations: [String] = [
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

    private var todayAffirmation: String {
        affirmations[affirmationIndex % affirmations.count]
    }

    private let dayLabels = ["D1", "D2", "D3", "D4", "D5", "D6", "D7"]

   
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.motherBgTop, .motherBgBottom],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()

                FloatingOrb(color: .motherSecondary, size: 200).position(x: 80,  y: 160)
                FloatingOrb(color: .motherPrimary,   size: 180).position(x: 300, y: 420)
                FloatingOrb(color: .motherLavender,  size: 160).position(x: 200, y: 680)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 26) {

                        affirmationSection
                            .cardAppear(index: 0, appeared: appeared)

                        connectionLineSection
                            .cardAppear(index: 1, appeared: appeared)

                        bloomFlowerSection
                            .cardAppear(index: 2, appeared: appeared)

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            activeNavTarget = .missions
                        } label: {
                            missionsCard
                        }
                        .buttonStyle(.plain)
                        .cardAppear(index: 3, appeared: appeared)

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            activeNavTarget = .journal
                        } label: {
                            journalCard
                        }
                        .buttonStyle(.plain)
                        .cardAppear(index: 4, appeared: appeared)

                        heartBondCard
                            .cardAppear(index: 5, appeared: appeared)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                }
            }
            .navigationTitle("Us")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        HStack(spacing: 6) {
                            Text(profile?.role == "partner" ? "Mom Mode" : "Dad Mode")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.motherTextBody)
                            Toggle("", isOn: isDadMode)
                                .toggleStyle(SwitchToggleStyle(tint: Color.partnerPrimary))
                                .labelsHidden()
                                .scaleEffect(0.75)
                                .frame(width: 42, height: 26)
                        }

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showProfile = true
                        } label: {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 26, weight: .medium))
                                .foregroundStyle(Color.motherRose)
                        }
                    }
                }
            }
            .navigationDestination(item: $activeNavTarget) { target in
                switch target {
                case .missions:
                    MotherMissionsView()
                case .journal:
                    JournalView()
                }
            }
            .sheet(isPresented: $showProfile)    { ProfileView() }
            .sheet(isPresented: $showMoodPicker) { moodPickerSheet }
            .onAppear {

                affirmationIndex = Int.random(in: 0..<affirmations.count)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeIn(duration: 0.8)) { affirmationVisible = true }
                }
                for i in 0..<7 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.12) {
                        withAnimation(.spring(duration: 0.55, bounce: 0.35)) { petalAppeared[i] = true }
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                        flowerRotation = 360
                    }
                }
                let score = min(1.0, Double(completedMissions.count + moodLogs.count + allLoveNotes.count) / 20.0)
                withAnimation(.easeInOut(duration: 1.5).delay(0.6)) { heartScore = score }
            }
            .overlay(alignment: .bottom) {
                if showToast {
                    ToastView(message: toastMessage)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.4), value: showToast)
        }
    }

   
    private var affirmationSection: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("A LITTLE REMINDER")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .kerning(1.6)
                    .foregroundStyle(Color.motherRose.opacity(0.55))
                Text(todayAffirmation)
                    .font(.title3.weight(.semibold))
                    .fontDesign(.rounded)
                    .italic()
                    .foregroundStyle(Color.motherTextHeading)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(affirmationVisible ? 1 : 0)
        .padding(.top, 2)
    }

    
    private var connectionLineSection: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.motherRose)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.motherRose.opacity(0.3), lineWidth: 3)
                        .scaleEffect(1.5)
                )
            Text("\(profile?.partnerName ?? "Your partner") is on this journey with you 💛")
                .font(.subheadline.weight(.medium))
                .fontDesign(.rounded)
                .foregroundStyle(Color.motherTextBody)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.motherRose.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.motherRose.opacity(0.15), lineWidth: 1)
                )
        )
    }

   
    private var bloomFlowerSection: some View {
        MotherGlassCard {
            VStack(spacing: 18) {
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    showMoodPicker = true
                } label: {
                    ZStack {
                        ForEach(0..<7, id: \.self) { i in
                            Ellipse()
                                .fill(
                                    LinearGradient(
                                        colors: moodTheme.petalColors,
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 30, height: 68)
                                .offset(y: -38)
                                .rotationEffect(.degrees(Double(i) * (360.0 / 7.0)))
                                .scaleEffect(petalAppeared[i] ? 1.0 : 0)
                                .opacity(petalAppeared[i] ? 1 : 0)
                        }
                        if showBurst { BurstParticles(colors: moodTheme.petalColors) }
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: moodTheme.centerColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .shadow(color: moodTheme.accentColor.opacity(0.45), radius: 8, x: 0, y: 3)
                            .pulsing()
                    }
                    .frame(width: 170, height: 170)
                    .rotationEffect(.degrees(flowerRotation))
                    .scaleEffect(moodTheme.flowerScale)
                    .animation(.easeInOut(duration: 0.6), value: moodTheme.flowerScale)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)



                Text("Your bloom is flourishing 🌸")
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.motherTextHeading)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showMoodPicker = true
                } label: {
                    HStack(spacing: 8) {
                        if selectedMood.isEmpty {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.motherRose)
                            Text("How are you feeling today?")
                                .font(.subheadline)
                                .fontDesign(.rounded)
                                .foregroundStyle(Color.motherTextBody)
                        } else {
                            Text(selectedMood).font(.system(size: 18))
                            Text("Feeling \(moodLabel(selectedMood))")
                                .font(.subheadline)
                                .fontDesign(.rounded)
                                .foregroundStyle(Color.motherTextBody)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.secondary.opacity(0.4))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.motherRose.opacity(0.08), Color.motherRose.opacity(0.04)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.motherRose.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
    }

    
    private var missionsCard: some View {
        MotherGlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.motherRose.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Text("🎯")
                        .font(.system(size: 26))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("MISSIONS FOR PARTNER")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .kerning(1.4)
                        .foregroundStyle(Color.motherRose.opacity(0.6))
                    Text("Tell \(profile?.partnerName ?? "Partner") how to help")
                        .font(.subheadline.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.motherTextHeading)
                    Text("\(completedMissions.count) completed so far")
                        .font(.caption)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.motherRose.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.motherRose)
                }
            }
            .padding(.vertical, 4)
        }
    }

    
    private var journalCard: some View {
        MotherGlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.motherLavender.opacity(0.25))
                        .frame(width: 52, height: 52)
                    Text("📖")
                        .font(.system(size: 26))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("HEART NOTES")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .kerning(1.4)
                        .foregroundStyle(Color.motherLavender.opacity(0.9))
                    Text("Write or speak your feelings")
                        .font(.subheadline.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.motherTextHeading)
                    let journalCount = moodLogs.filter { !$0.journalNote.isEmpty }.count
                    Text("\(journalCount) \(journalCount == 1 ? "entry" : "entries") written")
                        .font(.caption)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.motherLavender.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.motherLavender)
                }
            }
            .padding(.vertical, 4)
        }
    }

    
    private var heartBondCard: some View {
        MotherGlassCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.motherRose)
                                .frame(width: 7, height: 7)
                            Text("YOUR BOND")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .kerning(1.6)
                                .foregroundStyle(Color.motherRose)
                        }
                        Text("You & \(profile?.partnerName ?? "Partner")")
                            .font(.title3.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundStyle(Color.motherTextHeading)
                    }
                    Spacer()
                    Text("\(Int(heartScore * 100))%")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.motherRose)
                }

                HStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.motherRose.opacity(0.08))
                            .frame(width: 100, height: 100)
                        Image(systemName: "heart.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(Color.motherRose.opacity(0.10))
                            .frame(width: 66, height: 60)
                        Image(systemName: "heart.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "E91E73"), Color(hex: "FF6B9D"), Color(hex: "FFB020")],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 66, height: 60)
                            .mask(
                                GeometryReader { geo in
                                    VStack(spacing: 0) {
                                        Spacer(minLength: 0)
                                        Rectangle()
                                            .frame(height: geo.size.height * heartScore)
                                    }
                                }
                            )
                            .animation(.spring(duration: 1.6, bounce: 0.2), value: heartScore)
                            .shadow(color: Color.motherRose.opacity(0.35), radius: 10, x: 0, y: 4)
                        // Heart border
                        Image(systemName: "heart")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(Color.motherRose.opacity(0.35))
                            .frame(width: 66, height: 60)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Grows as you connect 💛")
                            .font(.caption)
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 6) {
                            BondRow(icon: "target",            label: "Missions completed", color: Color.motherRose)
                            BondRow(icon: "face.smiling",      label: "Moods shared",        color: Color(hex: "F9829E"))
                            BondRow(icon: "heart.text.square", label: "Notes exchanged",     color: Color.motherLavender)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    
    private var moodPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text("Tap your mood to\ncolour your bloom 🌸")
                    .font(.title3.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.motherTextHeading)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                HStack(spacing: 14) {
                    ForEach(["😔", "😰", "😐", "🙂", "😊"], id: \.self) { emoji in
                        let theme = MoodTheme.from(emoji)
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.spring(duration: 0.4, bounce: 0.4)) {
                                selectedMood = emoji
                                moodTheme    = theme
                            }
                            saveMood(emoji)
                            showBurst = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showBurst = false }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3)  { showMoodPicker = false }
                        } label: {
                            VStack(spacing: 8) {
                                Text(emoji)
                                    .font(.system(size: 36))
                                    .frame(width: 58, height: 58)
                                    .background(
                                        selectedMood == emoji
                                        ? LinearGradient(colors: theme.petalColors.map { $0.opacity(0.22) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [Color.primary.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(
                                            selectedMood == emoji
                                            ? LinearGradient(colors: theme.petalColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                            : LinearGradient(colors: [Color.gray.opacity(0.12)], startPoint: .top, endPoint: .bottom),
                                            lineWidth: selectedMood == emoji ? 2.5 : 1
                                        )
                                    )
                                    .scaleEffect(selectedMood == emoji ? 1.1 : 1.0)
                                    .animation(.spring(duration: 0.3, bounce: 0.4), value: selectedMood)
                                Text(moodLabel(emoji))
                                    .font(.caption2.weight(.semibold))
                                    .fontDesign(.rounded)
                                    .foregroundStyle(selectedMood == emoji ? Color.motherTextHeading : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !selectedMood.isEmpty {
                    Text("Your mood is shared with \(profile?.partnerName ?? "your partner") so they can show up for you 💙")
                        .font(.caption)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("How are you feeling?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showMoodPicker = false }
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.motherRose)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(28)
        .presentationDragIndicator(.visible)
    }

    
    private func moodLabel(_ emoji: String) -> String {
        switch emoji {
        case "😔": return "Sad";    case "😰": return "Anxious"
        case "😐": return "Okay";   case "🙂": return "Good"
        case "😊": return "Great";  default:   return ""
        }
    }

    private func saveMood(_ emoji: String) {
        let log = MoodLog(mood: emoji, energyLevel: moodEnergy(emoji))
        modelContext.insert(log)
        try? modelContext.save()
        toastMessage = "Mood saved 💛"
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { showToast = false }
    }

    private func moodEnergy(_ emoji: String) -> Int {
        switch emoji {
        case "😔": return 1; case "😰": return 2
        case "😐": return 3; case "🙂": return 4
        case "😊": return 5; default:   return 3
        }
    }

    private func switchRole() {
        guard let p = profile else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        p.role = (p.role == "partner") ? "mother" : "partner"
        let tempName = p.name
        p.name = p.partnerName
        p.partnerName = tempName
        try? modelContext.save()
    }
}


struct BondRow: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 14)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}
