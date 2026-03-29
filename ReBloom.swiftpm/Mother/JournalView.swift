import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(
        filter: #Predicate<MoodLog> { $0.mood == "journal" },
        sort: \MoodLog.date,
        order: .reverse
    ) private var journalEntries: [MoodLog]
    
    @State private var entryText = ""
    @State private var journalRecorder = VoiceRecorderManager()
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var entryToDelete: MoodLog?
    @State private var showDeleteConfirmation = false
    @FocusState private var isTextFieldFocused: Bool
    
    private var profile: UserProfile? { profiles.first }
    private var partnerName: String { profile?.partnerName ?? "Partner" }
    
    var body: some View {
        ZStack {
            
            LinearGradient(
                colors: [.motherBgTop, .motherBgBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                   
                    headerQuote
                    
                    
                    writeNewEntryCard
                    
                    HStack(spacing: 12) {
                        Rectangle().fill(Color.secondary.opacity(0.15)).frame(height: 1)
                        Text("or record a voice note")
                            .font(.caption.weight(.semibold))
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                            .fixedSize()
                        Rectangle().fill(Color.secondary.opacity(0.15)).frame(height: 1)
                    }
                    .padding(.horizontal, 24)
                    
                    
                    voiceRecordingCard
                    
                    
                    if !journalEntries.isEmpty {
                        pastEntriesSection
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
        }
        .navigationTitle("Heart Notes")
        .navigationBarTitleDisplayMode(.large)
        .overlay(alignment: .bottom) {
            if showToast {
                ToastView(message: toastMessage)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.4), value: showToast)
        .confirmationDialog(
            "Delete this entry?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Entry", role: .destructive) {
                if let entry = entryToDelete {
                    deleteEntry(entry)
                }
            }
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
        } message: {
            Text("This cannot be undone.")
        }
    }
    
    
    private var headerQuote: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.motherRose)
                Text("YOUR SAFE SPACE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .kerning(1.4)
                    .foregroundStyle(Color.motherRose.opacity(0.8))
            }
            
            Text("Express your feelings, your partner will always understand 💕")
                .font(.subheadline)
                .fontDesign(.rounded)
                .foregroundStyle(Color.motherTextBody)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.8))
                .shadow(color: Color.motherRose.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    
    private var writeNewEntryCard: some View {
        MotherGlassCard {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.motherRose)
                    Text("Write Your Thoughts")
                        .font(.headline)
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.motherTextHeading)
                    Spacer()
                }
                
                
                ZStack(alignment: .topLeading) {
                    if entryText.isEmpty && !isTextFieldFocused {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("What's on your heart today?")
                                .font(.body)
                                .foregroundStyle(Color.secondary.opacity(0.6))
                                .fontDesign(.rounded)
                            Text("Share your feelings, thoughts, or moments...")
                                .font(.caption)
                                .foregroundStyle(Color.secondary.opacity(0.4))
                                .fontDesign(.rounded)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    }
                    
                    TextEditor(text: $entryText)
                        .focused($isTextFieldFocused)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 140)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.motherTextHeading)
                        .onChange(of: entryText) { _, newValue in
                            if newValue.count > 500 {
                                entryText = String(newValue.prefix(500))
                            }
                        }
                }
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.motherRose.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    isTextFieldFocused ? Color.motherRose.opacity(0.3) : Color.motherRose.opacity(0.12),
                                    lineWidth: 1.5
                                )
                        )
                )
                
                
                HStack {
                    Spacer()
                    Text("\(entryText.count)/500")
                        .font(.caption2)
                        .fontDesign(.rounded)
                        .foregroundStyle(entryText.count > 450 ? Color.motherRose : Color.secondary.opacity(0.5))
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                
                VStack(spacing: 12) {
                    
                    Button {
                        saveToJournal()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Save to My Journal")
                                .font(.body.weight(.semibold))
                                .fontDesign(.rounded)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.motherRose, Color.motherDeepRose],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.motherRose.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                    
                    
                    Button {
                        shareWithPartner()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "heart.text.square.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Share with \(partnerName)")
                                .font(.body.weight(.semibold))
                                .fontDesign(.rounded)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.motherRose, Color.motherDeepRose],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.motherRose.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                }
            }
        }
    }
    
    
    private var voiceRecordingCard: some View {
        MotherGlassCard {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.motherLavender)
                    Text("Voice Message")
                        .font(.headline)
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.motherTextHeading)
                    Spacer()
                }
                
                Text("Record and share your voice with \(partnerName)")
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.motherTextBody)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                
                VStack(spacing: 12) {
                    VoiceMessageView(
                        recorder: journalRecorder,
                        tintColor: Color.motherLavender,
                        onSaveVoice: { data in saveVoiceToJournal(data) },
                        onSendVoice: { data in sendVoiceMessage(data) }
                    )
                }
                .padding(.vertical, 8)
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    
    private var pastEntriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.motherRose)
                Text("Past Entries")
                    .font(.title3.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.motherTextHeading)
                Spacer()
                Text("\(journalEntries.count)")
                    .font(.body.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.motherRose)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.motherRose.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            
            VStack(spacing: 12) {
                ForEach(journalEntries, id: \.id) { entry in
                    journalEntryCard(entry: entry)
                }
            }
        }
    }
    
    
    private func journalEntryCard(entry: MoodLog) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date Header
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(Color.motherRose.opacity(0.7))
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.secondary)
                Spacer()
                
                // Delete Button
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    entryToDelete = entry
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.caption)
                        .foregroundStyle(Color.red.opacity(0.7))
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            // Entry Content
            if entry.journalNote.hasPrefix("[VOICE:") {
                let base64 = String(entry.journalNote.dropFirst(7).dropLast(1))
                if let data = Data(base64Encoded: base64) {
                    VoicePlaybackView(data: data, tintColor: Color.motherRose)
                        .padding(.vertical, 8)
                }
            } else {
                Text(entry.journalNote)
                    .font(.body)
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.motherTextHeading)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.motherRose.opacity(0.08), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.motherRose.opacity(0.1), lineWidth: 1)
        )
    }
    
    
    private func saveToJournal() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        let log = MoodLog(
            id: UUID(),
            date: Date(),
            mood: "journal",
            energyLevel: 0,
            journalNote: entryText
        )
        
        modelContext.insert(log)
        try? modelContext.save()
        
        toastMessage = "Saved to your journal 🌸"
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showToast = false }
        }
        
        withAnimation(.spring(duration: 0.4)) {
            entryText = ""
            isTextFieldFocused = false
        }
    }
    
    private func shareWithPartner() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        let note = LoveNote(
            id: UUID(),
            date: Date(),
            senderRole: "mother",
            noteText: entryText,
            isRead: false
        )
        
        modelContext.insert(note)
        try? modelContext.save()
        
        toastMessage = "Shared with \(partnerName)"
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showToast = false }
        }
        
        withAnimation(.spring(duration: 0.4)) {
            entryText = ""
            isTextFieldFocused = false
        }
    }
    
    private func sendVoiceMessage(_ data: Data) {
        let encoded = "[VOICE:\(data.base64EncodedString())]"
        let note = LoveNote(
            id: UUID(),
            date: Date(),
            senderRole: "mother",
            noteText: encoded,
            isRead: false
        )
        
        modelContext.insert(note)
        try? modelContext.save()
        
        toastMessage = "Voice note sent to \(partnerName)!"
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showToast = false }
        }
    }
    
    private func saveVoiceToJournal(_ data: Data) {
        let encoded = "[VOICE:\(data.base64EncodedString())]"
        let log = MoodLog(
            id: UUID(),
            date: Date(),
            mood: "journal",
            energyLevel: 0,
            journalNote: encoded
        )
        
        modelContext.insert(log)
        try? modelContext.save()
        
        toastMessage = "Voice note saved to journal 🌸"
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showToast = false }
        }
    }
    
    private func deleteEntry(_ entry: MoodLog) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        withAnimation {
            modelContext.delete(entry)
            try? modelContext.save()
        }
        
        toastMessage = "Entry deleted"
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showToast = false }
        }
        
        entryToDelete = nil
    }
}
