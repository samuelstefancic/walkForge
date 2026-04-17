// WalkForge — DataKit
// Agent-Data: implémentation SwiftData du UserProfileRepository.

import DomainKit
import Foundation
import SwiftData

/// Implémentation SwiftData de `UserProfileRepository`.
///
/// Sémantique : au plus un profil persisté à la fois ("singleton" applicatif).
/// `save` met à jour le profil existant ou l'insère.
@ModelActor
public actor SwiftDataUserProfileRepository: UserProfileRepository {
    public func load() async throws -> UserProfileDTO? {
        let descriptor = FetchDescriptor<UserProfileModel>()
        return try modelContext.fetch(descriptor).first?.toDTO()
    }

    public func save(_ profile: UserProfileDTO) async throws {
        let descriptor = FetchDescriptor<UserProfileModel>()
        if let existing = try modelContext.fetch(descriptor).first {
            existing.update(from: profile)
        } else {
            modelContext.insert(UserProfileModel(
                weightKg: profile.weightKg,
                heightCm: profile.heightCm,
                ageYears: profile.ageYears,
                preferredSpeedKmh: profile.preferredSpeedKmh,
                dailyStepGoal: profile.dailyStepGoal,
                dailyDistanceGoalKm: profile.dailyDistanceGoalKm,
                lastLubricationDate: profile.lastLubricationDate,
                totalSessionCount: profile.totalSessionCount,
                nextMaintenanceAlertDate: profile.nextMaintenanceAlertDate,
            ))
        }
        try modelContext.save()
    }
}
