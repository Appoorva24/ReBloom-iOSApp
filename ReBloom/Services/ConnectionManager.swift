import Foundation
import Supabase

// MARK: - Connection Status
enum ConnectionStatus: String, Codable {
    case pending
    case accepted
    case rejected
}

// MARK: - Supabase DTOs (Data Transfer Objects)
/// Codable structs that map directly to Supabase table columns.

struct SupabaseUser: Codable {
    let id: String?
    let auth_id: String?
    let name: String
    let role: String
    let baby_name: String?
    let baby_birth_date: String?
    let invite_code: String?
    let profile_image_url: String?
    let created_at: String?
}

struct SupabaseConnection: Codable, Identifiable {
    let id: String?
    let user1_id: String
    let user2_id: String
    let status: String
    let created_at: String?
}

@Observable
final class ConnectionManager {
    // MARK: - State
    var connectionStatus: ConnectionStatus?
    var partnerCloudID: String?
    var inviteCode: String?
    var isLoading = false
    var error: String?
    
    /// The Supabase UUID for the current user's row in the `users` table.
    var supabaseUserID: String?
    
    private let authManager: AuthManager
    private let client = SupabaseManager.client
    
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
    
    // MARK: - Create User Record
    /// Inserts the user into the Supabase `users` table after onboarding.
    func createUserRecord(
        name: String,
        role: String,
        babyName: String,
        babyBirthDate: Date,
        code: String
    ) async throws {
        guard let authID = authManager.currentSupabaseUserID else {
            throw ConnectionError.notAuthenticated
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        
        let record = SupabaseUser(
            id: nil,
            auth_id: authID,
            name: name,
            role: role,
            baby_name: babyName.isEmpty ? nil : babyName,
            baby_birth_date: formatter.string(from: babyBirthDate),
            invite_code: code,
            profile_image_url: nil,
            created_at: nil
        )
        
        // Upsert so re-onboarding doesn't fail on unique constraint
        try await client.from("users")
            .upsert(record, onConflict: "auth_id")
            .execute()
        
        let rows: [SupabaseUser] = try await client.from("users")
            .select()
            .eq("auth_id", value: authID)
            .execute()
            .value
        
        await MainActor.run {
            self.supabaseUserID = rows.first?.id
            self.inviteCode = code
        }
    }
    
    // MARK: - Send Connection Request
    /// Finds a partner by their invite code and creates a pending connection.
    /// Includes retry logic (1 retry with 2s delay).
    func sendConnectionRequest(partnerInviteCode: String) async throws {
        guard let authID = authManager.currentSupabaseUserID else {
            throw ConnectionError.notAuthenticated
        }
        
        // Ensure we have our own Supabase user ID
        if supabaseUserID == nil {
            try await resolveOwnUserID(authID: authID)
        }
        guard let myID = supabaseUserID else {
            throw ConnectionError.notAuthenticated
        }
        
        // Find partner by invite code
        let partners: [SupabaseUser] = try await client.from("users")
            .select()
            .eq("invite_code", value: partnerInviteCode.uppercased())
            .execute()
            .value
        
        guard let partner = partners.first, let partnerID = partner.id else {
            throw ConnectionError.partnerNotFound
        }
        
        // Prevent self-connection
        if partnerID == myID {
            throw ConnectionError.cannotConnectToSelf
        }
        
        // Check for existing connection for BOTH users
        let myExisting: [SupabaseConnection] = try await client.from("connections")
            .select()
            .or("user1_id.eq.\(myID),user2_id.eq.\(myID)")
            .execute()
            .value
        
        if !myExisting.isEmpty {
            throw ConnectionError.connectionAlreadyExists
        }
        
        let partnerExisting: [SupabaseConnection] = try await client.from("connections")
            .select()
            .or("user1_id.eq.\(partnerID),user2_id.eq.\(partnerID)")
            .execute()
            .value
        
        if !partnerExisting.isEmpty {
            throw ConnectionError.partnerAlreadyConnected
        }
        
        // Create connection row — set as accepted immediately (both parties in same app)
        let connection = SupabaseConnection(
            id: nil,
            user1_id: myID,
            user2_id: partnerID,
            status: ConnectionStatus.accepted.rawValue,
            created_at: nil
        )
        
        do {
            try await client.from("connections")
                .insert(connection)
                .execute()
        } catch {
            // Retry once after 2 seconds
            try await Task.sleep(nanoseconds: 2_000_000_000)
            try await client.from("connections")
                .insert(connection)
                .execute()
        }
        
        await MainActor.run {
            self.connectionStatus = .accepted
            self.partnerCloudID = partnerID
        }
    }
    
    // MARK: - Check and Accept Pending Connections
    /// Checks for pending connections where the current user is user2 and auto-accepts them.
    func checkAndAcceptPendingConnections() async {
        guard let myID = supabaseUserID else { return }
        
        do {
            let pending: [SupabaseConnection] = try await client.from("connections")
                .select()
                .eq("user2_id", value: myID)
                .eq("status", value: ConnectionStatus.pending.rawValue)
                .execute()
                .value
            
            for conn in pending {
                guard let connID = conn.id else { continue }
                try await acceptConnection(connectionRecordID: connID)
                
                await MainActor.run {
                    self.partnerCloudID = conn.user1_id
                }
            }
        } catch {
            print("[Connection] Check pending failed: \(error)")
        }
    }
    
    // MARK: - Accept Connection
    /// Updates an existing connection row to accepted status.
    func acceptConnection(connectionRecordID: String) async throws {
        try await client.from("connections")
            .update(["status": ConnectionStatus.accepted.rawValue])
            .eq("id", value: connectionRecordID)
            .execute()
        
        await MainActor.run {
            self.connectionStatus = .accepted
        }
    }
    
    // MARK: - Fetch Connection Status
    /// Queries the connections table for the current user's connection.
    func fetchConnectionStatus() async throws {
        guard let authID = authManager.currentSupabaseUserID else { return }
        
        if supabaseUserID == nil {
            try await resolveOwnUserID(authID: authID)
        }
        guard let myID = supabaseUserID else { return }
        
        // Also fetch the user's own invite code from Supabase
        let myRows: [SupabaseUser] = try await client.from("users")
            .select()
            .eq("id", value: myID)
            .execute()
            .value
        
        if let myUser = myRows.first, let code = myUser.invite_code {
            await MainActor.run {
                self.inviteCode = code
            }
        }
        
        let connections: [SupabaseConnection] = try await client.from("connections")
            .select()
            .or("user1_id.eq.\(myID),user2_id.eq.\(myID)")
            .execute()
            .value
        
        guard let conn = connections.first else {
            await MainActor.run {
                self.connectionStatus = nil
                self.partnerCloudID = nil
            }
            return
        }
        
        let partnerID = (conn.user1_id == myID) ? conn.user2_id : conn.user1_id
        
        await MainActor.run {
            self.connectionStatus = ConnectionStatus(rawValue: conn.status)
            self.partnerCloudID = partnerID
        }
    }
    
    // MARK: - Fetch Partner Name
    /// Queries the partner's user profile from Supabase.
    func fetchPartnerName() async throws -> String? {
        guard let partnerID = partnerCloudID else { return nil }
        
        let partners: [SupabaseUser] = try await client.from("users")
            .select()
            .eq("id", value: partnerID)
            .execute()
            .value
        
        return partners.first?.name
    }
    
    // MARK: - Update Profile Image URL
    /// Updates the profile_image_url in the users table.
    func updateProfileImageURL(_ url: String) async throws {
        guard let myID = supabaseUserID else { return }
        
        try await client.from("users")
            .update(["profile_image_url": url])
            .eq("id", value: myID)
            .execute()
    }
    
    // MARK: - Disconnect
    /// Deletes the connection row from Supabase.
    func disconnect() async throws {
        guard let myID = supabaseUserID else {
            connectionStatus = nil
            partnerCloudID = nil
            return
        }
        
        try await client.from("connections")
            .delete()
            .or("user1_id.eq.\(myID),user2_id.eq.\(myID)")
            .execute()
        
        await MainActor.run {
            self.connectionStatus = nil
            self.partnerCloudID = nil
        }
    }
    
    // MARK: - Helpers
    /// Resolves the current user's Supabase UUID from their Apple ID.
    private func resolveOwnUserID(authID: String) async throws {
        let rows: [SupabaseUser] = try await client.from("users")
            .select()
            .eq("auth_id", value: authID)
            .execute()
            .value
        
        await MainActor.run {
            self.supabaseUserID = rows.first?.id
        }
    }
}

// MARK: - Errors
enum ConnectionError: LocalizedError {
    case notAuthenticated
    case partnerNotFound
    case cannotConnectToSelf
    case connectionAlreadyExists
    case partnerAlreadyConnected
    case connectionFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Please sign in first."
        case .partnerNotFound: return "No user found with that invite code."
        case .cannotConnectToSelf: return "You can't connect with yourself."
        case .connectionAlreadyExists: return "A connection already exists."
        case .partnerAlreadyConnected: return "That partner is already connected to someone."
        case .connectionFailed: return "Connection failed. Please try again."
        }
    }
}
