// WalkForge — App
// Agent-Session: point d'entrée iOS.

import DomainKit
import SwiftUI

@main
struct WalkForgeApp: App {
    @State private var services: AppServices
    @State private var dashboardVM: DashboardViewModel
    @State private var historyVM: HistoryViewModel
    @State private var programsVM: ProgramsViewModel
    @State private var profileVM: ProfileViewModel

    init() {
        let services = AppServices()
        _services = State(initialValue: services)
        _dashboardVM = State(initialValue: DashboardViewModel(
            bleService: services.bleService,
            workoutRepository: services.workoutRepository,
            notificationService: services.notificationService,
            healthKitService: services.healthKitService,
        ))
        _historyVM = State(initialValue: HistoryViewModel(
            repository: services.workoutRepository,
        ))
        _programsVM = State(initialValue: ProgramsViewModel(
            repository: services.programRepository,
        ))
        _profileVM = State(initialValue: ProfileViewModel(
            repository: services.userProfileRepository,
            notificationService: services.notificationService,
        ))
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(
                dashboardVM: dashboardVM,
                historyVM: historyVM,
                programsVM: programsVM,
                profileVM: profileVM,
            )
            .preferredColorScheme(.dark)
            .task {
                _ = await services.notificationService.requestAuthorization()
                _ = try? await services.healthKitService.requestAuthorization()
            }
        }
    }
}
