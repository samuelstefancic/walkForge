// WalkForge — App
// Agent-History: écran historique + Charts framework + export CSV.

import Charts
import DesignSystem
import DomainKit
import SwiftUI
import UniformTypeIdentifiers

struct HistoryView: View {
    @Bindable var viewModel: HistoryViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                WFColor.backgroundPrimary.ignoresSafeArea()
                content
            }
            .navigationTitle("Historique")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(
                        item: csvFile,
                        preview: SharePreview("WalkForge — sessions.csv"),
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Exporter CSV")
                }
            }
            .task { await viewModel.load() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: WFSpacing.lg) {
                filterPicker
                summaryCards
                chartSection
                if viewModel.sessions.isEmpty {
                    emptyState
                } else {
                    sessionsList
                }
            }
            .padding(.horizontal, WFSpacing.lg)
            .padding(.vertical, WFSpacing.md)
        }
    }

    // MARK: - Sections

    private var filterPicker: some View {
        Picker("Période", selection: $viewModel.filter) {
            ForEach(HistoryViewModel.Filter.allCases, id: \.self) { filter in
                Text(filter.label).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: WFSpacing.sm) {
            MetricCard(
                label: "Sessions",
                value: String(viewModel.sessionsCount),
                systemImage: "list.bullet",
            )
            MetricCard(
                label: "Streak",
                value: "\(viewModel.streakDays) j",
                systemImage: "flame.fill",
                tint: WFColor.warning,
            )
            MetricCard(
                label: "Distance",
                value: String(format: "%.1f", viewModel.totalDistanceKm),
                unit: "km",
                systemImage: "figure.walk",
            )
            MetricCard(
                label: "Calories",
                value: String(format: "%.0f", viewModel.totalCalories),
                unit: "kcal",
                systemImage: "flame.fill",
                tint: WFColor.warning,
            )
        }
    }

    @ViewBuilder
    private var chartSection: some View {
        if !viewModel.dailyDistances.isEmpty {
            VStack(alignment: .leading, spacing: WFSpacing.sm) {
                Text("Distance par jour")
                    .font(WFFont.metricLabel)
                    .foregroundStyle(WFColor.textSecondary)
                    .tracking(1.2)

                Chart(viewModel.dailyDistances) { day in
                    BarMark(
                        x: .value("Jour", day.date, unit: .day),
                        y: .value("Distance", day.distanceKm),
                    )
                    .foregroundStyle(WFColor.accentPrimary)
                    .cornerRadius(2)
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 3))
                }
                .accessibilityLabel("Graphique distance par jour")
            }
            .padding(WFSpacing.lg)
            .background(WFColor.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: WFCornerRadius.medium))
        }
    }

    private var sessionsList: some View {
        VStack(spacing: WFSpacing.sm) {
            ForEach(viewModel.sessions) { session in
                SessionRow(session: session)
                    .padding(WFSpacing.md)
                    .background(WFColor.backgroundSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: WFCornerRadius.small))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await viewModel.delete(id: session.id) }
                        } label: {
                            Label("Supprimer", systemImage: "trash")
                        }
                    }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: WFSpacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(WFColor.textSecondary)
            Text("Aucune session")
                .font(WFFont.subtitle)
                .foregroundStyle(WFColor.textPrimary)
            Text("Lancez une session pour la voir apparaître ici.")
                .font(WFFont.caption)
                .foregroundStyle(WFColor.textSecondary)
        }
        .padding(.vertical, WFSpacing.xl)
    }

    // MARK: - CSV

    private var csvFile: CSVDocumentURL {
        CSVDocumentURL(content: viewModel.exportCSV())
    }
}

private struct SessionRow: View {
    let session: WorkoutSessionDTO

    var body: some View {
        HStack(spacing: WFSpacing.md) {
            Image(systemName: "figure.walk.motion")
                .font(.system(size: 22))
                .foregroundStyle(WFColor.accentPrimary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(WFFont.body)
                    .foregroundStyle(WFColor.textPrimary)
                Text(subtitle)
                    .font(WFFont.caption)
                    .foregroundStyle(WFColor.textSecondary)
            }
            Spacer()
            Text(String(format: "%.2f km", session.distanceKm))
                .font(WFFont.metricLabel)
                .foregroundStyle(WFColor.accentPrimary)
        }
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        let minutes = session.durationSeconds / 60
        return "\(minutes) min · \(Int(session.estimatedCalories)) kcal"
    }
}

/// Wrapper Transferable pour partager le CSV via ShareLink.
private struct CSVDocumentURL: Transferable {
    let content: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { item in
            Data(item.content.utf8)
        }
        .suggestedFileName { _ in "walkforge-sessions.csv" }
    }
}

#Preview("History") {
    let services = AppServices.preview()
    let viewModel = HistoryViewModel(repository: services.workoutRepository)
    return HistoryView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}
