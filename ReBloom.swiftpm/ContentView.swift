import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("onboardingDone") private var onboardingDone = false
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if !onboardingDone {
                OnboardingView()
            } else if let profile = profiles.first {
                if profile.role == "partner" {
                    PartnerTabView()
                } else {
                    MotherTabView()
                }
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: onboardingDone)
    }
}

