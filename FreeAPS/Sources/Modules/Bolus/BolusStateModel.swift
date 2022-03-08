import SwiftUI
import Swinject

private extension Decimal {
    func rounded(_ places: Int = 0) -> Decimal {
        var inp = self
        var res = Decimal()
        NSDecimalRound(&res, &inp, places, .plain)
        return res
    }
}

extension Bolus {
    final class StateModel: BaseStateModel<Provider> {
        @Injected() var unlockmanager: UnlockManager!
        @Injected() var apsManager: APSManager!
        @Injected() var broadcaster: Broadcaster!
        @Injected() var pumpHistotyStorage: PumpHistoryStorage!
        @Published var amount: Decimal = 0
        @Published var inslinRecommended: Decimal = 0
        @Published var inslinRequired: Decimal = 0
        @Published var waitForSuggestion: Bool = false
        @Published var carbsAdded: Decimal = 0
        @Published var carbsInsulinRequired: Decimal = 0
        @Published var carbsInsulinRecommended: Decimal = 0

        var waitForSuggestionInitial: Bool = false

        override func subscribe() {
            setupInsulinRequired()
            broadcaster.register(SuggestionObserver.self, observer: self)

            if waitForSuggestionInitial {
                apsManager.determineBasal()
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] ok in
                        guard let self = self else { return }
                        if !ok {
                            self.waitForSuggestion = false
                            self.inslinRequired = 0
                            self.inslinRecommended = 0
                        }
                    }.store(in: &lifetime)
            }
        }

        func add() {
            guard amount > 0 else {
                showModal(for: nil)
                return
            }

            let maxAmount = Double(min(amount, provider.pumpSettings().maxBolus))

            apsManager.enactBolus(amount: maxAmount, isSMB: false)
            showModal(for: nil)
        }

        func addWithoutBolus() {
            guard amount > 0 else {
                showModal(for: nil)
                return
            }

            pumpHistotyStorage.storeEvents(
                [
                    PumpHistoryEvent(
                        id: UUID().uuidString,
                        type: .bolus,
                        timestamp: Date(),
                        amount: amount,
                        duration: nil,
                        durationMin: nil,
                        rate: nil,
                        temp: nil,
                        carbInput: nil
                    )
                ]
            )
            showModal(for: nil)
        }

        func roundInsulin(_ insulin: Decimal) -> Decimal {
            insulin.rounded(1)
        }

        func carbRequired() -> Decimal {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            let now = dateFormatter.string(from: Date())
            var ratio: Decimal = 0
            for cr in provider.carbRatios.schedule {
                if cr.start <= now {
                    ratio = cr.ratio
                }
            }
            if ratio <= 0 {
                return 0
            }
            let req = roundInsulin(carbsAdded / ratio)
            NSLog("carbRequired Now \(now) \(ratio) \(req)")
            return max(0, req)
        }

        func carbRecommended(_ required: Decimal) -> Decimal? {
            if carbsAdded <= 0 {
                return nil
            }
            let iob = provider.suggestion?.iob ?? 0
            // Safety values should be configurable
            if let bg = provider.suggestion?.bg, bg < 70 {
                return nil
            }
            // The ratio should be configurable
            // The logic here is that we trust any carbs entered to be
            // somewhat correct. We err on the side of caution, substract iob, no matter the cob
            // (so this will always underpredict).
            // The target use case is aggressive pre-bolus for big meals with low bg.
            let recommendation = max(0, 0.7 * (required - iob))
            NSLog("carbRecommended Now \(iob) \(required) \(recommendation)")
            return roundInsulin(recommendation)
        }

        func setupInsulinRequired() {
            DispatchQueue.main.async {
                self.carbsInsulinRequired = self.carbRequired()
                self.carbsInsulinRecommended = self.carbRecommended(self.carbsInsulinRequired) ?? 0
                var orefRecommended: Decimal = 0
                var orefRequired: Decimal = 0
                if let suggestion = self.provider.suggestion, let timestamp = suggestion.timestamp {
                    if timestamp.timeIntervalSinceNow > 5.minutes.timeInterval {
                        orefRequired = self.roundInsulin(suggestion.insulinReq ?? 0)
                        orefRecommended = self
                            .roundInsulin(max(orefRequired * self.settingsManager.settings.insulinReqFraction, 0))
                    } else {
                        NSLog("setupInsulinRequired: Suggestion too old \(timestamp)")
                    }
                }

                self.inslinRequired = orefRequired

                NSLog("Oref Recommended \(orefRecommended) U carbsInsulinRecommended \(self.carbsInsulinRecommended) U")
                self.inslinRecommended = self.roundInsulin(max(
                    orefRecommended,
                    self.carbsInsulinRecommended
                ))
                self.amount = self.inslinRecommended
            }
        }
    }
}

extension Bolus.StateModel: SuggestionObserver {
    func suggestionDidUpdate(_: Suggestion) {
        DispatchQueue.main.async {
            self.waitForSuggestion = false
        }
        setupInsulinRequired()
    }
}
