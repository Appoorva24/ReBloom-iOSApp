import SwiftUI
import Supabase

@Observable
final class AuthManager {
    // MARK: - State
    var isAuthenticated = false
    var currentSupabaseUserID: String?
    var authError: String?
    var isCheckingAuth = false
    var isLoading = false
    
    private let client = SupabaseManager.client
    
    // MARK: - Check Auth on Launch
    func checkAuthStatus() async {
        await MainActor.run { isCheckingAuth = true }
        
        do {
            let session = try await client.auth.session
            await MainActor.run {
                self.currentSupabaseUserID = session.user.id.uuidString
                self.isAuthenticated = true
                self.isCheckingAuth = false
            }
        } catch {
            await MainActor.run {
                self.isCheckingAuth = false
                self.isAuthenticated = false
            }
            print("[Auth] No active session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Email Sign In
    func signIn(email: String, password: String) async {
        await MainActor.run { 
            self.isLoading = true
            self.authError = nil
        }
        
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            await MainActor.run {
                self.currentSupabaseUserID = session.user.id.uuidString
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.authError = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Email Sign Up
    func signUp(email: String, password: String) async {
        await MainActor.run { 
            self.isLoading = true
            self.authError = nil
        }
        
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )
            
            await MainActor.run {
                self.currentSupabaseUserID = response.user.id.uuidString
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.authError = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        Task {
            do {
                try await client.auth.signOut()
            } catch {
                print("[Auth] Supabase sign-out error: \(error.localizedDescription)")
            }
        }
        
        isAuthenticated = false
        currentSupabaseUserID = nil
        authError = nil
    }
}
