// WalkForge — BLECore
// Agent-BLE: implémentation CoreBluetooth du protocole BLETreadmillServiceProtocol.
// Pattern @unchecked Sendable : tout l'état mutable est protégé par la DispatchQueue
// dédiée (single-writer). Les AsyncStream.Continuation sont thread-safe par design.

@preconcurrency import CoreBluetooth
import DomainKit
import Foundation
import os

/// Implémentation de production utilisant `CoreBluetooth`.
///
/// - Important : tous les états mutables (`_state`, `discovered`, `connected`…)
///   ne doivent être lus/écrits **que** depuis `queue`. Les méthodes publiques
///   `async` font un hop vers cette queue via `withCheckedContinuation`.
public final class BLEManager: NSObject, BLETreadmillServiceProtocol, @unchecked Sendable {
    // MARK: - Streams publics

    public let connectionStateStream: AsyncStream<TreadmillConnectionState>
    public let treadmillDataStream: AsyncStream<TreadmillData>
    public let discoveredDevicesStream: AsyncStream<DiscoveredDevice>

    // MARK: - État interne (queue-protected)

    private nonisolated(unsafe) var connectionContinuation:
        AsyncStream<TreadmillConnectionState>.Continuation
    private nonisolated(unsafe) var dataContinuation:
        AsyncStream<TreadmillData>.Continuation
    private nonisolated(unsafe) var devicesContinuation:
        AsyncStream<DiscoveredDevice>.Continuation

    private let queue = DispatchQueue(
        label: "com.samuel.walkforge.ble.central",
        qos: .userInitiated,
    )
    private nonisolated(unsafe) var centralManager: CBCentralManager?

    private nonisolated(unsafe) var state: TreadmillConnectionState = .unsupported
    private nonisolated(unsafe) var discovered: [UUID: (peripheral: CBPeripheral, rssi: Int)] = [:]
    private nonisolated(unsafe) var connectedPeripheral: CBPeripheral?
    private nonisolated(unsafe) var controlPointCharacteristic: CBCharacteristic?
    private nonisolated(unsafe) var treadmillDataCharacteristic: CBCharacteristic?

    private let logger = Logger(subsystem: "com.samuel.walkforge", category: "BLEManager")

    // MARK: - Init

