// WalkForge — App
// Agent-Profile: ViewModel du profil utilisateur + maintenance tapis.

import DomainKit
import Foundation
import Observation
import os

@MainActor
@Observable
public final class ProfileViewModel {
    public var weightKg: Double = 75
    public var heightCm: Double = 175
    public var ageYears: Int = 30
    public var preferredSpeedKmh: Double = 3.0
    public var dailyStepGoal: Int = 8000
    public var dailyDistanceGoalKm: Double = 5.0
    public var lastLubricationDate: Date?
    public var totalSessionCount: Int = 0
    public var nextMaintenanceAlertDate: Date?

    public private(set) var errorMessage: String?
    public private(set) var savedBannerVisible = false

    private let repository: any UserProfileRepository
    private let notificationService: any NotificationServiceProtocol
    private let logger = Logger(subsystem: "com.samuel.walkforge", category: "Profile")

    public init(
        repository: any UserProfileRepository,
        notificationService: any NotificationServiceProtocol,
    ) {
        self.repository = repository
        self.notificationService = notificationService
    }

    public func load() async {
        do {
            guard let dto = try await repository.load() else { return }
            apply(dto)
        } catch {
            errorMessage = "Chargement profil échoué"
            logger.error("Profile load failed: \(String(describing: error), privacy: .public)")
        }
    }

    public func save() async {
        let dto = currentDTO()
        do {
            try await repository.save(dto)
            savedBannerVisible = true
            try? await Task.sleep(for: .seconds(2))
            savedBannerVisible = false
        } catch {
            errorMessage = "Sauvegarde profil échouée"
            logger.error("Profile save failed: \(String(describing: error), privacy: .public)")
        }
    }

    public func markLubricatedNow() async {
        lastLubricationDate = Date()
        // Planifie l'alerte 21 jours plus tard (MaintenanceAlertUseCase).
        let useCase = MaintenanceAlertUseCase(notificationService: notificationService)
        do {
            let alert = try await useCase.execute(lastLubricationDate: lastLubricationDate)
            nextMaintenanceAlertDate = alert.dueDate
        } catch {
            logger.error("Schedule lubrication failed: \(String(describing: error), privacy: .public)")
        }
        await save()
    }

    // MARK: - Private

    private func apply(_ dto: UserProfileDTO) {
        weightKg = dto.weightKg
        heightCm = dto.heightCm
        ageYears = dto.ageYears
        preferredSpeedKmh = dto.preferredSpeedKmh
        dailyStepGoal = dto.dailyStepGoal
        dailyDistanceGoalKm = dto.dailyDistanceGoalKm
        lastLubricationDate = dto.lastLubricationDate
        totalSessionCount = dto.totalSessionCount
        nextMaintenanceAlertDate = dto.nextMaintenanceAlertDate
    }

    private func currentDTO() -> UserProfileDTO {
        UserProfileDTO(
            weightKg: weightKg,
            heightCm: heightCm,
            ageYears: ageYears,
            preferredSpeedKmh: preferredSpeedKmh,
            dailyStepGoal: dailyStepGoal,
            dailyDistanceGoalKm: dailyDistanceGoalKm,
            lastLubricationDate: lastLubricationDate,
            totalSessionCount: totalSessionCount,
            nextMaintenanceAlertDate: nextMaintenanceAlertDate,
        )
    }
}
