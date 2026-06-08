import Foundation
import SwiftData
import Network
import Supabase

// MARK: - Supabase DTOs for Sync
/// Lightweight Codable structs matching Supabase table columns.
/// Uses `owner_id` to match the database schema.

struct SupabaseMoodLog: Codable, Identifiable {
    let id: String?
    let owner_id: String
    let mood: String
    let energy_level: Int
    let journal_note: String?
    let date: String
}

struct SupabaseLoveNote: Codable, Identifiable {
    let id: String?
    let owner_id: String
    let sender_role: String
    let note_text: String
    let is_read: Bool
    let date: String
}

struct SupabaseMission: Codable, Identifiable {
    let id: String?
    let owner_id: String
    let mission_title: String
    let mission_description: String?
    let is_completed: Bool
    let is_new_for_partner: Bool
    let week_number: Int
    let date: String
}

struct SupabaseMemory: Codable, Identifiable {
    let id: String?
    let owner_id: String
    let title: String?
    let caption: String?
    let image_url: String?
    let is_shared_with_partner: Bool
    let is_new_for_partner: Bool
    let shared_by: String?
    let date: String
}

struct SupabaseExerciseLog: Codable, Identifiable {
    let id: String?
    let owner_id: String
    let exercise_name: String
    let duration_seconds: Int
    let week_number: Int
    let date: String
}

@Observable
final class SyncManager {
    // MARK: - State
    var isSyncing = false
    var isOnline = true
    var lastSyncDate: Date?
    var syncError: String?
    
    /// Timer for fallback periodic partner data polling.
    private var pollingTimer: Timer?
    
    /// Supabase Realtime channels for live updates.
    private var realtimeChannels: [RealtimeChannelV2] = []
    private var isRealtimeActive = false
    
    private let authManager: AuthManager
    private let client = SupabaseManager.client
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.rebloom.networkmonitor")
    
    /// Reference to notification service for creating partner notifications.
    var notificationService: NotificationService?
    
    let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    
    init(authManager: AuthManager) {
        self.authManager = authManager
        startNetworkMonitoring()
    }
    
    deinit {
        monitor.cancel()
        pollingTimer?.invalidate()
    }
    