    override public init() {
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
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: queue, options: nil)
    }

    // MARK: - BLETreadmillServiceProtocol — snapshot

    public var currentConnectionState: TreadmillConnectionState {
        get async {
            await withCheckedContinuation { cont in
                queue.async { cont.resume(returning: self.state) }
            }
        }
    }

    // MARK: - BLETreadmillServiceProtocol — lifecycle

    public func startScanning() async throws(TreadmillError) {
        try await runOnQueue { () throws(TreadmillError) in
            guard let central = self.centralManager else {
                throw .bluetoothUnavailable
            }
            switch central.state {
            case .poweredOn:
                break
            case .poweredOff:
                throw .bluetoothPoweredOff
            case .unauthorized:
                throw .bluetoothUnauthorized
            case .unsupported:
                throw .bluetoothUnavailable
            default:
                throw .bluetoothUnavailable
            }
            self.discovered.removeAll()
            central.scanForPeripherals(
                withServices: [FTMSUUID.service],
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: false],
            )
            self.transition(to: .scanning)
            self.logger.info("Scan FTMS démarré")
        }
    }

    public func stopScanning() async {
        await runOnQueueVoid {
            self.centralManager?.stopScan()
            if case .scanning = self.state {
                self.transition(to: .idle)
            }
            self.logger.info("Scan arrêté")
        }
    }

    public func connect(to deviceID: String) async throws(TreadmillError) {
        try await runOnQueue { () throws(TreadmillError) in
            guard let uuid = UUID(uuidString: deviceID),
                  let entry = self.discovered[uuid]
            else {
                throw .deviceNotFound
            }
            guard let central = self.centralManager else {
                throw .bluetoothUnavailable
            }
            central.stopScan()
            entry.peripheral.delegate = self
            self.transition(to: .connecting(deviceID: deviceID))
            central.connect(entry.peripheral, options: nil)
            self.logger.info("Connexion en cours: \(deviceID, privacy: .public)")
        }
    }

    public func disconnect() async {
        await runOnQueueVoid {
            guard let peripheral = self.connectedPeripheral else { return }
            self.transition(to: .disconnecting)
            self.centralManager?.cancelPeripheralConnection(peripheral)
        }
    }

    // MARK: - BLETreadmillServiceProtocol — FTMS commands

    public func requestControl() async throws(TreadmillError) {
        try await writeCommand(.requestControl)
    }

    public func start() async throws(TreadmillError) {
        try await writeCommand(.startOrResume)
    }

    public func stop() async throws(TreadmillError) {
        try await writeCommand(.stop)
    }

    public func pause() async throws(TreadmillError) {
        try await writeCommand(.pause)
    }

    public func reset() async throws(TreadmillError) {
        try await writeCommand(.reset)
    }

    public func setTargetSpeed(kmh: Double) async throws(TreadmillError) {
        try await writeCommand(.setTargetSpeed(kmh: kmh))
    }

    public func setTargetInclination(percent: Double) async throws(TreadmillError) {
        try await writeCommand(.setTargetInclination(percent: percent))
    }

    // MARK: - Écriture Control Point

    private func writeCommand(_ command: FTMSControlCommand) async throws(TreadmillError) {
        try await runOnQueue { () throws(TreadmillError) in
            guard let peripheral = self.connectedPeripheral,
                  let characteristic = self.controlPointCharacteristic
            else {
                throw .notConnected
            }
            peripheral.writeValue(command.encode(), for: characteristic, type: .withResponse)
            self.logger.debug("Commande FTMS envoyée: \(String(describing: command.opcode))")
        }
    }

    // MARK: - Transitions d'état

    /// - Important : doit être appelé depuis `queue`.
    private func transition(to newState: TreadmillConnectionState) {
        state = newState
        connectionContinuation.yield(newState)
    }

    // MARK: - Hop vers la queue

    private func runOnQueue<E: Error>(
        _ block: @escaping @Sendable () throws(E) -> Void,
    ) async throws(E) {
        let result: Result<Void, E> = await withCheckedContinuation { cont in
            queue.async {
                cont.resume(returning: Result(catching: block))
            }
        }
        try result.get()
    }

    private func runOnQueueVoid(_ block: @escaping @Sendable () -> Void) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            queue.async {
                block()
                cont.resume()
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            transition(to: .idle)
        case .poweredOff:
            transition(to: .poweredOff)
        case .unauthorized:
            transition(to: .unauthorized)
        case .unsupported:
            transition(to: .unsupported)
        case .resetting:
            transition(to: .idle)
        case .unknown:
            break
        @unknown default:
            break
        }
        logger.info("CB state update: \(central.state.rawValue)")
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi: NSNumber,
    ) {
        let identifier = peripheral.identifier
        let rssiInt = rssi.intValue
        discovered[identifier] = (peripheral, rssiInt)
        let device = DiscoveredDevice(
            id: identifier.uuidString,
            name: peripheral.name,
            rssi: rssiInt,
            advertisesFTMS: true,
        )
        devicesContinuation.yield(device)
    }

    public func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral,
    ) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices([FTMSUUID.service])
        logger.info("Connecté, découverte services…")
    }

    public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: (any Error)?,
    ) {
        let reason = error?.localizedDescription ?? "raison inconnue"
        transition(to: .failed(reason: reason))
        connectedPeripheral = nil
        controlPointCharacteristic = nil
        treadmillDataCharacteristic = nil
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)?,
    ) {
        connectedPeripheral = nil
        controlPointCharacteristic = nil
        treadmillDataCharacteristic = nil
        if let error {
            transition(to: .failed(reason: error.localizedDescription))
        } else {
            transition(to: .disconnected)
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEManager: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        if let error {
            logger.error("Erreur découverte services: \(error.localizedDescription)")
            return
        }
        for service in peripheral.services ?? [] where service.uuid == FTMSUUID.service {
            peripheral.discoverCharacteristics(
                [
                    FTMSUUID.treadmillData,
                    FTMSUUID.controlPoint,
                    FTMSUUID.machineStatus,
                    FTMSUUID.fitnessMachineFeature,
                ],
                for: service,
            )
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: (any Error)?,
    ) {
        if let error {
            logger.error("Erreur découverte chars: \(error.localizedDescription)")
            return
        }
        for characteristic in service.characteristics ?? [] {
            switch characteristic.uuid {
            case FTMSUUID.treadmillData:
                treadmillDataCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            case FTMSUUID.controlPoint:
                controlPointCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            case FTMSUUID.machineStatus:
                peripheral.setNotifyValue(true, for: characteristic)
            default:
                break
            }
        }
        if controlPointCharacteristic != nil, treadmillDataCharacteristic != nil {
            transition(to: .connected(deviceID: peripheral.identifier.uuidString))
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: (any Error)?,
    ) {
        guard let data = characteristic.value else { return }
        switch characteristic.uuid {
        case FTMSUUID.treadmillData:
            handleTreadmillData(data)
        case FTMSUUID.controlPoint:
            handleControlResponse(data)
        default:
            break
        }
    }

    private func handleTreadmillData(_ data: Data) {
        do {
            let parsed = try FTMSTreadmillDataParser.parse(data)
            dataContinuation.yield(parsed)
        } catch {
            logger.error("Parse Treadmill Data échoué: \(String(describing: error))")
        }
    }

    private func handleControlResponse(_ data: Data) {
        do {
            let response = try FTMSControlResponseParser.parse(data)
            let reqHex = String(format: "0x%02X", response.requestOpcode)
            let resultHex = String(format: "0x%02X", response.resultCode.rawValue)
            logger.debug("Réponse CP: req=\(reqHex, privacy: .public) result=\(resultHex, privacy: .public)")
        } catch {
            logger.error("Parse CP response échoué: \(String(describing: error))")
        }
    }
}
