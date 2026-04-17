// WalkForge — DataKit
// Agent-Data: modèle SwiftData du profil utilisateur (singleton en pratique).

import DomainKit
import Foundation
import SwiftData

@Model
public final class UserProfileModel {
    @Attribute(.unique)
    public var id: UUID
    public var weightKg: Double
    public var heightCm: Double
    public var ageYears: Int
    public var preferredSpeedKmh: Double
    public var dailyStepGoal: Int
    public var dailyDistanceGoalKm: Double
    public var lastLubricationDate: Date?
    public var totalSessionCount: Int
    public var nextMaintenanceAlertDate: Date?

    public init(
        id: UUID = UUID(),
        weightKg: Double,
        heightCm: Double,
        ageYears: Int,
        preferredSpeedKmh: Double = 3.0,
        dailyStepGoal: Int = 8000,
        dailyDistanceGoalKm: Double = 5.0,
        lastLubricationDate: Date? = nil,
        totalSessionCount: Int = 0,
        nextMaintenanceAlertDate: Date? = nil,
    ) {
        self.id = id
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.ageYears = ageYears
        self.preferredSpeedKmh = preferredSpeedKmh
        self.dailyStepGoal = dailyStepGoal
        self.dailyDistanceGoalKm = dailyDistanceGoalKm
        self.lastLubricationDate = lastLubricationDate
        self.totalSessionCount = totalSessionCount
        self.nextMaintenanceAlertDate = nextMaintenanceAlertDate
    }

    func toDTO() -> UserProfileDTO {
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

    func update(from dto: UserProfileDTO) {
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
}
