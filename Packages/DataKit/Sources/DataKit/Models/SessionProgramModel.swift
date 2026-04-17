// WalkForge — DataKit
// Agent-Data: modèle SwiftData d'un programme d'entraînement + étapes.

import DomainKit
import Foundation
import SwiftData

@Model
public final class SessionProgramModel {
    @Attribute(.unique)
    public var id: UUID
    public var name: String
    /// Raw value de `ProgramType` (SwiftData ne supporte pas directement les
    /// enums custom via macro sur tous les runtimes, on stocke le raw).
    public var typeRawValue: String
    @Relationship(deleteRule: .cascade)
    public var steps: [ProgramStepModel]
    public var scheduledTime: Date?
    public var isActive: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        type: ProgramType,
        steps: [ProgramStepModel] = [],
        scheduledTime: Date? = nil,
        isActive: Bool = true,
    ) {
        self.id = id
        self.name = name
        typeRawValue = type.rawValue
        self.steps = steps
        self.scheduledTime = scheduledTime
        self.isActive = isActive
    }

    public var type: ProgramType {
        get { ProgramType(rawValue: typeRawValue) ?? .timer }
        set { typeRawValue = newValue.rawValue }
    }

    func toDTO() -> SessionProgramDTO {
        SessionProgramDTO(
            id: id,
            name: name,
            type: type,
            steps: steps.map { $0.toDTO() },
            scheduledTime: scheduledTime,
            isActive: isActive,
        )
    }

    static func from(dto: SessionProgramDTO) -> SessionProgramModel {
        let model = SessionProgramModel(
            id: dto.id,
            name: dto.name,
            type: dto.type,
            scheduledTime: dto.scheduledTime,
            isActive: dto.isActive,
        )
        model.steps = dto.steps.map { ProgramStepModel.from(dto: $0) }
        return model
    }

    func update(from dto: SessionProgramDTO) {
        name = dto.name
        type = dto.type
        scheduledTime = dto.scheduledTime
        isActive = dto.isActive
        // Cascade delete via la Relationship → on remplace simplement le tableau.
        // Les ProgramStepModel n'ayant pas de contrainte unique (cf. commentaire),
        // recréer avec les mêmes IDs que les anciens est sûr.
        let newSteps = dto.steps.map { ProgramStepModel.from(dto: $0) }
        steps = newSteps
    }
}

@Model
public final class ProgramStepModel {
    // Pas de @Attribute(.unique) : les steps sont enfants d'un programme
    // et recréés lors d'un update (cascade). Une contrainte unique sur leur id
    // provoquerait un conflit lors de la réutilisation d'un même DTO.
    public var id: UUID
    public var targetSpeedKmh: Double
    public var durationSeconds: Int
    public var inclineLevel: Int

    public init(
        id: UUID = UUID(),
        targetSpeedKmh: Double,
        durationSeconds: Int,
        inclineLevel: Int = 0,
    ) {
        self.id = id
        self.targetSpeedKmh = targetSpeedKmh
        self.durationSeconds = durationSeconds
        self.inclineLevel = inclineLevel
    }

    func toDTO() -> ProgramStepDTO {
        ProgramStepDTO(
            id: id,
            targetSpeedKmh: targetSpeedKmh,
            durationSeconds: durationSeconds,
            inclineLevel: inclineLevel,
        )
    }

    static func from(dto: ProgramStepDTO) -> ProgramStepModel {
        ProgramStepModel(
            id: dto.id,
            targetSpeedKmh: dto.targetSpeedKmh,
            durationSeconds: dto.durationSeconds,
            inclineLevel: dto.inclineLevel,
        )
    }
}
