// WalkForge — DomainKitTests
// Agent-Tests: mock minimal de BLETreadmillServiceProtocol utilisé par les
// tests de use cases. Actor isolé, enregistre les appels dans l'ordre.

@testable import DomainKit
import Foundation

/// Implémentation actor-isolée de `BLETreadmillServiceProtocol` pour tests.
///
/// Enregistre chaque appel dans `calls` (dans l'ordre). Permet d'injecter
/// une erreur à lever sur n'importe quelle méthode via `errorToThrow`.
actor RecordingBLEService: BLETreadmillServiceProtocol {
    enum Call: Equatable {
        case startScanning
        case stopScanning
        case connect(String)
        case disconnect
        case requestControl
        case start
        case stop
        case pause
        case reset
        case setTargetSpeed(Double)
        case setTargetInclination(Double)
    }

    nonisolated let connectionStateStream: AsyncStream<TreadmillConnectionState>
    nonisolated let treadmillDataStream: AsyncStream<TreadmillData>
    nonisolated let discoveredDevicesStream: AsyncStream<DiscoveredDevice>

    private let connectionContinuation: AsyncStream<TreadmillConnectionState>.Continuation
    private let dataContinuation: AsyncStream<TreadmillData>.Continuation
    private let devicesContinuation: AsyncStream<DiscoveredDevice>.Continuation

    var calls: [Call] = []
    var errorToThrow: TreadmillError?

    nonisolated var currentConnectionState: TreadmillConnectionState {
        get async { await state }
    }

    private var state: TreadmillConnectionState = .idle

    init() {
        let conPair = AsyncStream<TreadmillConnectionState>.makeStream()
        let dataPair = AsyncStream<TreadmillData>.makeStream()
        let devPair = AsyncStream<DiscoveredDevice>.makeStream()
        connectionStateStream = conPair.stream
        connectionContinuation = conPair.continuation
        treadmillDataStream = dataPair.stream
        dataContinuation = dataPair.continuation
        discoveredDevicesStream = devPair.stream
        devicesContinuation = devPair.continuation
    }

    func setError(_ error: TreadmillError?) {
        errorToThrow = error
    }

    func setState(_ newState: TreadmillConnectionState) {
        state = newState
        connectionContinuation.yield(newState)
    }

    func emitData(_ data: TreadmillData) {
        dataContinuation.yield(data)
    }

    // MARK: - Protocol

    func startScanning() async throws(TreadmillError) {
        calls.append(.startScanning)
        if let error = errorToThrow { throw error }
    }

    func stopScanning() async {
        calls.append(.stopScanning)
    }

    func connect(to deviceID: String) async throws(TreadmillError) {
        calls.append(.connect(deviceID))
        if let error = errorToThrow { throw error }
    }

    func disconnect() async {
        calls.append(.disconnect)
    }

    func requestControl() async throws(TreadmillError) {
        calls.append(.requestControl)
        if let error = errorToThrow { throw error }
    }

    func start() async throws(TreadmillError) {
        calls.append(.start)
        if let error = errorToThrow { throw error }
    }

    func stop() async throws(TreadmillError) {
        calls.append(.stop)
        if let error = errorToThrow { throw error }
    }

    func pause() async throws(TreadmillError) {
        calls.append(.pause)
        if let error = errorToThrow { throw error }
    }

    func reset() async throws(TreadmillError) {
        calls.append(.reset)
        if let error = errorToThrow { throw error }
    }

    func setTargetSpeed(kmh: Double) async throws(TreadmillError) {
        calls.append(.setTargetSpeed(kmh))
        if let error = errorToThrow { throw error }
    }

    func setTargetInclination(percent: Double) async throws(TreadmillError) {
        calls.append(.setTargetInclination(percent))
        if let error = errorToThrow { throw error }
    }
}
