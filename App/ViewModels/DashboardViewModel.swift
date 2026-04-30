// WalkForge — App
// Agent-Session: ViewModel Observable du dashboard live.

import DomainKit
import Foundation
import Observation
import os

/// ViewModel du dashboard live (Swift 6.2 `@Observable`).
///
/// Responsabilités :
/// - S'abonner aux streams `connectionStateStream` + `treadmillDataStream`
///   du `BLETreadmillServiceProtocol`.
/// - Exposer l'état courant aux Views (SwiftUI réagit aux changements
///   via le framework Observation).
/// - Déléguer les actions utilisateur (start, stop, set speed, set incline)
///   aux use cases du DomainKit.
///
/// - Note : isolé `@MainActor` car il nourrit l'UI. Les Tasks d'abonnement
///   s'exécutent sur le même actor.
@MainActor
@Observable
public final class DashboardViewModel {
    // MARK: - Published state (@Observable)

    public private(set) var connectionState: TreadmillConnectionState = .idle
    public private(set) var lastData: TreadmillData = .idle
    public private(set) var discoveredDevices: [DiscoveredDevice] = []
    public private(set) var isSessionActive = false
    public private(set) var errorMessage: String?

    /// Vitesse cible actuellement demandée par l'utilisateur (slider).
    public var targetSpeedKmh: Double = 3.0

    /// Niveau d'inclinaison demandé.
    public var inclineLevel: InclineLevel = .flat

    /// Vitesse instantanée du tapis (dernière mesure BLE).
    public var instantaneousSpeedKmh: Double {
        lastData.speedKmh
    }

    /// Distance parcourue (dernière mesure).
    public var distanceKm: Double {
        lastData.distanceKm
    }

    /// Durée écoulée.
    public var elapsedSeconds: Int {
        lastData.elapsedTimeSeconds
    }

    /// Calories estimées (dernière mesure — estimation tapis ou calcul domaine).
    public var caloriesKcal: Double {
        lastData.totalEnergyKcal ?? 0
    }

    /// Est-ce que les contrôles peuvent être utilisés ? (= connecté)
    public var canControl: Bool {
        if case .connected = connectionState { return true }
        return false
    }

    // MARK: - Dependencies

    private let bleService: any BLETreadmillServiceProtocol
    private let healthKitService: (any HealthKitServiceProtocol)?
    private let startSession: StartSessionUseCase
    private let stopSession: StopSessionUseCase
    private let setSpeed: SetTargetSpeedUseCase
    private let setIncline: SetInclineUseCase
    private let persistSession: PersistSessionUseCase?
    private let motorRestAlert: MotorRestAlertUseCase?
    private var history: [TreadmillData] = []
    private var sessionStartDate: Date?
    private var motorRestAlreadyFired = false

    private let logger = Logger(subsystem: "com.samuel.walkforge", category: "Dashboard")

    // MARK: - Init

    public init(
        bleService: any BLETreadmillServiceProtocol,
        workoutRepository: (any WorkoutSessionRepository)? = nil,
        notificationService: (any NotificationServiceProtocol)? = nil,
        healthKitService: (any HealthKitServiceProtocol)? = nil,
    ) {
        self.bleService = bleService
        self.healthKitService = healthKitService
        startSession = StartSessionUseCase(bleService: bleService)
        stopSession = StopSessionUseCase(bleService: bleService)
        setSpeed = SetTargetSpeedUseCase(bleService: bleService)
        setIncline = SetInclineUseCase(bleService: bleService)
        persistSession = workoutRepository.map { PersistSessionUseCase(repository: $0) }
        motorRestAlert = notificationService.map { MotorRestAlertUseCase(notificationService: $0) }
    }

    // MARK: - Lifecycle

    /// À appeler en `task {}` dans la View d'accueil.
    ///
    /// Utilise `async let` plutôt qu'un `TaskGroup` pour éviter les frictions
    /// Swift 6 strict concurrency avec les closures @Sendable sur un type
    /// @MainActor. Les 3 streams tournent en parallèle sur le MainActor et
    /// le `await` tuple à la fin attend que le caller soit annulé.
    public func subscribeToStreams() async {
        async let connection: Void = consumeConnectionStream()
        async let data: Void = consumeDataStream()
        async let devices: Void = consumeDevicesStream()
        _ = await (connection, data, devices)
    }

