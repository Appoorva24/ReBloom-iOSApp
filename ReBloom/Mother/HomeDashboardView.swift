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
    @State private var vm = HomeDashboardViewModel()

    // UI-only animation state
    @State private var appeared             = true
    @State private var petalAppeared: [Bool] = Array(repeating: false, count: 7)
    @State private var flowerRotation: Double = 0
    @State private var showBurst              = false
    @State private var affirmationVisible     = false

    private let dayLabels = ["D1", "D2", "D3", "D4", "D5", "D6", "D7"]

    private var isDadMode: Binding<Bool> {
        Binding(
            get: { vm.profile?.role == "husband" },
            set: { newValue in
                vm.switchRole(modelContext: modelContext)
            }
        )
    }

   
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
                            vm.activeNavTarget = .missions
                        } label: {
                            missionsCard
                        }
                        .buttonStyle(.plain)
                        .cardAppear(index: 3, appeared: appeared)

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            vm.activeNavTarget = .journal
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
                            Text(vm.profile?.role == "husband" ? "Mom Mode" : "Dad Mode")
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
                            vm.showProfile = true
                        } label: {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 26, weight: .medium))
                                .foregroundStyle(Color.motherRose)
                        }
                    }
                }
            }
            .navigationDestination(item: $vm.activeNavTarget) { target in
                switch target {
                case .missions:
                    MotherMissionsView()
                case .journal:
                    JournalView()
                }
            }
            .sheet(isPresented: $vm.showProfile)    { ProfileView() }
            .sheet(isPresented: $vm.showMoodPicker) { moodPickerSheet }
            .onAppear {
                vm.load(modelContext: modelContext)
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
                withAnimation(.easeInOut(duration: 1.5).delay(0.6)) { vm.heartScore = vm.heartScore }
            }
            .overlay(alignment: .bottom) {
                if vm.showToast {
                    ToastView(message: vm.toastMessage)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.4), value: vm.showToast)
        }
    }

   
    private var affirmationSection: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("A LITTLE REMINDER")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .kerning(1.6)
                    .foregroundStyle(Color.motherRose.opacity(0.55))
                Text(vm.todayAffirmation)
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
            Text("\(vm.profile?.partnerName ?? "Your partner") is on this journey with you 💛")
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
                    vm.showMoodPicker = true
                } label: {
                    ZStack {
                        ForEach(0..<7, id: \.self) { i in
                            Ellipse()
                                .fill(
                                    LinearGradient(
                                        colors: vm.moodTheme.petalColors,
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
                        if showBurst { BurstParticles(colors: vm.moodTheme.petalColors) }
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: vm.moodTheme.centerColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .shadow(color: vm.moodTheme.accentColor.opacity(0.45), radius: 8, x: 0, y: 3)
                            .pulsing()
                    }
                    .frame(width: 170, height: 170)
                    .rotationEffect(.degrees(flowerRotation))
                    .scaleEffect(vm.moodTheme.flowerScale)
                    .animation(.easeInOut(duration: 0.6), value: vm.moodTheme.flowerScale)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)



                Text("Your bloom is flourishing 🌸")
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.motherTextHeading)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    vm.showMoodPicker = true
                } label: {
                    HStack(spacing: 8) {
                        if vm.selectedMood.isEmpty {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.motherRose)
                            Text("How are you feeling today?")
                                .font(.subheadline)
                                .fontDesign(.rounded)
                                .foregroundStyle(Color.motherTextBody)
                        } else {
                            Text(vm.selectedMood).font(.system(size: 18))
                            Text("Feeling \(vm.moodLabel(vm.selectedMood))")
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
                    Text("Tell \(vm.profile?.partnerName ?? "Partner") how to help")
                        .font(.subheadline.weight(.bold))
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.motherTextHeading)
                    Text("\(vm.completedMissions.count) completed so far")
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
                    let journalCount = vm.moodLogs.filter { !$0.journalNote.isEmpty }.count
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
                        Text("You & \(vm.profile?.partnerName ?? "Partner")")
                            .font(.title3.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundStyle(Color.motherTextHeading)
                    }
                    Spacer()
                    Text("\(Int(vm.heartScore * 100))%")
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
                                            .frame(height: geo.size.height * vm.heartScore)
                                    }
                                }
                            )
                            .animation(.spring(duration: 1.6, bounce: 0.2), value: vm.heartScore)
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
                                vm.selectedMood = emoji
                                vm.moodTheme    = theme
                            }
                            vm.saveMood(emoji, modelContext: modelContext)
                            showBurst = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showBurst = false }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3)  { vm.showMoodPicker = false }
                        } label: {
                            VStack(spacing: 8) {
                                Text(emoji)
                                    .font(.system(size: 36))
                                    .frame(width: 58, height: 58)
                                    .background(
                                        vm.selectedMood == emoji
                                        ? LinearGradient(colors: theme.petalColors.map { $0.opacity(0.22) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [Color.primary.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(
                                            vm.selectedMood == emoji
                                            ? LinearGradient(colors: theme.petalColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                            : LinearGradient(colors: [Color.gray.opacity(0.12)], startPoint: .top, endPoint: .bottom),
                                            lineWidth: vm.selectedMood == emoji ? 2.5 : 1
                                        )
                                    )
                                    .scaleEffect(vm.selectedMood == emoji ? 1.1 : 1.0)
                                    .animation(.spring(duration: 0.3, bounce: 0.4), value: vm.selectedMood)
                                Text(vm.moodLabel(emoji))
                                    .font(.caption2.weight(.semibold))
                                    .fontDesign(.rounded)
                                    .foregroundStyle(vm.selectedMood == emoji ? Color.motherTextHeading : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !vm.selectedMood.isEmpty {
                    Text("Your mood is shared with \(vm.profile?.partnerName ?? "your partner") so they can show up for you 💙")
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
                    Button("Done") { vm.showMoodPicker = false }
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.motherRose)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(28)
        .presentationDragIndicator(.visible)
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
