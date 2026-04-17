// WalkForge — DomainKit
// Agent-Domain: entité immuable représentant un instantané de l'état du tapis.

import Foundation

/// Instantané de l'état du tapis à un moment donné.
///
/// Émis par le service BLE FTMS à chaque notification sur la caractéristique
/// `Treadmill Data` (UUID `0x2ACD`).
///
/// Tous les champs optionnels reflètent les flags transmis par le tapis : si
/// le constructeur ne diffuse pas un champ, sa valeur reste `nil` plutôt que
/// `0`, afin de distinguer "inconnu" de "nul".
public struct TreadmillData: Sendable, Equatable, Hashable {
    /// Vitesse instantanée en km/h.
    public let speedKmh: Double

    /// Distance totale parcourue depuis le démarrage, en kilomètres.
    public let distanceKm: Double

    /// Temps écoulé depuis le démarrage, en secondes.
    public let elapsedTimeSeconds: Int

    /// Énergie totale dépensée, en kcal. `nil` si non transmis.
    public let totalEnergyKcal: Double?

    /// Inclinaison en pourcentage (ex: 2.5 %). `nil` si non transmis.
    public let inclinationPercent: Double?

    /// Fréquence cardiaque en battements par minute. `nil` si non disponible.
    public let heartRate: Int?

    /// Horodatage de la lecture.
    public let timestamp: Date

    public init(
        speedKmh: Double,
        distanceKm: Double,
        elapsedTimeSeconds: Int,
        totalEnergyKcal: Double? = nil,
        inclinationPercent: Double? = nil,
        heartRate: Int? = nil,
        timestamp: Date = Date(),
    ) {
        self.speedKmh = speedKmh
        self.distanceKm = distanceKm
        self.elapsedTimeSeconds = elapsedTimeSeconds
        self.totalEnergyKcal = totalEnergyKcal
        self.inclinationPercent = inclinationPercent
        self.heartRate = heartRate
        self.timestamp = timestamp
    }

    /// Instantané par défaut "tapis à l'arrêt" pour initialisation UI.
    public static let idle: TreadmillData = .init(
        speedKmh: 0,
        distanceKm: 0,
        elapsedTimeSeconds: 0,
    )
}
