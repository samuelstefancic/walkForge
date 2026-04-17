// WalkForge — DesignSystem
// Agent-UI: anneau de progression autour de la métrique principale.

import SwiftUI

/// Anneau de progression (0…1) pour l'objectif du jour.
///
/// Trace un cercle de fond + un arc de progression en `accentPrimary`,
/// avec animation sur la transition de `progress`.
public struct SessionProgressRing: View {
    private let progress: Double
    private let lineWidth: CGFloat
    private let tint: Color

    public init(
        progress: Double,
        lineWidth: CGFloat = 8,
        tint: Color = WFColor.accentPrimary,
    ) {
        self.progress = max(0, min(1, progress))
        self.lineWidth = lineWidth
        self.tint = tint
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(WFColor.backgroundSecondary, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round),
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: progress)
        }
        .accessibilityLabel("Progression objectif")
        .accessibilityValue("\(Int(progress * 100)) pour cent")
    }
}

#Preview("SessionProgressRing") {
    @Previewable @State var progress = 0.65
    ZStack {
        WFColor.backgroundPrimary.ignoresSafeArea()
        VStack {
            SessionProgressRing(progress: progress, lineWidth: 12)
                .frame(width: 200, height: 200)
            Slider(value: $progress, in: 0 ... 1)
                .padding()
        }
    }
}
