// WalkForge — App
// Agent-Session: point d'entrée iOS.

import BLECore
import DomainKit
import SwiftUI

@main
struct WalkForgeApp: App {
    /// En Sprint 2 : on utilise MockBLEManager partout (pas d'Apple Developer Program
    /// ni de PORTENTUM physique pour l'instant). La bascule vers BLEManager réel
    /// se fera via une compile-time flag en Sprint 3.
    @State private var viewModel: DashboardViewModel

    init() {
        let service = MockBLEManager()
        _viewModel = State(initialValue: DashboardViewModel(bleService: service))
    }

    var body: some Scene {
        WindowGroup {
            DashboardView(viewModel: viewModel)
                .preferredColorScheme(.dark)
        }
    }
}
