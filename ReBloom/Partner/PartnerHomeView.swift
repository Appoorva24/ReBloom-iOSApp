import SwiftUI
import SwiftData
import AVFoundation

struct PartnerHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = PartnerHomeViewModel()

    @State private var appeared          = true

    private var isDadMode: Binding<Bool> {
        Binding(
            get: { vm.profile?.role == "husband" },
            set: { _ in
                vm.switchRole(modelContext: modelContext)
            }
        )
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
                            Text(vm.profile?.role == "husband" ? "Mom Mode" : "Dad Mode")
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
                            vm.showProfile = true
                        } label: {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 26, weight: .medium))
                                .foregroundStyle(Color.partnerPrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $vm.showProfile)       { ProfileView() }
            .sheet(isPresented: $vm.showRecoverySheet) { recoveryDetailSheet }
            .sheet(isPresented: $vm.showHeartNotes) { herHeartNotesDetailView }
            .onAppear {
                vm.load(modelContext: modelContext)
                withAnimation(.easeInOut(duration: 1.5).delay(0.6)) { vm.heartScore = min(1.0, Double(vm.missionsCompleted + vm.actualMoodLogs.count) / 20.0) }
            }
        }
    }




    
    private var recoveryCard: some View {
        let tip = vm.postpartumTip(for: vm.daysPostpartum)

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            vm.showRecoverySheet = true
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
                        Text("Day \(vm.daysPostpartum) · Week \(max(1, (vm.daysPostpartum - 1) / 7 + 1))")
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
                    if vm.missionsTotal > 0 {
                        ZStack(alignment: .topTrailing) {
                            ZStack {
                                Circle()
                                    .stroke(Color.partnerLight, lineWidth: 3.5)
                                Circle()
                                    .trim(from: 0, to: vm.missionProgress)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.partnerDeep, Color.partnerPrimary],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                Text("\(Int(vm.missionProgress * 100))%")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color.partnerDeep)
                            }
                            .frame(width: 38, height: 38)
                            
                            if vm.hasNewMissions {
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
                    if vm.missionsTotal > 0 {
                        Text("\(vm.missionsCompleted)/\(vm.missionsTotal) done")
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
            vm.showHeartNotes = true
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
                    if !vm.motherNotes.isEmpty {
                        ZStack(alignment: .topTrailing) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "EEF2FF"))
                                    .frame(width: 28, height: 28)
                                Text("\(vm.motherNotes.count)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color(hex: "4F46E5"))
                            }
                            if vm.hasUnreadNotes {
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
                    Text(vm.motherNotes.isEmpty ? "Waiting for her words" : "\(vm.motherNotes.count == 1 ? "1 note" : "\(vm.motherNotes.count) notes") shared")
                        .font(.subheadline)
                        .foregroundStyle(vm.motherNotes.isEmpty ? Color.partnerTextMuted : Color(hex: "6366F1"))
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
        .disabled(vm.motherNotes.isEmpty)
    }

    
    private var moodCard: some View {
        let info = vm.moodDetails(vm.latestMood)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                if vm.latestMood.isEmpty {
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
                        Text("\(vm.motherName)'s Mood")
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
                        Text(vm.latestMood).font(.system(size: 28))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(vm.motherName) is \(info.label.lowercased())")
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

           
            if vm.actualMoodLogs.count > 1 {
                HStack(spacing: 6) {
                    ForEach(Array(vm.actualMoodLogs.prefix(5).reversed()), id: \.id) { log in
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

                        
                        ForEach(vm.motherNotes, id: \.id) { note in
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
                    Button("Done") { vm.showHeartNotes = false }
                        .foregroundStyle(Color.partnerPrimary)
                }
            }
            .onAppear {
                
                for note in vm.motherNotes where !note.isRead {
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
        let milestone = vm.babyMilestone(for: vm.daysPostpartum)

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
                    Text("About \(vm.babyName.capitalized) · Day \(vm.daysPostpartum)")
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
                    Text("You & \(vm.motherName)")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.partnerNavy)
                }
                Spacer()
                Text("\(Int(vm.heartScore * 100))%")
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
                                        .frame(height: geo.size.height * vm.heartScore)
                                }
                            }
                        )
                        .animation(.spring(duration: 1.6, bounce: 0.2), value: vm.heartScore)
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
        let tip = vm.postpartumTip(for: vm.daysPostpartum)

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
                                Text("DAY \(vm.daysPostpartum) OF POSTPARTUM")
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
            .navigationTitle("Day \(vm.daysPostpartum) · \(tip.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { vm.showRecoverySheet = false }
                        .foregroundStyle(Color.partnerPrimary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }

}

