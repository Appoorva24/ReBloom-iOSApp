import SwiftUI
import SwiftData

@Observable
final class OnboardingViewModel {
    // MARK: - State
    var motherName = ""
    var partnerName = ""
    var babyName = ""
    var babyBirthDate = Date()
    var selectedRole = "wife"
    var partnerInviteCode = ""
    var showConnectionStep = false
    var connectionError: String?
    var isConnecting = false

    // MARK: - Actions
    func saveProfile(
        modelContext: ModelContext,
        authManager: AuthManager,
        connectionManager: ConnectionManager,
        completion: @escaping () -> Void
    ) {
        let code = connectionManager.generateInviteCode()
        
        let profile = UserProfile(
            name: motherName,
            role: selectedRole,
            babyName: babyName,
            babyBirthDate: babyBirthDate,
            partnerName: partnerName,
            onboardingComplete: true,
            firstLaunchDate: Date(),
            inviteCode: code
        )
        modelContext.insert(profile)
        try? modelContext.save()

        // TODO: Upload user to Supabase
        Task {
            do {
                try await connectionManager.createUserRecord(
                    name: motherName,
                    role: selectedRole,
                    babyName: babyName,
                    babyBirthDate: babyBirthDate,
                    code: code
                )
            } catch {
                // Offline — will sync later
            }
            
            await MainActor.run {
                completion()
            }
        }
    }
    
    // MARK: - Connect with Partner
    func connectWithPartner(connectionManager: ConnectionManager) async {
        guard !partnerInviteCode.isEmpty else {
            connectionError = "Please enter an invite code."
            return
        }
        
        isConnecting = true
        connectionError = nil
        
        do {
            try await connectionManager.sendConnectionRequest(partnerInviteCode: partnerInviteCode)
            await MainActor.run {
                isConnecting = false
            }
        } catch {
            await MainActor.run {
                connectionError = error.localizedDescription
                isConnecting = false
            }
        }
    }
}
