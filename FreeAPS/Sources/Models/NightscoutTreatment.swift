import Foundation
import UIKit

struct NigtscoutTreatment: JSON, Hashable, Equatable {
    var duration: Int?
    var rawDuration: PumpHistoryEvent?
    var rawRate: PumpHistoryEvent?
    var absolute: Decimal?
    var rate: Decimal?
    var eventType: EventType
    var createdAt: Date?
    var enteredBy: String?
    var bolus: PumpHistoryEvent?
    var insulin: Decimal?
    var notes: String?
    var carbs: Decimal?
    let targetTop: Decimal?
    let targetBottom: Decimal?
    var glucoseType: String? = nil
    var units: String? = nil
    var glucose: Decimal? = nil

    static let local = "freeaps-x://" + UIDevice.current.name

    static let empty = NigtscoutTreatment(from: "{}")!

    static func == (lhs: NigtscoutTreatment, rhs: NigtscoutTreatment) -> Bool {
        (lhs.createdAt ?? Date()) == (rhs.createdAt ?? Date())
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt ?? Date())
    }
}

extension NigtscoutTreatment {
    private enum CodingKeys: String, CodingKey {
        case duration
        case rawDuration = "raw_duration"
        case rawRate = "raw_rate"
        case absolute
        case rate
        case eventType
        case createdAt = "created_at"
        case enteredBy
        case bolus
        case insulin
        case notes
        case carbs
        case targetTop
        case targetBottom
        case glucoseType
        case units
        case glucose
    }
}
