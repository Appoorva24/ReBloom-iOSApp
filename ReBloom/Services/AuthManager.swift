import SwiftUI
import AuthenticationServices

@Observable
final class AuthManager {
    // MARK: - State
    var isAuthenticated = false
    var currentUserID: String?
    var appleUserIdentifier: String?
    var userName: String?
    var authError: String?
    
    private let keychainAppleIDKey = "rebloom_apple_user_id"
    
    // MARK: - Check Auth on Launch
    func checkAuthStatus() async {
        // Check if we have stored Apple ID
        if let storedAppleID = KeychainHelper.loadString(forKey: keychainAppleIDKey) {
            appleUserIdentifier = storedAppleID
            
            // Verify the credential is still valid
            let provider = ASAuthorizationAppleIDProvider()
            do {
                let state = try await provider.credentialState(forUserID: storedAppleID)
                switch state {
                case .authorized:
                    isAuthenticated = true
                    currentUserID = storedAppleID
                case .revoked, .notFound:
                    signOut()
                default:
                    signOut()
                }
            } catch {
                // Offline — trust stored credential
                isAuthenticated = true
                currentUserID = storedAppleID
            }
        }
    }
    
    // MARK: - Sign In with Apple
    func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                authError = "Invalid credential type"
                return
            }
            
            let userID = credential.user
            appleUserIdentifier = userID
            currentUserID = userID
            KeychainHelper.saveString(userID, forKey: keychainAppleIDKey)
            
            // Extract name if available (only on first sign-in)
            if let fullName = credential.fullName {
                let name = [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                if !name.isEmpty {
                    userName = name
                }
            }
            
            isAuthenticated = true
            
        case .failure(let error):
            authError = error.localizedDescription
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        isAuthenticated = false
        currentUserID = nil
        appleUserIdentifier = nil
        userName = nil
        KeychainHelper.delete(key: keychainAppleIDKey)
    }
}
