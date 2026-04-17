// WalkForge — DesignSystem
// Agent-UI: slider de vitesse custom, alignement sur le pas du SpeedRange.

import DomainKit
import SwiftUI

/// Slider de sélection de vitesse avec snap sur un pas (`SpeedRange.stepKmh`).
///
/// Le binding est snappé : toute valeur entrée est arrondie au pas le plus proche.
/// Déclenche un haptic `speedChanged` à chaque pas.
public struct SpeedSlider: View {
    @Binding private var value: Double
    private let range: SpeedRange
    private let onChangeConfirmed: ((Double) -> Void)?

    public init(
        value: Binding<Double>,
        range: SpeedRange = .portentum8Pro,
        onChangeConfirmed: ((Double) -> Void)? = nil,
    ) {
        _value = value
        self.range = range
        self.onChangeConfirmed = onChangeConfirmed
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: WFSpacing.sm) {
            HStack {
                Text("Vitesse")
                    .font(WFFont.metricLabel)
                    .foregroundStyle(WFColor.textSecondary)
                    .tracking(1.2)
                Spacer()
                Text(String(format: "%.1f km/h", value))
                    .font(WFFont.metricM)
                    .foregroundStyle(WFColor.accentPrimary)
                    .contentTransition(.numericText())
            }

            Slider(
                value: Binding(
                    get: { value },
                    set: { newValue in
                        let snapped = range.snap(newValue)
                        if snapped != value {
                            value = snapped
                            Task { @MainActor in WFHaptic.speedChanged.play() }
                        }
                    },
                ),
                in: range.minKmh ... range.maxKmh,
                step: range.stepKmh,
                onEditingChanged: { editing in
                    if !editing {
                        onChangeConfirmed?(value)
                    }
                },
            )
            .tint(WFColor.accentPrimary)

            HStack {
                Text(String(format: "%.1f", range.minKmh))
                Spacer()
                Text(String(format: "%.1f", range.maxKmh))
            }
            .font(WFFont.caption)
            .foregroundStyle(WFColor.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Vitesse cible")
        .accessibilityValue(String(format: "%.1f kilomètres par heure", value))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                let newValue = range.snap(value + range.stepKmh)
                value = newValue
                onChangeConfirmed?(newValue)
            case .decrement:
                let newValue = range.snap(value - range.stepKmh)
                value = newValue
                onChangeConfirmed?(newValue)
            @unknown default:
                break
            }
        }
    }
}

#Preview("SpeedSlider") {
    @Previewable @State var speed = 3.0
    VStack {
        SpeedSlider(value: $speed)
            .padding(WFSpacing.lg)
            .background(WFColor.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: WFCornerRadius.medium))
    }
    .padding()
    .background(WFColor.backgroundPrimary)
}
