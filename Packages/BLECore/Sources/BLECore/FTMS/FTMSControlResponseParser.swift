// WalkForge — BLECore
// Agent-BLE: parser des réponses (opcode 0x80) du Control Point.

import DomainKit
import Foundation

/// Réponse décodée du Control Point.
///
/// Chaque écriture sur `0x2AD9` est acquittée par une indication de la forme :
/// `[0x80, request_opcode, result_code, (operand?)]`.
public struct FTMSControlResponse: Sendable, Equatable, Hashable {
    /// Opcode qui avait été demandé (echo).
    public let requestOpcode: UInt8

    /// Code de résultat.
    public let resultCode: FTMSResultCode

    public init(requestOpcode: UInt8, resultCode: FTMSResultCode) {
        self.requestOpcode = requestOpcode
        self.resultCode = resultCode
    }
}

/// Parser des réponses du Control Point.
public enum FTMSControlResponseParser {
    /// Décode une indication reçue sur le Control Point.
    ///
    /// - Throws: `TreadmillError.ftmsParseError` si la trame ne correspond pas
    ///   à une réponse valide (opcode `0x80` attendu).
    public static func parse(_ data: Data) throws(TreadmillError) -> FTMSControlResponse {
        guard data.count >= 3 else {
            throw .ftmsParseError(reason: "Réponse trop courte (\(data.count) octets, attendu ≥ 3)")
        }

        let base = data.startIndex
        let responseOpcode = data[base]
        guard responseOpcode == FTMSOpCode.responseCode.rawValue else {
            throw .ftmsParseError(
                reason: "Opcode de réponse invalide : "
                    + String(format: "0x%02X (attendu 0x80)", responseOpcode),
            )
        }

        let requestOpcode = data[base + 1]
        let rawResult = data[base + 2]
        guard let result = FTMSResultCode(rawValue: rawResult) else {
            throw .ftmsParseError(
                reason: "Result code inconnu : "
                    + String(format: "0x%02X", rawResult),
            )
        }

        return FTMSControlResponse(requestOpcode: requestOpcode, resultCode: result)
    }
}
