// WalkForge — BLECore
// Agent-BLE: constantes du protocole FTMS (Fitness Machine Service).
// Référence : Bluetooth SIG "FTMS" spec.

import CoreBluetooth
import Foundation

/// UUIDs 16 bits du service et des caractéristiques FTMS.
///
/// `CBUUID` n'est pas `Sendable` dans le SDK Apple, mais les instances sont
/// immuables après construction (NSCopying, thread-safe en pratique). On les
/// expose en `nonisolated(unsafe) let` : c'est le pattern canonique documenté
/// par Apple pour les constantes Obj-C non-Sendable.
public enum FTMSUUID {
    /// Service FTMS : `0x1826`.
    public nonisolated(unsafe) static let service: CBUUID = .init(string: "1826")

    /// Fitness Machine Feature (Read) : `0x2ACC`.
    public nonisolated(unsafe) static let fitnessMachineFeature: CBUUID = .init(string: "2ACC")

    /// Treadmill Data (Notify) : `0x2ACD`.
    public nonisolated(unsafe) static let treadmillData: CBUUID = .init(string: "2ACD")

    /// Fitness Machine Control Point (Write + Indicate) : `0x2AD9`.
    public nonisolated(unsafe) static let controlPoint: CBUUID = .init(string: "2AD9")

    /// Fitness Machine Status (Notify) : `0x2ADA`.
    public nonisolated(unsafe) static let machineStatus: CBUUID = .init(string: "2ADA")
}

/// Opcodes du Fitness Machine Control Point (0x2AD9).
///
/// Source : Bluetooth SIG — *Fitness Machine Service*, section "Op Codes".
public enum FTMSOpCode: UInt8, Sendable, Equatable, Hashable {
    case requestControl = 0x00
    case reset = 0x01
    case setTargetSpeed = 0x02
    case setTargetInclination = 0x03
    case startOrResume = 0x07
    case stopOrPause = 0x08
    case responseCode = 0x80
}

/// Result codes d'une réponse (opcode `0x80`) du Control Point.
public enum FTMSResultCode: UInt8, Sendable, Equatable, Hashable {
    case success = 0x01
    case opCodeNotSupported = 0x02
    case invalidParameter = 0x03
    case operationFailed = 0x04
    case controlNotPermitted = 0x05
}

/// Operand du `Stop or Pause` (opcode `0x08`).
public enum FTMSStopOrPauseOperand: UInt8, Sendable {
    case stop = 0x01
    case pause = 0x02
}

/// Flags (uint16 LE) du champ `Treadmill Data` (`0x2ACD`).
///
/// Chaque bit indique la présence d'un champ optionnel dans la payload.
/// Le bit 0 est particulier : il signale la *présence* ou non de
/// `Instantaneous Speed` (`0` = présent, `1` = absent car "More Data" suit).
public enum FTMSTreadmillDataFlag: UInt16, Sendable {
    case moreData = 0x0001
    case averageSpeed = 0x0002
    case totalDistance = 0x0004
    case inclinationAndRampAngle = 0x0008
    case elevationGain = 0x0010
    case instantaneousPace = 0x0020
    case averagePace = 0x0040
    case expendedEnergy = 0x0080
    case heartRate = 0x0100
    case metabolicEquivalent = 0x0200
    case elapsedTime = 0x0400
    case remainingTime = 0x0800
    case forceOnBeltAndPowerOutput = 0x1000
}
