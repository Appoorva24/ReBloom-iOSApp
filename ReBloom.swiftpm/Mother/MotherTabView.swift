import SwiftUI

struct MotherTabView: View {
    var body: some View {
        TabView {
            HomeDashboardView()
                .tabItem {
                    Label("Us", systemImage: "heart.fill")
                }

            MemoryJarView()
                .tabItem {
                    Label("Memories", systemImage: "photo.on.rectangle.angled")
                }

            HealView()
                .tabItem {
                    Label("Heal", systemImage: "figure.mind.and.body")
                }
        }
        .tint(Color.motherPrimary)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            appearance.shadowColor = UIColor(Color.motherPrimary.opacity(0.2))

            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.normal.iconColor = UIColor(Color.navIconInactive)
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.navIconInactive)]
            itemAppearance.selected.iconColor = UIColor(Color.motherPrimary)
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.motherPrimary)]

            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
