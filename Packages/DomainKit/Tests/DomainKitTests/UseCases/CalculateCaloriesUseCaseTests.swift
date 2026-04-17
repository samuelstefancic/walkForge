// WalkForge — DomainKitTests
// Agent-Tests: formule MET-based du calcul de calories.

@testable import DomainKit
import Testing

@Suite("CalculateCaloriesUseCase · formule MET")
struct CalculateCaloriesUseCaseTests {
    let useCase = CalculateCaloriesUseCase()

    @Test("Durée 0 → 0 calorie")
    func zeroDuration() {
        let kcal = useCase.execute(weightKg: 75, speedKmh: 3.0, durationSeconds: 0)
        #expect(kcal == 0)
    }

    @Test("Vitesse 0 → 0 calorie")
    func zeroSpeed() {
        let kcal = useCase.execute(weightKg: 75, speedKmh: 0, durationSeconds: 3600)
        #expect(kcal == 0)
    }

    @Test("Poids 0 → 0 calorie")
    func zeroWeight() {
        let kcal = useCase.execute(weightKg: 0, speedKmh: 3.0, durationSeconds: 3600)
        #expect(kcal == 0)
    }

    @Test("Référence : 75 kg, 3 km/h pendant 1h = MET 3.3 × 75 = 247.5 kcal")
    func referenceWalk() {
        // MET 3.3 × 75 kg × 1 h = 247.5 kcal
        let kcal = useCase.execute(weightKg: 75, speedKmh: 3.0, durationSeconds: 3600)
        #expect(kcal == 247.5)
    }

    @Test("MET croissant avec la vitesse")
    func monotonicMET() {
        let speeds = [1.5, 2.5, 3.5, 4.5, 5.5, 6.5]
        let mets = speeds.map { CalculateCaloriesUseCase.metValue(for: $0, inclinePercent: 0) }
        for index in 1 ..< mets.count {
            #expect(
                mets[index] > mets[index - 1],
                "MET à \(speeds[index]) km/h devrait être > à \(speeds[index - 1]) km/h",
            )
        }
    }

    @Test("Inclinaison +5 % augmente les calories de ~25 %")
    func inclinationBoost() {
        let flat = useCase.execute(weightKg: 75, speedKmh: 4.0, durationSeconds: 3600, inclinePercent: 0)
        let inclined = useCase.execute(weightKg: 75, speedKmh: 4.0, durationSeconds: 3600, inclinePercent: 5)
        // Facteur +5 * 0.05 = 1.25 → +25 %
        #expect(abs(inclined - flat * 1.25) < 0.01)
    }

    @Test("Demi-heure à 5 km/h ≈ MET 5.8 × 75 × 0.5 = 217.5 kcal")
    func halfHourBrisk() {
        let kcal = useCase.execute(weightKg: 75, speedKmh: 5.0, durationSeconds: 1800)
        #expect(kcal == 217.5)
    }

    @Test("Inclinaison négative traitée comme 0 (pas de boost)")
    func negativeInclineIgnored() {
        let flat = useCase.execute(weightKg: 75, speedKmh: 4.0, durationSeconds: 3600)
        let downhill = useCase.execute(
            weightKg: 75,
            speedKmh: 4.0,
            durationSeconds: 3600,
            inclinePercent: -5,
        )
        #expect(flat == downhill)
    }
}
