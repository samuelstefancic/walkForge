// WalkForge — HealthKitBridge
// Agent-Infra: implémentation HealthKit du HealthKitServiceProtocol.
//
// `@preconcurrency import HealthKit` pour la même raison que UserNotifications
// (HKHealthStore et co. ne sont pas Sendable sur les SDKs antérieurs à
// macOS 26 / iOS 19). Les appels sont confinés à l'actor.

import DomainKit
import Foundation
import os
#if canImport(HealthKit)
@preconcurrency import HealthKit
#endif

/// Service HealthKit (actor isolé).
///
/// Périmètre Sprint 4 :
/// - Permission granulaire (read profile + heart rate, write workouts/distance/energy)
/// - Lecture profil utilisateur (poids, taille, âge, sexe)
/// - Export d'une session terminée comme `HKWorkout`
///
/// **Note ADP** : la réelle exécution requiert l'entitlement HealthKit
/// (com.apple.developer.healthkit) qui suppose un compte Apple Developer
/// Program. Sur Simulator/CI, le code compile mais HKHealthStore.isHealthDataAvailable
/// renvoie `false` et toutes les opérations échouent silencieusement.
public actor HealthKitService: HealthKitServiceProtocol {
    private let logger = Logger(subsystem: "com.samuel.walkforge", category: "HealthKit")

    #if canImport(HealthKit)
    private let store = HKHealthStore()

    private nonisolated static let readTypes: Set<HKObjectType> = {
        var types: Set<HKObjectType> = []
        if let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(weight)
        }
        if let height = HKObjectType.quantityType(forIdentifier: .height) {
            types.insert(height)
        }
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(hr)
        }
        if let dob = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) {
            types.insert(dob)
        }
        if let sex = HKObjectType.characteristicType(forIdentifier: .biologicalSex) {
            types.insert(sex)
        }
        return types
    }()

    private nonisolated static let writeTypes: Set<HKSampleType> = {
        var types: Set<HKSampleType> = [HKWorkoutType.workoutType()]
        if let dist = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(dist)
        }
        if let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(energy)
        }
        return types
    }()
    #endif

    public init() {}

    public var isAvailable: Bool {
        get async {
            #if canImport(HealthKit)
            return HKHealthStore.isHealthDataAvailable()
            #else
            return false
            #endif
        }
    }

    public func authorizationStatus() async -> HealthKitAuthorization {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { return .sharingDenied }
        // L'authorizationStatus pour les types d'écriture donne la meilleure
        // indication globale (Apple ne permet pas de lire le statut "read").
        let workoutStatus = store.authorizationStatus(for: HKWorkoutType.workoutType())
        return Self.mapStatus(workoutStatus)
        #else
        return .notDetermined
        #endif
    }

    public func requestAuthorization() async throws -> HealthKitAuthorization {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { return .sharingDenied }
        try await store.requestAuthorization(toShare: Self.writeTypes, read: Self.readTypes)
        return await authorizationStatus()
        #else
        return .notDetermined
        #endif
    }

    public func readProfile() async throws -> HealthKitProfileSnapshot {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else {
            return HealthKitProfileSnapshot()
        }

        let weightKg = try await readLatestQuantity(.bodyMass, unit: .gramUnit(with: .kilo))
        let heightCm = try await readLatestQuantity(.height, unit: .meterUnit(with: .centi))

        var ageYears: Int?
        if let birthDate = try? store.dateOfBirthComponents().date {
            let now = Date()
            ageYears = Calendar.current.dateComponents([.year], from: birthDate, to: now).year
        }

        var sex: HealthKitBiologicalSex?
        if let biological = try? store.biologicalSex() {
            sex = Self.mapSex(biological.biologicalSex)
        }

        return HealthKitProfileSnapshot(
            weightKg: weightKg,
            heightCm: heightCm,
            ageYears: ageYears,
            biologicalSex: sex,
        )
        #else
        return HealthKitProfileSnapshot()
        #endif
    }

    @discardableResult
    public func exportWorkout(_ session: WorkoutSessionDTO) async throws -> Bool {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .walking
        configuration.locationType = .indoor

        let builder = HKWorkoutBuilder(
            healthStore: store,
            configuration: configuration,
            device: .local(),
        )

        let endDate = session.endDate ?? session.startDate.addingTimeInterval(
            Double(session.durationSeconds),
        )
        try await builder.beginCollection(at: session.startDate)

        // Distance
        if session.distanceKm > 0 {
            if let distType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
                let qty = HKQuantity(
                    unit: .meterUnit(with: .kilo),
                    doubleValue: session.distanceKm,
                )
                let sample = HKQuantitySample(
                    type: distType,
                    quantity: qty,
                    start: session.startDate,
                    end: endDate,
                )
                try await builder.addSamples([sample])
            }
        }

        // Calories
        if session.estimatedCalories > 0 {
            if let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
                let qty = HKQuantity(unit: .kilocalorie(), doubleValue: session.estimatedCalories)
                let sample = HKQuantitySample(
                    type: energyType,
                    quantity: qty,
                    start: session.startDate,
                    end: endDate,
                )
                try await builder.addSamples([sample])
            }
        }

        try await builder.endCollection(at: endDate)
        _ = try await builder.finishWorkout()
        logger.info("Workout exporté HK : id=\(session.id, privacy: .public)")
        return true
        #else
        return false
        #endif
    }

    // MARK: - Private

    #if canImport(HealthKit)
    private func readLatestQuantity(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
    ) async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return nil }
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1,
        )
        let samples = try await descriptor.result(for: store)
        return samples.first?.quantity.doubleValue(for: unit)
    }

    private static func mapStatus(_ status: HKAuthorizationStatus) -> HealthKitAuthorization {
        switch status {
        case .notDetermined: .notDetermined
        case .sharingDenied: .sharingDenied
        case .sharingAuthorized: .sharingAuthorized
        @unknown default: .notDetermined
        }
    }

    private static func mapSex(_ sex: HKBiologicalSex) -> HealthKitBiologicalSex {
        switch sex {
        case .female: .female
        case .male: .male
        case .other: .other
        case .notSet: .notSet
        @unknown default: .notSet
        }
    }
    #endif
}
