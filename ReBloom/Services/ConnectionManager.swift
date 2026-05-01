import Foundation

// MARK: - Connection Status
enum ConnectionStatus: String, Codable {
    case pending
    case accepted
    case rejected
}

@Observable
final class ConnectionManager {
    // MARK: - State
    var connectionStatus: ConnectionStatus?
    var partnerCloudID: String?
    var inviteCode: String?
    var isLoading = false
    var error: String?
    
    private let authManager: AuthManager
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    // MARK: - Generate Invite Code
    func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // No ambiguous chars (0/O, 1/I)
        let code = String((0..<6).map { _ in chars.randomElement()! })
        inviteCode = code
        return code
    }
    
    // MARK: - Stub Methods (to be implemented with Supabase)
    
    func createUserRecord(
        name: String,
        role: String,
        babyName: String,
        babyBirthDate: Date,
        code: String
    ) async throws {
        // TODO: Implement with Supabase — insert into 'users' table
    }
    
    func sendConnectionRequest(partnerInviteCode: String) async throws {
        // TODO: Implement with Supabase — query users by invite code, create connection row
        throw ConnectionError.connectionFailed
    }
    
    func acceptConnection(connectionRecordID: String) async throws {
        // TODO: Implement with Supabase — update connection status
    }
    
    func fetchConnectionStatus() async throws {
        // TODO: Implement with Supabase — query connections table
    }
    
    func fetchPartnerName() async throws -> String? {
        // TODO: Implement with Supabase — query partner profile
        return nil
    }
    
    func disconnect() async throws {
        // TODO: Implement with Supabase — delete connection row
        connectionStatus = nil
        partnerCloudID = nil
    }
}

// MARK: - Errors
enum ConnectionError: LocalizedError {
    case notAuthenticated
    case partnerNotFound
    case cannotConnectToSelf
    case connectionAlreadyExists
    case connectionFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Please sign in first."
        case .partnerNotFound: return "No user found with that invite code."
        case .cannotConnectToSelf: return "You can't connect with yourself."
        case .connectionAlreadyExists: return "A connection already exists."
        case .connectionFailed: return "Connection failed. Please try again."
        }
    }
}
