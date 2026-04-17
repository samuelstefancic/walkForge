// WalkForge — DomainKit
// Agent-Domain: contrat repository des programmes (timer, intervalles, objectifs).
// Sera implémenté par DataKit au Sprint 3.

import Foundation

/// Type de programme d'entraînement.
public enum ProgramType: String, Sendable, Equatable, Hashable, CaseIterable {
    case timer
    case intervals
    case goal
    case reminder
}

/// Une étape d'un programme (par ex. "5 min à 4 km/h").
public struct ProgramStepDTO: Sendable, Equatable, Hashable, Identifiable {
    public let id: UUID
    public let targetSpeedKmh: Double
    public let durationSeconds: Int
    public let inclineLevel: Int

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
}

/// DTO d'un programme d'entraînement.
public struct SessionProgramDTO: Sendable, Equatable, Hashable, Identifiable {
    public let id: UUID
    public var name: String
    public var type: ProgramType
    public var steps: [ProgramStepDTO]
    public var scheduledTime: Date?
    public var isActive: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        type: ProgramType,
        steps: [ProgramStepDTO],
        scheduledTime: Date? = nil,
        isActive: Bool = true,
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.steps = steps
        self.scheduledTime = scheduledTime
        self.isActive = isActive
    }
}

/// Repository des programmes d'entraînement.
public protocol SessionProgramRepository: Sendable {
    func listAll() async throws -> [SessionProgramDTO]
    func save(_ program: SessionProgramDTO) async throws
    func delete(id: UUID) async throws
    func find(id: UUID) async throws -> SessionProgramDTO?
}
