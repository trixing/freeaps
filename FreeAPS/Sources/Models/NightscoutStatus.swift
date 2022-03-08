import Foundation

struct NightscoutStatus: JSON {
    let device: String
    let openaps: OpenAPSStatus
    let pump: NSPumpStatus
    let preferences: Preferences
    let uploader: Uploader
}

struct OpenAPSStatus: JSON {
    let iob: IOBEntry?
    let suggested: Suggestion?
    let enacted: Suggestion?
    let version: String
}

struct NSPumpStatus: JSON {
    let clock: Date
    let battery: Battery?
    let reservoir: Decimal?
    let status: PumpStatus?
}

struct Uploader: JSON {
    let batteryVoltage: Decimal?
    let battery: Int
}

struct NightscoutTimevalue: JSON {
    // rep["time"] = String(format:"%02i:%02i", Int(hours), Int(minutes))
    // rep["value"] = value
    //  rep["timeAsSeconds"] = Int(offset)
    let time: String
    let value: Decimal
    let timeAsSeconds: Int
}

extension NightscoutTimevalue {
    func equals(_ other: NightscoutTimevalue) -> Bool {
        other.time == time && (abs(other.value - value) < 0.001) && other.timeAsSeconds == timeAsSeconds
    }
}

struct ScheduledNightscoutProfile: JSON {
    let dia: Decimal
    let carbs_hr: Decimal
    let delay: Decimal
    let timezone: String
    let target_low: [NightscoutTimevalue]
    let target_high: [NightscoutTimevalue]
    let sens: [NightscoutTimevalue]
    let basal: [NightscoutTimevalue]
    let carbratio: [NightscoutTimevalue]
    let units: String
}

extension ScheduledNightscoutProfile {
    func equal_timevalues(_ a: [NightscoutTimevalue], _ b: [NightscoutTimevalue]) -> Bool {
        if a.count != b.count {
            return false
        }
        for (i, v) in a.enumerated() {
            if !v.equals(b[i]) {
                return false
            }
        }
        return true
    }

    func equals(_ other: ScheduledNightscoutProfile) -> Bool {
        let basic = other.dia == dia && other.carbs_hr == carbs_hr && other.delay == delay && other.timezone == timezone && other
            .units == units
        let adv = (
            equal_timevalues(target_low, other.target_low) &&
                equal_timevalues(target_high, other.target_high) &&
                equal_timevalues(sens, other.sens) &&
                equal_timevalues(basal, other.basal) &&
                equal_timevalues(carbratio, other.carbratio)
        )
        return basic && adv
    }
}

struct NightscoutProfileStore: JSON {
    let defaultProfile: String
    let startDate: Date
    let mills: Int
    let units: String
    let enteredBy: String
    let store: [String: ScheduledNightscoutProfile]
}
