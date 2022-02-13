import SwiftUI
import Swinject

extension Bolus {
    final class StateModel: BaseStateModel<Provider> {
        @Injected() var unlockmanager: UnlockManager!
        @Injected() var apsManager: APSManager!
        @Injected() var broadcaster: Broadcaster!
        @Injected() var pumpHistotyStorage: PumpHistoryStorage!
        @Published var amount: Decimal = 0
        @Published var insulinRecommended: Decimal = 0
        @Published var insulinRequired: Decimal = 0
        @Published var waitForSuggestion: Bool = false
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
                            self.insulinRequired = 0
                            self.insulinRecommended = 0
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

        func setupInsulinRequired() {
            DispatchQueue.main.async {
                self.insulinRequired = self.provider.suggestion?.insulinReq ?? 0
                self.insulinRecommended = self.apsManager
                    .roundBolus(amount: max(self.insulinRequired * self.settingsManager.settings.insulinReqFraction, 0))
                self.amount = self.insulinRecommended
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
