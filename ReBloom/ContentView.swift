import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("onboardingDone") private var onboardingDone = false
    @Query private var profiles: [UserProfile]
    @Environment(AuthManager.self) private var authManager
    @Environment(SyncManager.self) private var syncManager
    @Environment(ConnectionManager.self) private var connectionManager
    @Environment(NotificationService.self) private var notificationService
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if !onboardingDone {
                OnboardingView()
            } else if !authManager.isAuthenticated {
                SignInView()
            } else if let profile = profiles.first {
                if profile.role == "husband" {
                    PartnerTabView()
                } else {
                    MotherTabView()
                }
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: onboardingDone)
        .animation(.easeInOut(duration: 0.4), value: authManager.isAuthenticated)
        .task {
            await authManager.checkAuthStatus()
            
            // After authentication, set up everything
            if authManager.isAuthenticated {
                // Fetch connection status and auto-accept pending connections
                do {
                    try await connectionManager.fetchConnectionStatus()
                    await connectionManager.checkAndAcceptPendingConnections()
                } catch {
                    print("[ContentView] Connection status fetch failed: \(error)")
                }
                
                // Sync all data
                await syncManager.syncAll(modelContext: modelContext)
                
                // Set up Realtime subscriptions
                await syncManager.setupSubscriptions(modelContext: modelContext)
                
                // Fetch notifications
                if let userID = try? await syncManager.resolveUserID() {
                    await notificationService.fetchNotifications(userID: userID)
                }
            }
        }
    }
}
