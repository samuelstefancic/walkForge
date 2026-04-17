// WalkForge — App
// Agent-Profile: ViewModel de la liste et du CRUD de programmes.

import DomainKit
import Foundation
import Observation
import os

@MainActor
@Observable
public final class ProgramsViewModel {
    public private(set) var programs: [SessionProgramDTO] = []
    public private(set) var errorMessage: String?

    private let repository: any SessionProgramRepository
    private let logger = Logger(subsystem: "com.samuel.walkforge", category: "Programs")

    public init(repository: any SessionProgramRepository) {
        self.repository = repository
    }

    public func load() async {
        do {
            programs = try await repository.listAll()
            errorMessage = nil
        } catch {
            errorMessage = "Chargement des programmes échoué"
            logger.error("Programs load failed: \(String(describing: error), privacy: .public)")
        }
    }

    public func addQuickProgram(name: String, type: ProgramType, durationMinutes: Int, speedKmh: Double) async {
        let program = SessionProgramDTO(
            name: name,
            type: type,
            steps: [
                ProgramStepDTO(
                    targetSpeedKmh: speedKmh,
                    durationSeconds: durationMinutes * 60,
                    inclineLevel: 0,
                ),
            ],
        )
        do {
            try await repository.save(program)
            await load()
        } catch {
            errorMessage = "Création échouée"
            logger.error("Program save failed: \(String(describing: error), privacy: .public)")
        }
    }

    public func delete(id: UUID) async {
        do {
            try await repository.delete(id: id)
            await load()
        } catch {
            errorMessage = "Suppression échouée"
            logger.error("Program delete failed: \(String(describing: error), privacy: .public)")
        }
    }
}
