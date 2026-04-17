// WalkForge — DesignSystem
// Agent-UI: 4 boutons de sélection d'inclinaison discrète.

import DomainKit
import SwiftUI

/// Sélecteur de niveau d'inclinaison — 4 boutons (plat, bas, moyen, haut).
public struct InclineSelector: View {
    @Binding private var level: InclineLevel
    private let onSelection: ((InclineLevel) -> Void)?

    public init(
        level: Binding<InclineLevel>,
        onSelection: ((InclineLevel) -> Void)? = nil,
    ) {
        _level = level
        self.onSelection = onSelection
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: WFSpacing.sm) {
            Text("Inclinaison")
                .font(WFFont.metricLabel)
                .foregroundStyle(WFColor.textSecondary)
                .tracking(1.2)

            HStack(spacing: WFSpacing.sm) {
                ForEach(InclineLevel.allCases, id: \.self) { option in
                    button(for: option)
                }
            }
        }
    }

    @ViewBuilder
    private func button(for option: InclineLevel) -> some View {
        let isSelected = option == level
        Button {
            guard option != level else { return }
            level = option
            onSelection?(option)
            Task { @MainActor in WFHaptic.inclineChanged.play() }
        } label: {
            VStack(spacing: 2) {
                Text(option.shortLabel)
                    .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                Text(String(format: "%.0f%%", option.percentValue))
                    .font(WFFont.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(isSelected ? WFColor.backgroundPrimary : WFColor.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: WFCornerRadius.small)
                    .fill(isSelected ? WFColor.accentPrimary : WFColor.backgroundSecondary),
            )
            .overlay(
                RoundedRectangle(cornerRadius: WFCornerRadius.small)
                    .stroke(
                        isSelected ? WFColor.accentPrimary : WFColor.textSecondary.opacity(0.2),
                        lineWidth: 1,
                    ),
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Inclinaison niveau \(option.shortLabel)")
        .accessibilityValue("\(option.percentValue) pourcent")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview("InclineSelector") {
    @Previewable @State var level: InclineLevel = .low
    VStack {
        InclineSelector(level: $level)
            .padding(WFSpacing.lg)
            .background(WFColor.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: WFCornerRadius.medium))
    }
    .padding()
    .background(WFColor.backgroundPrimary)
}
