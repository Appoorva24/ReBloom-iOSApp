import SwiftUI

struct PartnerTabView: View {
    var body: some View {
        TabView {
            PartnerHomeView()
                .tabItem {
                    Label("Us", systemImage: "heart.fill")
                }

            PartnerMemoriesView()
                .tabItem {
                    Label("Memories", systemImage: "photo.on.rectangle.angled")
                }

            LearnView()
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }
        }
        .tint(Color.partnerPrimary)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white

            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.normal.iconColor = UIColor(Color.navIconInactive)
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.navIconInactive)]
            itemAppearance.selected.iconColor = UIColor(Color.partnerPrimary)
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.partnerPrimary)]

            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
