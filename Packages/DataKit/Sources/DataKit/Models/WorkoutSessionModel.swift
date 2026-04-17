// WalkForge — DataKit
// Agent-Data: modèle SwiftData d'une session persistée.
// Converti vers/depuis `DomainKit.WorkoutSessionDTO` dans la couche repository
// pour éviter de coupler le domaine au framework SwiftData.

import DomainKit
import Foundation
import SwiftData

@Model
public final class WorkoutSessionModel {
    @Attribute(.unique)
    public var id: UUID
    public var startDate: Date
    public var endDate: Date?
    public var durationSeconds: Int
    public var distanceKm: Double
    public var estimatedCalories: Double
    public var averageSpeedKmh: Double
    public var maxSpeedKmh: Double
    public var inclineLevel: Int
    public var isExportedToHealthKit: Bool

    public init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date? = nil,
        durationSeconds: Int,
        distanceKm: Double,
        estimatedCalories: Double,
        averageSpeedKmh: Double,
        maxSpeedKmh: Double,
        inclineLevel: Int,
        isExportedToHealthKit: Bool = false,
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.durationSeconds = durationSeconds
        self.distanceKm = distanceKm
        self.estimatedCalories = estimatedCalories
        self.averageSpeedKmh = averageSpeedKmh
        self.maxSpeedKmh = maxSpeedKmh
        self.inclineLevel = inclineLevel
        self.isExportedToHealthKit = isExportedToHealthKit
    }

    convenience init(from dto: WorkoutSessionDTO) {
        self.init(
            id: dto.id,
            startDate: dto.startDate,
            endDate: dto.endDate,
            durationSeconds: dto.durationSeconds,
            distanceKm: dto.distanceKm,
            estimatedCalories: dto.estimatedCalories,
            averageSpeedKmh: dto.averageSpeedKmh,
            maxSpeedKmh: dto.maxSpeedKmh,
            inclineLevel: dto.inclineLevel,
            isExportedToHealthKit: dto.isExportedToHealthKit,
        )
    }

    func toDTO() -> WorkoutSessionDTO {
        WorkoutSessionDTO(
            id: id,
            startDate: startDate,
            endDate: endDate,
            durationSeconds: durationSeconds,
            distanceKm: distanceKm,
            estimatedCalories: estimatedCalories,
            averageSpeedKmh: averageSpeedKmh,
            maxSpeedKmh: maxSpeedKmh,
            inclineLevel: inclineLevel,
            isExportedToHealthKit: isExportedToHealthKit,
        )
    }

    /// Copie les champs du DTO sur un modèle existant (pour update).
    func update(from dto: WorkoutSessionDTO) {
        startDate = dto.startDate
        endDate = dto.endDate
        durationSeconds = dto.durationSeconds
        distanceKm = dto.distanceKm
        estimatedCalories = dto.estimatedCalories
        averageSpeedKmh = dto.averageSpeedKmh
        maxSpeedKmh = dto.maxSpeedKmh
        inclineLevel = dto.inclineLevel
        isExportedToHealthKit = dto.isExportedToHealthKit
    }
}
