// WalkForge — DataKit
// Agent-Data: factory de ModelContainer pour l'app et les tests/preview.
//
// Note : `@preconcurrency import SwiftData` car `Schema` n'est pas Sendable
// sur les SDKs antérieurs à macOS 26 / iOS 19 (CI Xcode 16.4 → SDK 15.5).
// `@preconcurrency` passe ces avertissements en warnings plutôt qu'en erreurs.

import Foundation
@preconcurrency import SwiftData

/// Fabrique centralisée de `ModelContainer` WalkForge.
///
/// - `production()` → persistance disque (par défaut de SwiftData).
/// - `inMemory()`   → stockage mémoire volatil, utilisé en tests et previews.
public enum ModelContainerFactory {
    /// Liste des types `@Model` embarqués dans WalkForge.
    public static let schema: Schema = .init([
        WorkoutSessionModel.self,
        UserProfileModel.self,
        SessionProgramModel.self,
        ProgramStepModel.self,
    ])

    /// Container de production (disque).
    public static func production() throws -> ModelContainer {
        try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: false),
        )
    }

    /// Container en mémoire uniquement, pour tests et previews SwiftUI.
    public static func inMemory() throws -> ModelContainer {
        try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true),
        )
    }
}
