extension Bolus {
    final class Provider: BaseProvider, BolusProvider {
        var suggestion: Suggestion? {
            storage.retrieve(OpenAPS.Enact.suggested, as: Suggestion.self)
        }

        func pumpSettings() -> PumpSettings {
            storage.retrieve(OpenAPS.Settings.settings, as: PumpSettings.self)
                ?? PumpSettings(from: OpenAPS.defaults(for: OpenAPS.Settings.settings))
                ?? PumpSettings(insulinActionCurve: 5, maxBolus: 10, maxBasal: 2)
        }

        var carbRatios: CarbRatios {
            storage.retrieve(OpenAPS.Settings.carbRatios, as: CarbRatios.self)
                ?? CarbRatios(from: OpenAPS.defaults(for: OpenAPS.Settings.carbRatios))
                ?? CarbRatios(units: .grams, schedule: [])
        }
    }
}
