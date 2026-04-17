// WalkForge — BLECore
// Agent-BLE: simulateur complet, actor-isolé, pour tests unitaires et mode simulateur.
// Implémente BLETreadmillServiceProtocol avec une physique simple (vitesse cible
// → accélération linéaire → intégration distance + temps).

import DomainKit
import Foundation

/// Simulateur de tapis FTMS. Aucune dépendance à CoreBluetooth.
///
/// Expose le même protocol que `BLEManager` pour permettre aux ViewModels et
/// use cases d'être testés sans hardware ni simulateur.
///
/// Physique simulée :
/// - vitesse interpole linéairement vers la vitesse cible (`accelerationKmhPerSec`)
/// - distance = intégration de la vitesse sur le temps
/// - calories = estimation simple MET-based (détail dans `stepPhysics`)
public actor MockBLEManager: BLETreadmillServiceProtocol {
    // MARK: - Streams publics

    public nonisolated let connectionStateStream: AsyncStream<TreadmillConnectionState>
    public nonisolated let treadmillDataStream: AsyncStream<TreadmillData>
    public nonisolated let discoveredDevicesStream: AsyncStream<DiscoveredDevice>

    private let connectionContinuation: AsyncStream<TreadmillConnectionState>.Continuation
    private let dataContinuation: AsyncStream<TreadmillData>.Continuation
    private let devicesContinuation: AsyncStream<DiscoveredDevice>.Continuation

    // MARK: - Configuration

    /// Accélération nominale (0.5 km/h par seconde).
    public static let defaultAcceleration: Double = 0.5

    private let acceleration: Double
    private let tickInterval: Duration
    private let simulatedDevices: [DiscoveredDevice]
    private let userWeightKg: Double

    // MARK: - État interne

    private var state: TreadmillConnectionState = .idle
    private var hasControl = false
    private var isRunning = false
    private var targetSpeedKmh: Double = 0
    private var currentSpeedKmh: Double = 0
    private var currentInclinePercent: Double = 0
    private var distanceKm: Double = 0
    private var elapsedSeconds: Int = 0
    private var totalKcal: Double = 0
    private var tickTask: Task<Void, Never>?

    public nonisolated var currentConnectionState: TreadmillConnectionState {
        get async { await state }
    }

    // MARK: - Init

    public init(
        acceleration: Double = MockBLEManager.defaultAcceleration,
        tickInterval: Duration = .milliseconds(500),
        simulatedDevices: [DiscoveredDevice] = MockBLEManager.defaultDevices,
        userWeightKg: Double = 75.0,
    ) {
        let conPair = AsyncStream<TreadmillConnectionState>.makeStream(
            bufferingPolicy: .bufferingNewest(16),
        )
        let dataPair = AsyncStream<TreadmillData>.makeStream(
            bufferingPolicy: .bufferingNewest(16),
        )
        let devPair = AsyncStream<DiscoveredDevice>.makeStream(
            bufferingPolicy: .unbounded,
        )
        connectionStateStream = conPair.stream
        connectionContinuation = conPair.continuation
        treadmillDataStream = dataPair.stream
        dataContinuation = dataPair.continuation
        discoveredDevicesStream = devPair.stream
        devicesContinuation = devPair.continuation

        self.acceleration = acceleration
        self.tickInterval = tickInterval
        self.simulatedDevices = simulatedDevices
        self.userWeightKg = userWeightKg
    }

    public static let defaultDevices: [DiscoveredDevice] = [
        DiscoveredDevice(
            id: "00000000-0000-0000-0000-0000000000A1",
            name: "PORTENTUM 8 Pro (Mock)",
            rssi: -55,
            advertisesFTMS: true,
        ),
    ]

    // MARK: - Lifecycle

    public func startScanning() async throws(TreadmillError) {
        transition(to: .scanning)
        for device in simulatedDevices {
            devicesContinuation.yield(device)
        }
    }

    public func stopScanning() async {
        if case .scanning = state {
            transition(to: .idle)
        }
    }

    public func connect(to deviceID: String) async throws(TreadmillError) {
        guard simulatedDevices.contains(where: { $0.id == deviceID }) else {
            throw .deviceNotFound
        }
        transition(to: .connecting(deviceID: deviceID))
        // Simule la latence BLE : 150 ms
        try? await Task.sleep(for: .milliseconds(150))
        transition(to: .connected(deviceID: deviceID))
    }

    public func disconnect() async {
        tickTask?.cancel()
        tickTask = nil
        hasControl = false
        isRunning = false
        resetPhysics()
        transition(to: .disconnected)
    }

    // MARK: - FTMS Commands

    public func requestControl() async throws(TreadmillError) {
        try ensureConnected()
        hasControl = true
    }

    public func start() async throws(TreadmillError) {
        try ensureControl()
        guard !isRunning else { return }
        isRunning = true
        startTicking()
    }

    public func stop() async throws(TreadmillError) {
        try ensureControl()
        isRunning = false
        tickTask?.cancel()
        tickTask = nil
        targetSpeedKmh = 0
        currentSpeedKmh = 0
        emitSnapshot()
    }

    public func pause() async throws(TreadmillError) {
        try ensureControl()
        isRunning = false
        tickTask?.cancel()
        tickTask = nil
        targetSpeedKmh = 0
        emitSnapshot()
    }

    public func reset() async throws(TreadmillError) {
        try ensureControl()
        isRunning = false
        tickTask?.cancel()
        tickTask = nil
        resetPhysics()
        emitSnapshot()
    }

    public func setTargetSpeed(kmh: Double) async throws(TreadmillError) {
        try ensureControl()
        let range = SpeedRange.portentum8Pro
        guard kmh >= range.minKmh, kmh <= range.maxKmh else {
            throw .invalidSpeed(requested: kmh, min: range.minKmh, max: range.maxKmh)
        }
        targetSpeedKmh = kmh
    }

    public func setTargetInclination(percent: Double) async throws(TreadmillError) {
        try ensureControl()
        guard percent >= 0, percent <= 15 else {
            throw .invalidInclination(requested: percent)
        }
        currentInclinePercent = percent
    }

    // MARK: - Test helpers (emit manuellement un state ou data)

    /// Utile en tests : injecter un état arbitraire (ex. `.failed`) pour tester l'UI.
    public func emitStateForTesting(_ newState: TreadmillConnectionState) {
        transition(to: newState)
    }

    /// Utile en tests : injecter une donnée arbitraire.
    public func emitDataForTesting(_ data: TreadmillData) {
        dataContinuation.yield(data)
    }

    // MARK: - Private

    private func ensureConnected() throws(TreadmillError) {
        if case .connected = state { return }
        throw .notConnected
    }

    private func ensureControl() throws(TreadmillError) {
        try ensureConnected()
        guard hasControl else { throw .controlNotGranted }
    }

    private func transition(to newState: TreadmillConnectionState) {
        state = newState
        connectionContinuation.yield(newState)
    }

    private func resetPhysics() {
        targetSpeedKmh = 0
        currentSpeedKmh = 0
        distanceKm = 0
        elapsedSeconds = 0
        totalKcal = 0
        currentInclinePercent = 0
    }

    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [tickInterval] in
            while !Task.isCancelled {
                await self.tick()
                try? await Task.sleep(for: tickInterval)
            }
        }
    }

    private func tick() async {
        guard isRunning else { return }
        let dtSec = Double(tickInterval.components.seconds)
            + Double(tickInterval.components.attoseconds) / 1e18

        stepPhysics(dtSec: dtSec)
        emitSnapshot()
    }

    /// Un pas de physique :
    /// - accélération linéaire vers la cible
    /// - intégration distance
    /// - estimation calories MET (marche ~3 MET à 3 km/h, ~5 à 5 km/h)
    private func stepPhysics(dtSec: Double) {
        let delta = targetSpeedKmh - currentSpeedKmh
        let maxStep = acceleration * dtSec
        if abs(delta) <= maxStep {
            currentSpeedKmh = targetSpeedKmh
        } else {
            currentSpeedKmh += delta > 0 ? maxStep : -maxStep
        }

        let distanceDeltaKm = currentSpeedKmh * dtSec / 3600
        distanceKm += distanceDeltaKm
        elapsedSeconds += Int(dtSec.rounded())

        // MET approximatif : 0.6 × speed (km/h) — grossier, affiné au Sprint 2
        let met = max(1.0, 0.6 * currentSpeedKmh) * (1.0 + currentInclinePercent / 100)
        let hours = dtSec / 3600
        let kcalDelta = met * userWeightKg * hours
        totalKcal += kcalDelta
    }

    private func emitSnapshot() {
        let snapshot = TreadmillData(
            speedKmh: currentSpeedKmh,
            distanceKm: distanceKm,
            elapsedTimeSeconds: elapsedSeconds,
            totalEnergyKcal: totalKcal,
            inclinationPercent: currentInclinePercent,
            heartRate: nil,
            timestamp: Date(),
        )
        dataContinuation.yield(snapshot)
    }
}
