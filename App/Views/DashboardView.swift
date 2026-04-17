// WalkForge — App
// Agent-Session: écran live principal.

import BLECore
import DesignSystem
import DomainKit
import SwiftUI

/// Dashboard live principal.
///
/// Hiérarchie :
/// - Header : titre + badge statut BLE
/// - Metric grid : vitesse (XL), distance, durée, calories
/// - Contrôles : slider vitesse, sélecteur inclinaison
/// - Bouton start/stop
/// - Banner d'erreur (si `errorMessage`)
struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel

    var body: some View {
        ZStack {
            WFColor.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: WFSpacing.lg) {
                    header
                    mainSpeedHero
                    metricsGrid
                    controls
                    sessionToggleButton
                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }
                }
                .padding(.horizontal, WFSpacing.lg)
                .padding(.vertical, WFSpacing.xl)
            }
        }
        .task {
            await viewModel.subscribeToStreams()
        }
        .task {
            await viewModel.startScanning()
            // Auto-connect au premier device simulé (Sprint 2 = MockBLE uniquement)
            if let first = viewModel.discoveredDevices.first {
                await viewModel.connect(to: first)
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: WFSpacing.xs) {
                Text("Session")
                    .font(WFFont.screenTitle)
                    .foregroundStyle(WFColor.textPrimary)
                Text(subtitle)
                    .font(WFFont.subtitle)
                    .foregroundStyle(WFColor.textSecondary)
            }
            Spacer()
            ConnectionStatusBadge(state: viewModel.connectionState)
        }
    }

    private var subtitle: String {
        switch viewModel.connectionState {
        case let .connected(deviceID):
            if let name = viewModel.discoveredDevices
                .first(where: { $0.id == deviceID })?.name
            {
                return name
            }
            return "Tapis connecté"
        case .scanning:
            return "Recherche d'un tapis…"
        case .connecting:
            return "Connexion en cours…"
        default:
            return "Prêt à connecter"
        }
    }

    private var mainSpeedHero: some View {
        VStack(spacing: WFSpacing.sm) {
            Text(String(format: "%.1f", viewModel.instantaneousSpeedKmh))
                .font(WFFont.metricXL)
                .foregroundStyle(WFColor.accentPrimary)
                .contentTransition(.numericText())
            Text("km/h")
                .font(WFFont.metricLabel)
                .foregroundStyle(WFColor.textSecondary)
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, WFSpacing.xl)
        .background(WFColor.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: WFCornerRadius.large))
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: WFSpacing.md) {
            MetricCard(
                label: "Distance",
                value: String(format: "%.2f", viewModel.distanceKm),
                unit: "km",
                systemImage: "figure.walk",
            )
            MetricCard(
                label: "Durée",
                value: formattedDuration(viewModel.elapsedSeconds),
                systemImage: "clock.fill",
            )
            MetricCard(
                label: "Calories",
                value: String(format: "%.0f", viewModel.caloriesKcal),
                unit: "kcal",
                systemImage: "flame.fill",
                tint: WFColor.warning,
            )
            MetricCard(
                label: "Inclinaison",
                value: viewModel.inclineLevel.shortLabel,
                unit: "niv.",
                systemImage: "arrow.up.forward",
                tint: WFColor.accentSecondary,
            )
        }
    }

    private var controls: some View {
        VStack(spacing: WFSpacing.lg) {
            SpeedSlider(
                value: Binding(
                    get: { viewModel.targetSpeedKmh },
                    set: { viewModel.targetSpeedKmh = $0 },
                ),
                onChangeConfirmed: { _ in
                    Task { await viewModel.applyTargetSpeed() }
                },
            )
            .padding(WFSpacing.lg)
            .background(WFColor.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: WFCornerRadius.medium))

            InclineSelector(
                level: Binding(
                    get: { viewModel.inclineLevel },
                    set: { newValue in
                        Task { await viewModel.applyIncline(newValue) }
                    },
                ),
            )
            .padding(WFSpacing.lg)
            .background(WFColor.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: WFCornerRadius.medium))
        }
        .opacity(viewModel.canControl ? 1.0 : 0.45)
        .disabled(!viewModel.canControl)
    }

    private var sessionToggleButton: some View {
        Button {
            Task {
                await viewModel.toggleSession()
                await MainActor.run {
                    (viewModel.isSessionActive ? WFHaptic.sessionStart : WFHaptic.sessionStop).play()
                }
            }
        } label: {
            HStack(spacing: WFSpacing.sm) {
                Image(systemName: viewModel.isSessionActive ? "stop.fill" : "play.fill")
                Text(viewModel.isSessionActive ? "Arrêter" : "Démarrer")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(WFColor.backgroundPrimary)
            .background(
                RoundedRectangle(cornerRadius: WFCornerRadius.medium)
                    .fill(viewModel.isSessionActive ? WFColor.danger : WFColor.accentPrimary),
            )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canControl)
        .opacity(viewModel.canControl ? 1.0 : 0.5)
        .accessibilityIdentifier(
            viewModel.isSessionActive ? "session.stop" : "session.start",
        )
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: WFSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(WFColor.danger)
            Text(message)
                .font(WFFont.caption)
                .foregroundStyle(WFColor.textPrimary)
            Spacer()
        }
        .padding(WFSpacing.md)
        .background(WFColor.danger.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: WFCornerRadius.small))
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

#Preview("Dashboard · Mock") {
    let mock = MockBLEManager()
    let viewModel = DashboardViewModel(bleService: mock)
    return DashboardView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}
