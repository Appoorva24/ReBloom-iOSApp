import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("onboardingDone") private var onboardingDone = false
    @Query private var profiles: [UserProfile]
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        Group {
            if !authManager.isAuthenticated {
                SignInView()
            } else if !onboardingDone {
                OnboardingView()
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
        }
    }
}
