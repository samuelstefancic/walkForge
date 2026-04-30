// WalkForge — App
// Agent-Session: container de dépendances injectées par @main.
//
// Principe : instancier tout l'arbre de services au lancement et passer un
// seul `AppServices` aux ViewModels. Évite un DI framework et reste explicite.

import BLECore
import DataKit
import DomainKit
import HealthKitBridge
import NotificationKit
import os
import SwiftData

/// Container de dépendances injectées dans les ViewModels.
///
/// Marqué `@MainActor` car la construction de `ModelContainer` se fait via
/// l'app main thread, et les ViewModels qui le consomment sont @MainActor.
@MainActor
public final class AppServices {
    public let modelContainer: ModelContainer
    public let bleService: any BLETreadmillServiceProtocol
    public let notificationService: any NotificationServiceProtocol
    public let healthKitService: any HealthKitServiceProtocol
    public let workoutRepository: any WorkoutSessionRepository
    public let userProfileRepository: any UserProfileRepository
    public let programRepository: any SessionProgramRepository

    private static let logger = Logger(subsystem: "com.samuel.walkforge", category: "AppServices")

    public init() {
        // 1. Persistence
        let container: ModelContainer
        do {
            container = try ModelContainerFactory.production()
        } catch {
            let reason = String(describing: error)
            Self.logger.error("Container production KO, fallback in-memory: \(reason, privacy: .public)")
            container = (try? ModelContainerFactory.inMemory())
                ?? {
                    // Ne devrait jamais arriver — le fallback in-memory est quasi-toujours OK.
                    // Préférable à un crash silencieux : on remonte clairement.
                    fatalError("Unable to create any ModelContainer")
                }()
        }
        modelContainer = container

        // 2. BLE (Sprint 3 : toujours mock, vrai BLE au Sprint 5 avec ADP)
        bleService = MockBLEManager()

        // 3. Notifications
        notificationService = UserNotificationsService()

        // 4. HealthKit (vraie impl ; sans entitlement actif elle no-op proprement)
        healthKitService = HealthKitService()

        // 5. Repositories SwiftData
        workoutRepository = SwiftDataWorkoutSessionRepository(modelContainer: container)
        userProfileRepository = SwiftDataUserProfileRepository(modelContainer: container)
        programRepository = SwiftDataSessionProgramRepository(modelContainer: container)
    }

    /// Container en-mémoire pour previews/tests.
    public static func preview() -> AppServices {
        AppServices(inMemory: true)
    }

    private init(inMemory _: Bool) {
        let container = (try? ModelContainerFactory.inMemory())
            ?? {
                fatalError("In-memory ModelContainer failed")
            }()
        modelContainer = container
        bleService = MockBLEManager()
        notificationService = UserNotificationsService()
        healthKitService = InMemoryHealthKitService()
        workoutRepository = SwiftDataWorkoutSessionRepository(modelContainer: container)
        userProfileRepository = SwiftDataUserProfileRepository(modelContainer: container)
        programRepository = SwiftDataSessionProgramRepository(modelContainer: container)
    }
}
