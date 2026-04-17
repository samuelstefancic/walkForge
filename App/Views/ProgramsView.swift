// WalkForge — App
// Agent-Profile: liste + création rapide de programmes d'entraînement.

import DesignSystem
import DomainKit
import SwiftUI

struct ProgramsView: View {
    @Bindable var viewModel: ProgramsViewModel
    @State private var showingCreate = false

    var body: some View {
        NavigationStack {
            ZStack {
                WFColor.backgroundPrimary.ignoresSafeArea()
                content
            }
            .navigationTitle("Programmes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                QuickProgramCreator { name, type, minutes, speed in
                    Task { await viewModel.addQuickProgram(
                        name: name,
                        type: type,
                        durationMinutes: minutes,
                        speedKmh: speed,
                    )
                    }
                    showingCreate = false
                }
                .presentationDetents([.medium])
            }
            .task { await viewModel.load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.programs.isEmpty {
            emptyState
        } else {
            List {
                ForEach(viewModel.programs) { program in
                    ProgramRow(program: program)
                        .listRowBackground(WFColor.backgroundSecondary)
                }
                .onDelete { indices in
                    let ids = indices.map { viewModel.programs[$0].id }
                    Task {
                        for id in ids {
                            await viewModel.delete(id: id)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    private var emptyState: some View {
        VStack(spacing: WFSpacing.md) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(WFColor.textSecondary)
            Text("Aucun programme")
                .font(WFFont.subtitle)
                .foregroundStyle(WFColor.textPrimary)
            Text("Créez un programme avec le bouton +.")
                .font(WFFont.caption)
                .foregroundStyle(WFColor.textSecondary)
        }
    }
}

// MARK: - ProgramRow

private struct ProgramRow: View {
    let program: SessionProgramDTO

    var body: some View {
        HStack(spacing: WFSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(WFColor.accentPrimary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(program.name)
                    .font(WFFont.body)
                    .foregroundStyle(WFColor.textPrimary)
                Text(subtitle)
                    .font(WFFont.caption)
                    .foregroundStyle(WFColor.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, WFSpacing.xs)
    }

    private var icon: String {
        switch program.type {
        case .timer: "timer"
        case .intervals: "repeat"
        case .goal: "target"
        case .reminder: "bell.fill"
        }
    }

    private var subtitle: String {
        let stepCount = program.steps.count
        let totalMinutes = program.steps.reduce(0) { $0 + $1.durationSeconds } / 60
        return "\(stepCount) étape(s) · \(totalMinutes) min"
    }
}

// MARK: - QuickProgramCreator

private struct QuickProgramCreator: View {
    let onConfirm: (String, ProgramType, Int, Double) -> Void

    @State private var name = "Nouveau programme"
    @State private var type: ProgramType = .timer
    @State private var minutes = 15
    @State private var speed: Double = 3.0

    var body: some View {
        NavigationStack {
            Form {
                Section("Nom") {
                    TextField("Nom", text: $name)
                }
                Section("Type") {
                    Picker("Type", selection: $type) {
                        Text("Timer").tag(ProgramType.timer)
                        Text("Intervalles").tag(ProgramType.intervals)
                        Text("Objectif").tag(ProgramType.goal)
                        Text("Rappel").tag(ProgramType.reminder)
                    }
                }
                Section("Étape initiale") {
                    Stepper(
                        "Durée : \(minutes) min",
                        value: $minutes,
                        in: 1 ... 120,
                        step: 1,
                    )
                    Stepper(
                        "Vitesse : \(String(format: "%.1f", speed)) km/h",
                        value: $speed,
                        in: 1 ... 6,
                        step: 0.5,
                    )
                }
            }
            .navigationTitle("Nouveau programme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") {
                        onConfirm(name, type, minutes, speed)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview("Programs") {
    let services = AppServices.preview()
    let viewModel = ProgramsViewModel(repository: services.programRepository)
    return ProgramsView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}
