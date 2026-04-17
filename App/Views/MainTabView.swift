// WalkForge — App
// Agent-Session: navigation racine en 3 onglets.

import DesignSystem
import SwiftUI

struct MainTabView: View {
    @Bindable var dashboardVM: DashboardViewModel
    @Bindable var programsVM: ProgramsViewModel
    @Bindable var profileVM: ProfileViewModel

    var body: some View {
        TabView {
            DashboardView(viewModel: dashboardVM)
                .tabItem {
                    Label("Session", systemImage: "figure.walk.motion")
                }

            ProgramsView(viewModel: programsVM)
                .tabItem {
                    Label("Programmes", systemImage: "list.bullet.rectangle")
                }

            ProfileView(viewModel: profileVM)
                .tabItem {
                    Label("Profil", systemImage: "person.circle.fill")
                }
        }
        .tint(WFColor.accentPrimary)
    }
}
