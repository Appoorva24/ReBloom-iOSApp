import SwiftUI
import SwiftData

@Observable
final class ProfileViewModel {
    // MARK: - Data
    var profiles: [UserProfile] = []
    var moodLogs: [MoodLog] = []
    var missions: [PartnerMission] = []
    var notes: [LoveNote] = []
    var exerciseLogs: [ExerciseLog] = []
    var memories: [Memory] = []

    // MARK: - State
    var showResetConfirm = false
    var isEditing = false
    var editName = ""
    var editPartnerName = ""
    var editBabyName = ""
    var editBabyBirthDate = Date()
    var isLoading = false
    var errorMessage: String?
    var profileImageURL: String?
    var isUploadingImage = false

    // MARK: - Computed
    var profile: UserProfile? { profiles.first }

    // MARK: - Load Data
    func load(modelContext: ModelContext) {
        profiles = (try? modelContext.fetch(FetchDescriptor<UserProfile>())) ?? []
        moodLogs = (try? modelContext.fetch(FetchDescriptor<MoodLog>())) ?? []
        missions = (try? modelContext.fetch(FetchDescriptor<PartnerMission>())) ?? []
        notes = (try? modelContext.fetch(FetchDescriptor<LoveNote>())) ?? []
        exerciseLogs = (try? modelContext.fetch(FetchDescriptor<ExerciseLog>())) ?? []
        memories = (try? modelContext.fetch(FetchDescriptor<Memory>())) ?? []
        profileImageURL = profile?.profileImageURL
    }

    // MARK: - Actions
    func loadProfileForEditing() {
        guard let p = profile else { return }
        editName = p.name
        editPartnerName = p.partnerName
        editBabyName = p.babyName
        editBabyBirthDate = p.babyBirthDate
    }

    func saveProfile(modelContext: ModelContext, connectionManager: ConnectionManager? = nil) {
        guard let p = profile else { return }
        p.name = editName
        p.partnerName = editPartnerName
        p.babyName = editBabyName
        p.babyBirthDate = editBabyBirthDate
        try? modelContext.save()
        
        // Also update the Supabase users record
        if let conn = connectionManager {
            Task {
                do {
                    try await conn.createUserRecord(
                        name: editName,
                        role: p.role,
                        babyName: editBabyName,
                        babyBirthDate: editBabyBirthDate,
                        code: p.inviteCode
                    )
                } catch {
                    print("[Profile] Supabase update failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Profile Image Upload
    func uploadProfileImage(_ imageData: Data, modelContext: ModelContext, connectionManager: ConnectionManager?) async {
        guard let userID = connectionManager?.supabaseUserID else {
            errorMessage = "Not connected to server."
            return
        }
        
        await MainActor.run { isUploadingImage = true; errorMessage = nil }
        
        do {
            let url = try await ImageStorageManager.uploadProfileImage(imageData: imageData, userID: userID)
            
            // Update Supabase users table
            try await connectionManager?.updateProfileImageURL(url)
            
            // Update local model
            await MainActor.run {
                profile?.profileImageURL = url
                profileImageURL = url
                try? modelContext.save()
                isUploadingImage = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to upload profile image."
                isUploadingImage = false
            }
            print("[Profile] Image upload failed: \(error)")
        }
    }
    
    // MARK: - Load Profile Image from Supabase
    func loadProfileImageFromSupabase(connectionManager: ConnectionManager?) async {
        guard let userID = connectionManager?.supabaseUserID else { return }
        
        do {
            let rows: [SupabaseUser] = try await SupabaseManager.client.from("users")
                .select()
                .eq("id", value: userID)
                .execute()
                .value
            
            if let url = rows.first?.profile_image_url {
                await MainActor.run {
                    profileImageURL = url
                    profile?.profileImageURL = url
                }
            }
        } catch {
            print("[Profile] Failed to load profile image URL: \(error)")
        }
    }

    func resetApp(modelContext: ModelContext, authManager: AuthManager? = nil, syncManager: SyncManager? = nil, completion: () -> Void) {
        for profile in profiles { modelContext.delete(profile) }
        for log in moodLogs { modelContext.delete(log) }
        for mission in missions { modelContext.delete(mission) }
        for note in notes { modelContext.delete(note) }
        for log in exerciseLogs { modelContext.delete(log) }
        for memory in memories { modelContext.delete(memory) }

        try? modelContext.save()
        
        // Stop Realtime subscriptions
        syncManager?.stopSubscriptions()
        
        authManager?.signOut()
        completion()
    }
}
