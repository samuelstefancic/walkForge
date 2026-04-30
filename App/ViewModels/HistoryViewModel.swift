// WalkForge — App
// Agent-History: ViewModel de l'écran historique (liste + agrégations + export CSV).

import DomainKit
import Foundation
import Observation
import os

@MainActor
@Observable
public final class HistoryViewModel {
    public enum Filter: String, CaseIterable, Sendable, Hashable {
        case week
        case month
        case threeMonths
        case all

        var label: String {
            switch self {
            case .week: "7 j"
            case .month: "30 j"
            case .threeMonths: "3 mois"
            case .all: "Tout"
            }
        }
    }

    public private(set) var sessions: [WorkoutSessionDTO] = []
    public private(set) var streakDays = 0
    public private(set) var errorMessage: String?
    public var filter: Filter = .month {
        didSet { Task { await load() } }
    }

    /// Stats agrégées (calculées à partir de `sessions`).
    public var totalDistanceKm: Double {
        sessions.reduce(0.0) { $0 + $1.distanceKm }
    }

    public var totalCalories: Double {
        sessions.reduce(0.0) { $0 + $1.estimatedCalories }
    }

    public var totalSeconds: Int {
        sessions.reduce(0) { $0 + $1.durationSeconds }
    }

    public var sessionsCount: Int {
        sessions.count
    }

    /// Données pour le graphique distance/jour.
    public var dailyDistances: [DailyAggregate] {
        let calendar = Calendar(identifier: .gregorian)
        let grouped = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.startDate) }
        return grouped.map { day, sessions in
            DailyAggregate(
                date: day,
                distanceKm: sessions.reduce(0.0) { $0 + $1.distanceKm },
                calories: sessions.reduce(0.0) { $0 + $1.estimatedCalories },
                averageSpeedKmh: averageSpeed(of: sessions),
            )
        }
        .sorted { $0.date < $1.date }
    }

    private let repository: any WorkoutSessionRepository
    private let logger = Logger(subsystem: "com.samuel.walkforge", category: "History")

    public init(repository: any WorkoutSessionRepository) {
        self.repository = repository
    }

    public func load() async {
        do {
            let now = Date()
            sessions = switch filter {
            case .all: try await repository.listAll()
            case .week: try await repository.list(from: now.addingTimeInterval(-7 * 86400), to: now)
            case .month: try await repository.list(from: now.addingTimeInterval(-30 * 86400), to: now)
            case .threeMonths: try await repository.list(
                    from: now.addingTimeInterval(-90 * 86400),
                    to: now,
                )
            }
            streakDays = try await repository.currentStreakDays(now: now)
            errorMessage = nil
        } catch {
            errorMessage = "Chargement historique échoué"
            logger.error("History load: \(String(describing: error), privacy: .public)")
        }
    }

    public func delete(id: UUID) async {
        do {
            try await repository.delete(id: id)
            await load()
        } catch {
            errorMessage = "Suppression échouée"
            logger.error("History delete: \(String(describing: error), privacy: .public)")
        }
    }

    /// Génère le contenu CSV des sessions courantes (à exporter via ShareLink).
    public func exportCSV() -> String {
        let header = "id,startDate,endDate,durationSeconds,distanceKm,estimatedCalories,"
            + "averageSpeedKmh,maxSpeedKmh,inclineLevel\n"
        let formatter = ISO8601DateFormatter()
        let rows = sessions.map { session in
            let endStr = session.endDate.map { formatter.string(from: $0) } ?? ""
            return [
                session.id.uuidString,
                formatter.string(from: session.startDate),
                endStr,
                String(session.durationSeconds),
                String(session.distanceKm),
                String(session.estimatedCalories),
                String(session.averageSpeedKmh),
                String(session.maxSpeedKmh),
                String(session.inclineLevel),
            ].joined(separator: ",")
        }
        return header + rows.joined(separator: "\n") + "\n"
    }

    // MARK: - Private

    private func averageSpeed(of sessions: [WorkoutSessionDTO]) -> Double {
        guard !sessions.isEmpty else { return 0 }
        let sum = sessions.reduce(0.0) { $0 + $1.averageSpeedKmh }
        return sum / Double(sessions.count)
    }
}

/// Donnée agrégée par jour (pour les graphiques).
public struct DailyAggregate: Sendable, Equatable, Hashable, Identifiable {
    public var id: Date {
        date
    }

    public let date: Date
    public let distanceKm: Double
    public let calories: Double
    public let averageSpeedKmh: Double
}