    // MARK: - Network Monitoring
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = (path.status == .satisfied)
            }
        }
        monitor.start(queue: monitorQueue)
    }
    
    // MARK: - Retry Helper
    /// Retries an async operation with a delay between attempts.
    private func retryOperation<T>(
        retries: Int = 1,
        delay: TimeInterval = 2.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        for attempt in 0...retries {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt < retries {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        throw lastError ?? SyncError.syncFailed("Unknown error after retries")
    }
    
    // MARK: - Resolve User ID
    /// Gets the Supabase UUID for the currently signed-in Apple user.
    func resolveUserID() async throws -> String {
        // First check if Supabase auth session has the user ID
        if let supabaseID = authManager.currentSupabaseUserID {
            // Verify this user exists in our users table
            let rows: [SupabaseUser] = try await client.from("users")
                .select()
                .eq("id", value: supabaseID)
                .execute()
                .value
            
            if let userID = rows.first?.id {
                return userID
            }
        }
        
        // Fallback to auth ID lookup
        guard let authID = authManager.currentSupabaseUserID else {
            throw SyncError.notAuthenticated
        }
        
        let rows: [SupabaseUser] = try await client.from("users")
            .select()
            .eq("auth_id", value: authID)
            .execute()
            .value
        
        guard let userID = rows.first?.id else {
            throw SyncError.userNotFound
        }
        return userID
    }
    
    // MARK: - Get Partner ID
    /// Resolves the connected partner's Supabase UUID via the connections table.
    func getPartnerID() async throws -> String? {
        let myID = try await resolveUserID()
        
        let connections: [SupabaseConnection] = try await client.from("connections")
            .select()
            .or("user1_id.eq.\(myID),user2_id.eq.\(myID)")
            .eq("status", value: "accepted")
            .execute()
            .value
        
        guard let conn = connections.first else { return nil }
        return conn.user1_id == myID ? conn.user2_id : conn.user1_id
    }
    
    // MARK: - Sync All (Push + Pull)
    /// Orchestrates syncing all data types — pushes local, then pulls partner data.
    func syncAll(modelContext: ModelContext) async {
        guard isOnline, !isSyncing else { return }
        
        await MainActor.run { isSyncing = true; syncError = nil }
        
        // Push local data to Supabase
        do { try await retryOperation { try await self.syncMoodLogs(modelContext: modelContext) } } catch { print("[Sync] MoodLogs push failed: \(error)") }
        do { try await retryOperation { try await self.syncLoveNotes(modelContext: modelContext) } } catch { print("[Sync] LoveNotes push failed: \(error)") }
        do { try await retryOperation { try await self.syncMissions(modelContext: modelContext) } } catch { print("[Sync] Missions push failed: \(error)") }
        do { try await retryOperation { try await self.syncMemories(modelContext: modelContext) } } catch { print("[Sync] Memories push failed: \(error)") }
        do { try await retryOperation { try await self.syncExerciseLogs(modelContext: modelContext) } } catch { print("[Sync] ExerciseLogs push failed: \(error)") }
        
        // Pull partner data from Supabase
        do { try await retryOperation { try await self.fetchPartnerData(modelContext: modelContext) } } catch { print("[Sync] Partner fetch failed: \(error)") }
        
        await MainActor.run {
            isSyncing = false
            lastSyncDate = Date()
        }
    }
    
    // MARK: - Push: Sync Mood Logs
    /// Pushes all local MoodLog entries to Supabase (upsert by UUID).
    func syncMoodLogs(modelContext: ModelContext) async throws {
        let userID = try await resolveUserID()
        
        let logs = try await MainActor.run {
            try modelContext.fetch(FetchDescriptor<MoodLog>())
        }
        
        guard !logs.isEmpty else { return }
        
        let records = logs.map { log in
            SupabaseMoodLog(
                id: log.id.uuidString,
                owner_id: userID,
                mood: log.mood,
                energy_level: log.energyLevel,
                journal_note: log.journalNote.isEmpty ? nil : log.journalNote,
                date: iso.string(from: log.date)
            )
        }
        
        try await client.from("mood_logs")
            .upsert(records, onConflict: "id")
            .execute()
    }
    
    // MARK: - Push: Sync Love Notes
    /// Pushes all local LoveNote entries to Supabase (upsert by UUID).
    func syncLoveNotes(modelContext: ModelContext) async throws {
        let userID = try await resolveUserID()
        
        let notes = try await MainActor.run {
            try modelContext.fetch(FetchDescriptor<LoveNote>())
        }
        
        guard !notes.isEmpty else { return }
        
        let records = notes.map { note in
            SupabaseLoveNote(
                id: note.id.uuidString,
                owner_id: userID,
                sender_role: note.senderRole,
                note_text: note.noteText,
                is_read: note.isRead,
                date: iso.string(from: note.date)
            )
        }
        
        try await client.from("love_notes")
            .upsert(records, onConflict: "id")
            .execute()
        
        // Create notification for partner if there are unread notes
        if let partnerID = try? await getPartnerID() {
            let unreadCount = notes.filter { !$0.isRead }.count
            if unreadCount > 0 {
                await notificationService?.createNotification(
                    type: .loveNoteReceived,
                    recipientID: partnerID,
                    message: "You have a new love note 💌"
                )
            }
        }
    }
    
    // MARK: - Mark Love Note as Read
    /// Updates a love note's read status directly in Supabase.
    func markNoteAsRead(noteID: UUID) async throws {
        try await client.from("love_notes")
            .update(["is_read": true])
            .eq("id", value: noteID.uuidString)
            .execute()
    }
    
    // MARK: - Push: Sync Missions
    /// Pushes all local PartnerMission entries to Supabase (upsert by UUID).
    func syncMissions(modelContext: ModelContext) async throws {
        let userID = try await resolveUserID()
        
        let missions = try await MainActor.run {
            try modelContext.fetch(FetchDescriptor<PartnerMission>())
        }
        
        guard !missions.isEmpty else { return }
        
        let records = missions.map { m in
            SupabaseMission(
                id: m.id.uuidString,
                owner_id: userID,
                mission_title: m.missionTitle,
                mission_description: m.missionDescription.isEmpty ? nil : m.missionDescription,
                is_completed: m.isCompleted,
                is_new_for_partner: m.isNewForPartner,
                week_number: m.weekNumber,
                date: iso.string(from: m.date)
            )
        }
        
        try await client.from("missions")
            .upsert(records, onConflict: "id")
            .execute()
        
        // Create notification if mission was just completed
        if let partnerID = try? await getPartnerID() {
            let justCompleted = missions.filter { $0.isCompleted }
            if !justCompleted.isEmpty {
                await notificationService?.createNotification(
                    type: .missionCompleted,
                    recipientID: partnerID,
                    message: "A mission was completed! ✅"
                )
            }
        }
    }
    
    // MARK: - Push: Sync Memories
    /// Pushes all local Memory entries to Supabase with image upload.
    func syncMemories(modelContext: ModelContext) async throws {
        let userID = try await resolveUserID()
        
        let memories = try await MainActor.run {
            try modelContext.fetch(FetchDescriptor<Memory>())
        }
        
        guard !memories.isEmpty else { return }
        
        for m in memories {
            // Upload image to Supabase Storage if there's image data and no URL yet
            var imageURL: String? = await MainActor.run { m.imageURL }
            let imgData = await MainActor.run { m.imageData }
            
            if imageURL == nil && !imgData.isEmpty {
                do {
                    let memID = await MainActor.run { m.id }
                    imageURL = try await ImageStorageManager.uploadImage(imageData: imgData, memoryID: memID)
                    
                    // Save the URL back to the local model
                    await MainActor.run {
                        m.imageURL = imageURL
                        try? modelContext.save()
                    }
                } catch {
                    print("[Sync] Image upload failed for memory \(m.id): \(error)")
                }
            }
            
            let record = await MainActor.run {
                SupabaseMemory(
                    id: m.id.uuidString,
                    owner_id: userID,
                    title: m.title.isEmpty ? nil : m.title,
                    caption: m.caption.isEmpty ? nil : m.caption,
                    image_url: imageURL,
                    is_shared_with_partner: m.isSharedWithPartner,
                    is_new_for_partner: m.isNewForPartner,
                    shared_by: m.sharedBy.isEmpty ? nil : m.sharedBy,
                    date: iso.string(from: m.date)
                )
            }
            
            try await client.from("memories")
                .upsert(record, onConflict: "id")
                .execute()
        }
        
        // Create notification for shared memories
        if let partnerID = try? await getPartnerID() {
            let shared = memories.filter { $0.isSharedWithPartner && $0.isNewForPartner }
            if !shared.isEmpty {
                await notificationService?.createNotification(
                    type: .memoryShared,
                    recipientID: partnerID,
                    message: "A new memory was shared with you 📸"
                )
            }
        }
    }
    
    // MARK: - Push: Sync Exercise Logs
    /// Pushes all local ExerciseLog entries to Supabase (upsert by UUID).
    func syncExerciseLogs(modelContext: ModelContext) async throws {
        let userID = try await resolveUserID()
        
        let logs = try await MainActor.run {
            try modelContext.fetch(FetchDescriptor<ExerciseLog>())
        }
        
        guard !logs.isEmpty else { return }
        
        let records = logs.map { log in
            SupabaseExerciseLog(
                id: log.id.uuidString,
                owner_id: userID,
                exercise_name: log.exerciseName,
                duration_seconds: log.durationSeconds,
                week_number: log.weekNumber,
                date: iso.string(from: log.date)
            )
        }
        
        try await client.from("exercise_logs")
            .upsert(records, onConflict: "id")
            .execute()
    }
    
    // MARK: - Pull: Fetch All Partner Data
    /// Fetches all data from the connected partner and inserts into local SwiftData.
    func fetchPartnerData(modelContext: ModelContext) async throws {
        guard isOnline else { return }
        
        let partnerID = try await getPartnerID()
        guard let partnerID = partnerID else { return }
        
        do { try await fetchPartnerMoodLogs(partnerID: partnerID, modelContext: modelContext) } catch { print("[Sync] Partner mood logs failed: \(error)") }
        do { try await fetchPartnerLoveNotes(partnerID: partnerID, modelContext: modelContext) } catch { print("[Sync] Partner love notes failed: \(error)") }
        do { try await fetchPartnerMissions(partnerID: partnerID, modelContext: modelContext) } catch { print("[Sync] Partner missions failed: \(error)") }
        do { try await fetchPartnerMemories(partnerID: partnerID, modelContext: modelContext) } catch { print("[Sync] Partner memories failed: \(error)") }
    }
    
    // MARK: - Pull: Partner Mood Logs
    func fetchPartnerMoodLogs(partnerID: String, modelContext: ModelContext) async throws {
        let rows: [SupabaseMoodLog] = try await client.from("mood_logs")
            .select()
            .eq("owner_id", value: partnerID)
            .execute()
            .value
        
        await MainActor.run {
            for row in rows {
                guard let uuid = UUID(uuidString: row.id ?? "") else { continue }
                
                let descriptor = FetchDescriptor<MoodLog>(
                    predicate: #Predicate { $0.id == uuid }
                )
                let existing = try? modelContext.fetch(descriptor).first
                
                if existing == nil {
                    let log = MoodLog(
                        id: uuid,
                        date: iso.date(from: row.date) ?? Date(),
                        mood: row.mood,
                        energyLevel: row.energy_level,
                        journalNote: row.journal_note ?? ""
                    )
                    modelContext.insert(log)
                }
            }
            try? modelContext.save()
        }
    }
    
    // MARK: - Pull: Partner Love Notes
    func fetchPartnerLoveNotes(partnerID: String, modelContext: ModelContext) async throws {
        let rows: [SupabaseLoveNote] = try await client.from("love_notes")
            .select()
            .eq("owner_id", value: partnerID)
            .execute()
            .value
        
        await MainActor.run {
            for row in rows {
                guard let uuid = UUID(uuidString: row.id ?? "") else { continue }
                
                let descriptor = FetchDescriptor<LoveNote>(
                    predicate: #Predicate { $0.id == uuid }
                )
                let existing = try? modelContext.fetch(descriptor).first
                
                if existing == nil {
                    let note = LoveNote(
                        id: uuid,
                        date: iso.date(from: row.date) ?? Date(),
                        senderRole: row.sender_role,
                        noteText: row.note_text,
                        isRead: row.is_read
                    )
                    modelContext.insert(note)
                } else if !existing!.isRead && row.is_read {
                    existing!.isRead = true
                }
            }
            try? modelContext.save()
        }
    }
    
    // MARK: - Pull: Partner Missions
    func fetchPartnerMissions(partnerID: String, modelContext: ModelContext) async throws {
        let rows: [SupabaseMission] = try await client.from("missions")
            .select()
            .eq("owner_id", value: partnerID)
            .execute()
            .value
        
        await MainActor.run {
            for row in rows {
                guard let uuid = UUID(uuidString: row.id ?? "") else { continue }
                
                let descriptor = FetchDescriptor<PartnerMission>(
                    predicate: #Predicate { $0.id == uuid }
                )
                let existing = try? modelContext.fetch(descriptor).first
                
                if existing == nil {
                    let mission = PartnerMission(
                        id: uuid,
                        date: iso.date(from: row.date) ?? Date(),
                        missionTitle: row.mission_title,
                        missionDescription: row.mission_description ?? "",
                        isCompleted: row.is_completed,
                        weekNumber: row.week_number,
                        isNewForPartner: row.is_new_for_partner
                    )
                    modelContext.insert(mission)
                } else if !existing!.isCompleted && row.is_completed {
                    existing!.isCompleted = true
                }
            }
            try? modelContext.save()
        }
    }
    
    // MARK: - Pull: Partner Memories (with image download)
    func fetchPartnerMemories(partnerID: String, modelContext: ModelContext) async throws {
        let rows: [SupabaseMemory] = try await client.from("memories")
            .select()
            .eq("owner_id", value: partnerID)
            .eq("is_shared_with_partner", value: true)
            .execute()
            .value
        
        for row in rows {
            guard let uuid = UUID(uuidString: row.id ?? "") else { continue }
            
            // Check if already exists locally
            let alreadyExists = await MainActor.run {
                let descriptor = FetchDescriptor<Memory>(
                    predicate: #Predicate { $0.id == uuid }
                )
                return (try? modelContext.fetch(descriptor).first) != nil
            }
            
            if alreadyExists { continue }
            
            // Download image from Supabase Storage
            var imageData = Data()
            if let imageURL = row.image_url {
                do {
                    imageData = try await ImageStorageManager.downloadImage(url: imageURL)
                } catch {
                    print("[Sync] Failed to download image for memory \(uuid): \(error)")
                }
            }
            
            await MainActor.run {
                let memory = Memory(
                    id: uuid,
                    date: iso.date(from: row.date) ?? Date(),
                    title: row.title ?? "",
                    caption: row.caption ?? "",
                    imageData: imageData,
                    isSharedWithPartner: row.is_shared_with_partner,
                    isNewForPartner: row.is_new_for_partner,
                    sharedBy: row.shared_by ?? "",
                    imageURL: row.image_url
                )
                modelContext.insert(memory)
                try? modelContext.save()
            }
        }
    }
    
    // MARK: - Supabase Realtime Subscriptions
    /// Sets up Supabase Realtime channels for live partner data updates.
    /// Falls back to polling if Realtime fails.
    func setupSubscriptions(modelContext: ModelContext) async {
        guard authManager.isAuthenticated else { return }
        
        do {
            let partnerID = try await getPartnerID()
            guard let partnerID = partnerID else {
                print("[SyncManager] No connected partner — skipping realtime subscriptions.")
                return
            }
            
            // Try to set up Realtime channels
            await setupRealtimeChannels(partnerID: partnerID, modelContext: modelContext)
            
            // Also set up fallback polling (less frequent since we have Realtime)
            await MainActor.run {
                pollingTimer?.invalidate()
                pollingTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                    guard let self else { return }
                    Task {
                        try? await self.fetchPartnerData(modelContext: modelContext)
                    }
                }
            }
            
            print("[SyncManager] Realtime + polling active for partner \(partnerID)")
        } catch {
            print("[SyncManager] Subscription setup failed: \(error)")
            
            // Fallback to more frequent polling
            await MainActor.run {
                pollingTimer?.invalidate()
                pollingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
                    guard let self else { return }
                    Task {
                        try? await self.fetchPartnerData(modelContext: modelContext)
                    }
                }
            }
        }
    }
    
    /// Sets up Supabase Realtime channels for each relevant table.
    private func setupRealtimeChannels(partnerID: String, modelContext: ModelContext) async {
        // Subscribe to love_notes changes from partner
        let notesChannel = client.realtimeV2.channel("love-notes-\(partnerID)")
        let noteChanges = notesChannel.postgresChange(InsertAction.self, schema: "public", table: "love_notes", filter: "owner_id=eq.\(partnerID)")
        
        Task {
            for await _ in noteChanges {
                try? await self.fetchPartnerLoveNotes(partnerID: partnerID, modelContext: modelContext)
            }
        }
        
        // Subscribe to missions changes from partner
        let missionsChannel = client.realtimeV2.channel("missions-\(partnerID)")
        let missionChanges = missionsChannel.postgresChange(InsertAction.self, schema: "public", table: "missions", filter: "owner_id=eq.\(partnerID)")
        
        Task {
            for await _ in missionChanges {
                try? await self.fetchPartnerMissions(partnerID: partnerID, modelContext: modelContext)
            }
        }
        
        // Subscribe to memories changes from partner
        let memoriesChannel = client.realtimeV2.channel("memories-\(partnerID)")
        let memoryChanges = memoriesChannel.postgresChange(InsertAction.self, schema: "public", table: "memories", filter: "owner_id=eq.\(partnerID)")
        
        Task {
            for await _ in memoryChanges {
                try? await self.fetchPartnerMemories(partnerID: partnerID, modelContext: modelContext)
            }
        }
        
        // Subscribe to notifications for current user
        do {
            let myID = try await resolveUserID()
            let notifsChannel = client.realtimeV2.channel("notifications-\(myID)")
            let notifChanges = notifsChannel.postgresChange(InsertAction.self, schema: "public", table: "notifications", filter: "user_id=eq.\(myID)")
            
            Task {
                for await _ in notifChanges {
                    await self.notificationService?.fetchNotifications(userID: myID)
                }
            }
            
            await notifsChannel.subscribe()
        } catch {
            print("[SyncManager] Notifications channel setup failed: \(error)")
        }
        
        // Subscribe all channels
        await notesChannel.subscribe()
        await missionsChannel.subscribe()
        await memoriesChannel.subscribe()
        
        isRealtimeActive = true
    }
    
    /// Stops all Realtime channels and polling.
    func stopSubscriptions() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        
        Task {
            await client.realtimeV2.disconnect()
        }
        
        isRealtimeActive = false
    }
    
    // MARK: - Process Remote Notification
    /// Triggers a full sync when a remote notification is received.
    func processRemoteNotification(modelContext: ModelContext) async {
        await syncAll(modelContext: modelContext)
    }
}

// MARK: - Sync Errors
enum SyncError: LocalizedError {
    case notAuthenticated
    case userNotFound
    case syncFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not signed in."
        case .userNotFound: return "User record not found in Supabase."
        case .syncFailed(let detail): return "Sync failed: \(detail)"
        }
    }
}
