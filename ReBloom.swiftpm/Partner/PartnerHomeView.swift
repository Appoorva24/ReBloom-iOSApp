import SwiftUI
import SwiftData
import AVFoundation

struct PartnerHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \MoodLog.date, order: .reverse) private var moodLogs: [MoodLog]
    @Query(sort: \PartnerMission.date) private var missions: [PartnerMission]
    @Query(sort: \LoveNote.date, order: .reverse) private var loveNotes: [LoveNote]

    @State private var appeared          = true
    @State private var showProfile       = false
    @State private var showRecoverySheet = false
    @State private var showHeartNotes    = false

    @State private var heartScore: Double = 0

    private var profile: UserProfile? { profiles.first }

    private var isDadMode: Binding<Bool> {
        Binding(
            get: { profile?.role == "partner" },
            set: { newValue in
                switchRole()
            }
        )
    }
    private var daysPostpartum: Int { profile?.daysPostpartum ?? 1 }
    private var motherName: String {
        let n = profile?.partnerName ?? ""; return n.isEmpty ? "She" : n
    }
    private var babyName: String {
        let n = profile?.babyName ?? ""; return n.isEmpty ? "your baby" : n
    }
    private var actualMoodLogs: [MoodLog] {
        moodLogs.filter { $0.mood != "journal" && !$0.mood.isEmpty }
    }
    private var latestMood: String { actualMoodLogs.first?.mood ?? "" }

    
    private var motherNotes: [LoveNote] {
        loveNotes.filter { $0.senderRole == "mother" }
    }

   
    private var hasNewMissions: Bool { missions.contains { $0.isNewForPartner } }
    private var hasUnreadNotes: Bool { motherNotes.contains { !$0.isRead } }

 
    private var missionsCompleted: Int { missions.filter { $0.isCompleted }.count }
    private var missionsTotal: Int { missions.count }
    private var missionProgress: CGFloat {
        guard missionsTotal > 0 else { return 0 }
        return CGFloat(missionsCompleted) / CGFloat(missionsTotal)
    }


    var body: some View {
        NavigationStack {
            ZStack {
                
                LinearGradient(
                    colors: [.partnerBgTop, .partnerBgBottom],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()

                FloatingOrb(color: .partnerSecondary, size: 200).position(x: 80,  y: 160)
                FloatingOrb(color: .partnerPrimary,   size: 180).position(x: 320, y: 420)
                FloatingOrb(color: .partnerLight,     size: 160).position(x: 180, y: 680)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {

                        
                        heartBondCard
                            .cardAppear(index: 0, appeared: appeared)

                        
                        recoveryCard
                            .cardAppear(index: 1, appeared: appeared)

                        
                        moodCard
                            .cardAppear(index: 2, appeared: appeared)

                        
                        HStack(spacing: 12) {
                            missionsCard
                                .cardAppear(index: 3, appeared: appeared)

                            herHeartSpaceCard
                                .cardAppear(index: 4, appeared: appeared)
                        }

                       
                        babyMilestoneCard
                            .cardAppear(index: 5, appeared: appeared)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
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
                                .foregroundStyle(Color.partnerTextMuted)
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
                                .foregroundStyle(Color.partnerPrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showProfile)       { ProfileView() }
            .sheet(isPresented: $showRecoverySheet) { recoveryDetailSheet }
            .sheet(isPresented: $showHeartNotes) { herHeartNotesDetailView }
            .onAppear {
                let score = min(1.0, Double(missionsCompleted + actualMoodLogs.count) / 20.0)
                withAnimation(.easeInOut(duration: 1.5).delay(0.6)) { heartScore = score }
            }
        }
    }




    
    private var recoveryCard: some View {
        let tip = postpartumTip(for: daysPostpartum)

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showRecoverySheet = true
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "93C5FD"), Color(hex: "BFDBFE")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)
                        Text(tip.icon).font(.system(size: 24))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Day \(daysPostpartum) · Week \(max(1, (daysPostpartum - 1) / 7 + 1))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.partnerPrimary)
                        Text(tip.title)
                            .font(.headline)
                            .foregroundStyle(Color.partnerNavy)
                            .lineLimit(2)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.partnerIce)
                            .frame(width: 32, height: 32)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.partnerPrimary)
                    }
                }

                
                Rectangle()
                    .fill(Color.partnerLight)
                    .frame(height: 1)

                Text(tip.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.partnerTextMuted)
                    .lineLimit(2)
            }
            .padding(20)
            .frame(minHeight: 120)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.partnerNavy.opacity(0.08), radius: 14, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    
    private var missionsCard: some View {
        NavigationLink(destination: MissionsView()) {
            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "3A7BD5"), Color(hex: "5B9BD5")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        Image(systemName: "target")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    if missionsTotal > 0 {
                        ZStack(alignment: .topTrailing) {
                            ZStack {
                                Circle()
                                    .stroke(Color.partnerLight, lineWidth: 3.5)
                                Circle()
                                    .trim(from: 0, to: missionProgress)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.partnerDeep, Color.partnerPrimary],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                Text("\(Int(missionProgress * 100))%")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color.partnerDeep)
                            }
                            .frame(width: 38, height: 38)
                            
                            if hasNewMissions {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 3) {
                    Text("Missions")
                        .font(.headline)
                        .foregroundStyle(Color.partnerNavy)
                    if missionsTotal > 0 {
                        Text("\(missionsCompleted)/\(missionsTotal) done")
                            .font(.subheadline)
                            .foregroundStyle(Color.partnerPrimary)
                    } else {
                        Text("Acts of love")
                            .font(.subheadline)
                            .foregroundStyle(Color.partnerTextMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.partnerNavy.opacity(0.08), radius: 14, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    
    private var herHeartSpaceCard: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showHeartNotes = true
        } label: {
            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "6366F1"), Color(hex: "818CF8")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    if !motherNotes.isEmpty {
                        ZStack(alignment: .topTrailing) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "EEF2FF"))
                                    .frame(width: 28, height: 28)
                                Text("\(motherNotes.count)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color(hex: "4F46E5"))
                            }
                            if hasUnreadNotes {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                    .offset(x: 2, y: -2)
                            }
                        }
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "818CF8").opacity(0.4))
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 3) {
                    Text("Her Heart Notes")
                        .font(.headline)
                        .foregroundStyle(Color.partnerNavy)
                    Text(motherNotes.isEmpty ? "Waiting for her words" : "\(motherNotes.count == 1 ? "1 note" : "\(motherNotes.count) notes") shared")
                        .font(.subheadline)
                        .foregroundStyle(motherNotes.isEmpty ? Color.partnerTextMuted : Color(hex: "6366F1"))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.partnerNavy.opacity(0.08), radius: 14, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(motherNotes.isEmpty)
    }

    
    private var moodCard: some View {
        let info = moodDetails(latestMood)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                if latestMood.isEmpty {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "3A7BD5"), Color(hex: "93D0E8")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)
                        Text("💙").font(.system(size: 24))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(motherName)'s Mood")
                            .font(.headline)
                            .foregroundStyle(Color.partnerNavy)
                        Text("She hasn't shared yet today")
                            .font(.subheadline)
                            .foregroundStyle(Color.partnerTextMuted)
                    }
                    Spacer()
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.partnerIce)
                            .frame(width: 52, height: 52)
                        Text(latestMood).font(.system(size: 28))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(motherName) is \(info.label.lowercased())")
                            .font(.headline)
                            .foregroundStyle(Color.partnerNavy)
                        Text(info.supportHint)
                            .font(.subheadline)
                            .foregroundStyle(Color.partnerPrimary)
                            .lineLimit(2)
                    }
                    Spacer()
                }
            }

           
            if actualMoodLogs.count > 1 {
                HStack(spacing: 10) {
                    ForEach(Array(actualMoodLogs.prefix(5).reversed()), id: \.id) { log in
                        VStack(spacing: 4) {
                            Text(log.mood).font(.system(size: 20))
                            Text(log.date, format: .dateTime.weekday(.abbreviated))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Color.partnerTextMuted)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.partnerIce)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(20)
        .frame(minHeight: 120)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.partnerNavy.opacity(0.08), radius: 14, x: 0, y: 5)
    }



    
    private var herHeartNotesDetailView: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.partnerBackground, .white],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {

                        
                        HStack(spacing: 10) {
                            Text("💙")
                                .font(.system(size: 20))
                            Text("She trusts you with these words.")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.partnerTextMuted)
                                .italic()
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.partnerPrimary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        
                        ForEach(motherNotes, id: \.id) { note in
                            noteCard(note)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Her Heart Notes 💕")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showHeartNotes = false }
                        .foregroundStyle(Color.partnerPrimary)
                }
            }
            .onAppear {
                
                for note in motherNotes where !note.isRead {
                    note.isRead = true
                }
                try? modelContext.save()
            }
        }
        .presentationCornerRadius(28)
        .presentationDragIndicator(.visible)
    }

    private func noteCard(_ note: LoveNote) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "6366F1").opacity(0.7))
                Text(note.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                Spacer()
                if !note.isRead {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
            }

            if note.noteText.hasPrefix("[VOICE:") {
                let base64 = String(note.noteText.dropFirst(7).dropLast(1))
                if let data = Data(base64Encoded: base64) {
                    VoicePlaybackView(data: data, tintColor: Color(hex: "6366F1"))
                        .padding(.vertical, 4)
                }
            } else {
                Text(note.noteText)
                    .font(.body)
                    .foregroundStyle(Color.partnerNavy.opacity(0.8))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color(hex: "6366F1").opacity(0.08), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "6366F1").opacity(0.1), lineWidth: 1)
        )
    }

 
    private var babyMilestoneCard: some View {
        let milestone = babyMilestone(for: daysPostpartum)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "0EA5E9"), Color(hex: "38BDF8")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    Text(milestone.icon).font(.system(size: 24))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("About \(babyName.capitalized) · Day \(daysPostpartum)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: "0EA5E9"))
                    Text("Did you know? 🌱")
                        .font(.headline)
                        .foregroundStyle(Color.partnerNavy)
                }

                Spacer(minLength: 0)
            }

            Rectangle()
                .fill(Color.partnerLight)
                .frame(height: 1)

            Text(milestone.fact)
                .font(.subheadline)
                .foregroundStyle(Color.partnerTextMuted)
                .lineLimit(3)
                .lineSpacing(4)
        }
        .padding(20)
        .frame(minHeight: 120)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.partnerNavy.opacity(0.08), radius: 14, x: 0, y: 5)
    }





    private var heartBondCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("YOUR BOND")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.partnerPrimary)
                        .textCase(.uppercase)
                    Text("You & \(motherName)")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.partnerNavy)
                }
                Spacer()
                Text("\(Int(heartScore * 100))%")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.partnerPrimary)
            }

            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.partnerPrimary.opacity(0.06))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "heart.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.partnerPrimary.opacity(0.10))
                        .frame(width: 66, height: 60)
                    
                    Image(systemName: "heart.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.partnerDeep, Color.partnerPrimary, Color.partnerLight],
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
                        .shadow(color: Color.partnerPrimary.opacity(0.3), radius: 8, x: 0, y: 3)
                    
                    Image(systemName: "heart")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.partnerPrimary.opacity(0.30))
                        .frame(width: 66, height: 60)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Grows as you connect 💙")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 6) {
                        BondRow(icon: "target",            label: "Missions completed", color: Color.partnerPrimary)
                        BondRow(icon: "face.smiling",      label: "Moods shared",        color: Color.partnerSecondary)
                        BondRow(icon: "heart.text.square", label: "Notes exchanged",     color: Color.partnerDeep)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.partnerNavy.opacity(0.08), radius: 14, x: 0, y: 5)
    }


    private var recoveryDetailSheet: some View {
        let tip = postpartumTip(for: daysPostpartum)

        return NavigationStack {
            ZStack {
                Color.partnerBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {

                        HStack(spacing: 16) {
                            ZStack {
                                Circle().fill(Color.partnerPrimary.opacity(0.1)).frame(width: 64, height: 64)
                                Text(tip.icon).font(.system(size: 32))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("DAY \(daysPostpartum) OF POSTPARTUM")
                                    .font(.system(size: 10, weight: .bold))
                                    .kerning(1.4).foregroundStyle(Color.partnerPrimary.opacity(0.6))
                                Text(tip.title)
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(Color.partnerNavy)
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Label("What she's going through", systemImage: "heart.text.square.fill")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.partnerPrimary)
                            Text(tip.body)
                                .font(.body)
                                .foregroundStyle(Color.partnerNavy.opacity(0.8)).lineSpacing(5)
                        }
                        .padding(16).background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.partnerPrimary.opacity(0.05), radius: 6, x: 0, y: 3)

                        VStack(alignment: .leading, spacing: 10) {
                            Label("How you can help", systemImage: "hand.raised.fill")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.partnerPrimary)

                            ForEach(tip.actions, id: \.title) { action in
                                HStack(alignment: .top, spacing: 12) {
                                    Text(action.icon).font(.system(size: 20)).frame(width: 30)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(action.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.partnerNavy)
                                        Text(action.detail)
                                            .font(.caption)
                                            .foregroundStyle(Color.partnerTextMuted)
                                            .lineSpacing(2).fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .padding(14).background(Color.partnerPrimary.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }
                    .padding(20).padding(.bottom, 32)
                }
            }
            .navigationTitle("Day \(daysPostpartum) · \(tip.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showRecoverySheet = false }
                        .foregroundStyle(Color.partnerPrimary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

   
    private struct MoodInfo { let label: String; let supportHint: String; let bgColors: [Color] }
    private func moodDetails(_ emoji: String) -> MoodInfo {
        switch emoji {
        case "😔": return MoodInfo(label: "Feeling Sad",          supportHint: "She needs quiet presence. Take the baby.",      bgColors: [Color(hex: "E8D5F5"), Color(hex: "D4B8E8")])
        case "😰": return MoodInfo(label: "Feeling Anxious",      supportHint: "Don't try to fix it — just listen.",             bgColors: [Color(hex: "FFF3C4"), Color(hex: "FFE08A")])
        case "😐": return MoodInfo(label: "Getting Through It",   supportHint: "A small act of care goes a long way.",           bgColors: [Color(hex: "D4E8F5"), Color(hex: "B8D4ED")])
        case "🙂": return MoodInfo(label: "Doing Okay",           supportHint: "Keep the positive energy going today.",          bgColors: [Color(hex: "D4EDD8"), Color(hex: "B8E0BE")])
        case "😊": return MoodInfo(label: "Feeling Good",         supportHint: "She's having a good day — celebrate it!",        bgColors: [Color(hex: "FFF3C4"), Color(hex: "FFD93D").opacity(0.6)])
        default:   return MoodInfo(label: "No mood yet",          supportHint: "Check in on her today.",                         bgColors: [Color(hex: "EBF2FC"), Color(hex: "D4E4F5")])
        }
    }

 
    private struct BabyMilestone { let icon: String; let fact: String }
    private func babyMilestone(for day: Int) -> BabyMilestone {
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

 
    private struct PostpartumAction { let icon: String; let title: String; let detail: String }
    private struct PostpartumTip {
        let icon: String; let title: String; let subtitle: String
        let body: String; let actions: [PostpartumAction]
    }
    private func postpartumTip(for day: Int) -> PostpartumTip {
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
