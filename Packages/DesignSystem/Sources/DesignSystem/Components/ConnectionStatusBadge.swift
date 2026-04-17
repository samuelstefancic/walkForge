// WalkForge — DesignSystem
// Agent-UI: badge pilule affichant l'état de la connexion BLE.

import DomainKit
import SwiftUI

/// Badge pilule affichant l'état BLE : icône + label, couleur selon l'état.
public struct ConnectionStatusBadge: View {
    private let state: TreadmillConnectionState

    public init(state: TreadmillConnectionState) {
        self.state = state
    }

    public var body: some View {
        HStack(spacing: WFSpacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(color.opacity(0.3), lineWidth: 4)
                        .scaleEffect(isAnimating ? 1.8 : 1.0)
                        .opacity(isAnimating ? 0 : 1),
                )

            Text(label)
                .font(WFFont.caption)
                .fontWeight(.semibold)
                .foregroundStyle(WFColor.textPrimary)
        }
        .padding(.horizontal, WFSpacing.md)
        .padding(.vertical, WFSpacing.xs + 2)
        .background(
            Capsule().fill(WFColor.backgroundSecondary),
        )
        .accessibilityLabel("État connexion")
        .accessibilityValue(label)
    }

    private var isAnimating: Bool {
        switch state {
        case .scanning, .connecting:
            true
        default:
            false
        }
    }

    private var label: String {
        switch state {
        case .unsupported: "Non supporté"
        case .poweredOff: "BT éteint"
        case .unauthorized: "Autorisation BT"
        case .idle: "Prêt"
        case .scanning: "Recherche…"
        case .connecting: "Connexion…"
        case .connected: "Connecté"
        case .disconnecting: "Déconnexion…"
        case .disconnected: "Déconnecté"
        case .failed: "Échec"
        }
    }

    private var color: Color {
        switch state {
        case .connected: WFColor.success
        case .scanning, .connecting: WFColor.accentPrimary
        case .failed, .poweredOff, .unauthorized, .unsupported: WFColor.danger
        case .idle, .disconnected, .disconnecting: WFColor.textSecondary
        }
    }
}

#Preview("ConnectionStatusBadge") {
    ZStack {
        WFColor.backgroundPrimary.ignoresSafeArea()
        VStack(spacing: WFSpacing.md) {
            ConnectionStatusBadge(state: .idle)
            ConnectionStatusBadge(state: .scanning)
            ConnectionStatusBadge(state: .connecting(deviceID: "abc"))
            ConnectionStatusBadge(state: .connected(deviceID: "abc"))
            ConnectionStatusBadge(state: .failed(reason: "timeout"))
            ConnectionStatusBadge(state: .poweredOff)
        }
    }
}
