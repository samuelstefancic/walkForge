// WalkForge — BLECoreTests
// Agent-Tests: validation du simulateur actor MockBLEManager.
// swiftlint:disable identifier_name

@testable import BLECore
import DomainKit
import Foundation
import Testing

@Suite("MockBLEManager · lifecycle + commandes")
struct MockBLEManagerTests {
    @Test
    func `État initial = idle`() async {
        let mock = MockBLEManager()
        let state = await mock.currentConnectionState
        #expect(state == .idle)
    }

    @Test
    func `startScanning → état scanning + device émis`() async throws {
        let mock = MockBLEManager()

        // Itération limitée pour ne pas bloquer
        let deviceTask = Task { () -> DiscoveredDevice? in
            for await device in mock.discoveredDevicesStream {
                return device
            }
            return nil
        }

        try await mock.startScanning()
        let device = await deviceTask.value

        #expect(device?.name == "PORTENTUM 8 Pro (Mock)")
        #expect(device?.advertisesFTMS == true)

        let state = await mock.currentConnectionState
        #expect(state == .scanning)
    }

    @Test
    func `connect → état connected`() async throws {
        let mock = MockBLEManager()
        try await mock.startScanning()

        let device = MockBLEManager.defaultDevices[0]
        try await mock.connect(to: device.id)

        let state = await mock.currentConnectionState
        if case let .connected(id) = state {
            #expect(id == device.id)
        } else {
            Issue.record("attendu .connected, reçu \(state)")
        }
    }

    @Test
    func `connect sur device inconnu → deviceNotFound`() async {
        let mock = MockBLEManager()
        await #expect(throws: TreadmillError.deviceNotFound) {
            try await mock.connect(to: "00000000-0000-0000-0000-FAKEFAKE0000")
        }
    }

    @Test
    func `start sans requestControl → controlNotGranted`() async throws {
        let mock = MockBLEManager()
        try await mock.startScanning()
        try await mock.connect(to: MockBLEManager.defaultDevices[0].id)

        await #expect(throws: TreadmillError.controlNotGranted) {
            try await mock.start()
        }
    }

    @Test
    func `start sans connexion → notConnected`() async {
        let mock = MockBLEManager()
        await #expect(throws: TreadmillError.notConnected) {
            try await mock.requestControl()
        }
    }

    @Test
    func `setTargetSpeed hors plage → invalidSpeed`() async throws {
        let mock = MockBLEManager()
        try await mock.startScanning()
        try await mock.connect(to: MockBLEManager.defaultDevices[0].id)
        try await mock.requestControl()

        await #expect(throws: TreadmillError.self) {
            try await mock.setTargetSpeed(kmh: 99.0)
        }
    }

    @Test
    func `Flux complet : scan → connect → control → start → set speed → data emise`() async throws {
        let mock = MockBLEManager(
            acceleration: 10.0, // très rapide pour test court
            tickInterval: .milliseconds(50),
        )

        try await mock.startScanning()
        try await mock.connect(to: MockBLEManager.defaultDevices[0].id)
        try await mock.requestControl()
        try await mock.setTargetSpeed(kmh: 3.0)
        try await mock.start()

        // Attendre une donnée reflétant la vitesse cible (~300 ms suffit)
        var nonZeroSeen = false
        let deadline = Date().addingTimeInterval(2.0)
        for await snapshot in mock.treadmillDataStream {
            if snapshot.speedKmh > 0 {
                nonZeroSeen = true
                break
            }
            if Date() > deadline { break }
        }
        #expect(nonZeroSeen)

        try await mock.stop()
    }

    @Test
    func `disconnect réinitialise la physique`() async throws {
        let mock = MockBLEManager()
        try await mock.startScanning()
        try await mock.connect(to: MockBLEManager.defaultDevices[0].id)
        try await mock.requestControl()
        try await mock.setTargetSpeed(kmh: 3.0)
        try await mock.start()

        try await Task.sleep(for: .milliseconds(50))
        await mock.disconnect()

        let state = await mock.currentConnectionState
        #expect(state == .disconnected)
    }
}
