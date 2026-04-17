// WalkForge — DesignSystem
// Agent-UI: carte métrique affichant une valeur numérique + label + icône.

import SwiftUI

/// Carte affichant une métrique temps-réel (vitesse, distance, durée, calories…).
///
/// Convention d'usage :
/// ```swift
/// MetricCard(
///     label: "Distance",
///     value: "1.24",
///     unit: "km",
///     systemImage: "figure.walk"
/// )
/// ```
public struct MetricCard: View {
    private let label: String
    private let value: String
    private let unit: String?
    private let systemImage: String?
    private let tint: Color

    public init(
        label: String,
        value: String,
        unit: String? = nil,
        systemImage: String? = nil,
        tint: Color = WFColor.accentPrimary,
    ) {
        self.label = label
        self.value = value
        self.unit = unit
        self.systemImage = systemImage
        self.tint = tint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: WFSpacing.sm) {
            HStack(spacing: WFSpacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(tint)
                }
                Text(label.uppercased())
                    .font(WFFont.metricLabel)
                    .foregroundStyle(WFColor.textSecondary)
                    .tracking(1.2)
            }

            HStack(alignment: .lastTextBaseline, spacing: WFSpacing.xs) {
                Text(value)
                    .font(WFFont.metricM)
                    .foregroundStyle(WFColor.textPrimary)
                    .contentTransition(.numericText())
                if let unit {
                    Text(unit)
                        .font(WFFont.metricLabel)
                        .foregroundStyle(WFColor.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(WFSpacing.lg)
        .background(WFColor.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: WFCornerRadius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(unit.map { "\(value) \($0)" } ?? value)
    }
}

#Preview("MetricCard examples") {
    VStack(spacing: WFSpacing.md) {
        MetricCard(label: "Distance", value: "1.24", unit: "km", systemImage: "figure.walk")
        MetricCard(label: "Calories", value: "127", unit: "kcal", systemImage: "flame.fill", tint: WFColor.warning)
        MetricCard(label: "Durée", value: "00:24:15", systemImage: "clock.fill")
    }
    .padding()
    .background(WFColor.backgroundPrimary)
}