    private func consumeConnectionStream() async {
        for await state in bleService.connectionStateStream {
            connectionState = state
        }
    }

    private func consumeDataStream() async {
        for await data in bleService.treadmillDataStream {
            lastData = data
            history.append(data)
            if history.count > 1000 {
                history.removeFirst(history.count - 1000)
            }
            await checkMotorRestAlert(elapsedSeconds: data.elapsedTimeSeconds)
        }
    }

    private func checkMotorRestAlert(elapsedSeconds: Int) async {
        guard let motorRestAlert, isSessionActive else { return }
        do {
            let fired = try await motorRestAlert.evaluate(
                elapsedSeconds: elapsedSeconds,
                alreadyAlerted: motorRestAlreadyFired,
            )
            if fired { motorRestAlreadyFired = true }
        } catch {
            logger.error("Motor rest alert failed: \(String(describing: error), privacy: .public)")
        }
    }

    private func consumeDevicesStream() async {
        for await device in bleService.discoveredDevicesStream {
            if !discoveredDevices.contains(where: { $0.id == device.id }) {
                discoveredDevices.append(device)
            }
        }
    }

    // MARK: - User actions

    public func startScanning() async {
        await runAction { () throws(TreadmillError) in
            try await self.bleService.startScanning()
        }
    }

    public func connect(to device: DiscoveredDevice) async {
        await runAction { () throws(TreadmillError) in
            try await self.bleService.connect(to: device.id)
        }
    }

    public func toggleSession() async {
        if isSessionActive {
            await stopCurrentSession()
        } else {
            await startCurrentSession()
        }
    }

    public func applyTargetSpeed() async {
        await runAction { () throws(TreadmillError) in
            _ = try await self.setSpeed.execute(kmh: self.targetSpeedKmh)
        }
    }

    public func applyIncline(_ level: InclineLevel) async {
        inclineLevel = level
        await runAction { () throws(TreadmillError) in
            try await self.setIncline.execute(level: level)
        }
    }

    // MARK: - Private

    private func startCurrentSession() async {
        history.removeAll()
        motorRestAlreadyFired = false
        sessionStartDate = Date()
        await runAction { () throws(TreadmillError) in
            try await self.startSession.execute()
        }
        if errorMessage == nil {
            isSessionActive = true
            await applyTargetSpeed()
        }
    }

    private func stopCurrentSession() async {
        let last = lastData
        let snap = history
        let start = sessionStartDate ?? Date()
        let incline = inclineLevel.rawValue

        // 1. Arrêt + calcul résumé (via use case)
        var summary: SessionSummary?
        do {
            let result = try await stopSession.execute(lastSnapshot: last, history: snap)
            summary = result
            errorMessage = nil
        } catch {
            errorMessage = error.description
            logger.error("Stop session failed: \(String(describing: error), privacy: .public)")
        }

        // 2. Persistance (optionnelle, best-effort)
        var persistedDTO: WorkoutSessionDTO?
        if let persistSession, let summary {
            do {
                persistedDTO = try await persistSession.execute(
                    summary: summary,
                    startDate: start,
                    inclineLevel: incline,
                )
            } catch {
                logger.error("Persist session failed: \(String(describing: error), privacy: .public)")
            }
        }

        // 3. Export HealthKit (best-effort, n'échoue pas le flux)
        if let healthKitService, let dto = persistedDTO {
            do {
                _ = try await healthKitService.exportWorkout(dto)
            } catch {
                logger.error("HK export failed: \(String(describing: error), privacy: .public)")
            }
        }

        isSessionActive = false
        sessionStartDate = nil
    }

    private func runAction(_ block: () async throws(TreadmillError) -> Void) async {
        do {
            try await block()
            errorMessage = nil
        } catch {
            errorMessage = error.description
            logger.error("Action échouée: \(String(describing: error), privacy: .public)")
        }
    }
}
