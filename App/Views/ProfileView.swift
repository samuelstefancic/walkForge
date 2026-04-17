// WalkForge — App
// Agent-Profile: écran de profil utilisateur + maintenance du tapis.

import DesignSystem
import DomainKit
import SwiftUI

struct ProfileView: View {
    @Bindable var viewModel: ProfileViewModel

    var body: some View {
        NavigationStack {
            Form {
                measurementsSection
                goalsSection
                maintenanceSection
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(WFColor.danger)
                    }
                }
                if viewModel.savedBannerVisible {
                    Section {
                        Label("Enregistré", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(WFColor.success)
                    }
                }
            }
            .navigationTitle("Profil")
            .scrollContentBackground(.hidden)
            .background(WFColor.backgroundPrimary)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        Task { await viewModel.save() }
                    }
                }
            }
            .task { await viewModel.load() }
        }
    }

    // MARK: - Sections

    private var measurementsSection: some View {
        Section("Mensurations") {
            Stepper(
                "Poids : \(Int(viewModel.weightKg)) kg",
                value: $viewModel.weightKg,
                in: 40 ... 200,
                step: 1,
            )
            Stepper(
                "Taille : \(Int(viewModel.heightCm)) cm",
                value: $viewModel.heightCm,
                in: 120 ... 220,
                step: 1,
            )
            Stepper(
                "Âge : \(viewModel.ageYears) ans",
                value: $viewModel.ageYears,
                in: 12 ... 100,
                step: 1,
            )
        }
    }

    private var goalsSection: some View {
        Section("Objectifs quotidiens") {
            Stepper(
                "Pas : \(viewModel.dailyStepGoal)",
                value: $viewModel.dailyStepGoal,
                in: 1000 ... 30000,
                step: 500,
            )
            Stepper(
                "Distance : \(String(format: "%.1f", viewModel.dailyDistanceGoalKm)) km",
                value: $viewModel.dailyDistanceGoalKm,
                in: 1 ... 20,
                step: 0.5,
            )
            Stepper(
                "Vitesse préférée : \(String(format: "%.1f", viewModel.preferredSpeedKmh)) km/h",
                value: $viewModel.preferredSpeedKmh,
                in: 1 ... 6,
                step: 0.5,
            )
        }
    }

    private var maintenanceSection: some View {
        Section("Maintenance tapis") {
            if let last = viewModel.lastLubricationDate {
                LabeledContent("Dernière lubrification", value: last.formatted(date: .abbreviated, time: .omitted))
            } else {
                Text("Jamais lubrifié")
                    .foregroundStyle(WFColor.textSecondary)
            }
            if let next = viewModel.nextMaintenanceAlertDate {
                LabeledContent("Prochaine échéance", value: next.formatted(date: .abbreviated, time: .omitted))
            }
            Button {
                Task { await viewModel.markLubricatedNow() }
            } label: {
                Label("Lubrifié aujourd'hui", systemImage: "drop.fill")
            }
            LabeledContent("Sessions totales", value: "\(viewModel.totalSessionCount)")
        }
    }
}

#Preview("Profile") {
    let services = AppServices.preview()
    let viewModel = ProfileViewModel(
        repository: services.userProfileRepository,
        notificationService: services.notificationService,
    )
    return ProfileView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}
