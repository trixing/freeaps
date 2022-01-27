import SwiftUI
import Swinject

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

        func setupInsulinRequired() {
            DispatchQueue.main.async {
                self.inslinRequired = self.provider.suggestion?.insulinReq ?? 0
                self.inslinRecommended = self.apsManager
                    .roundBolus(amount: max(self.inslinRequired * self.settingsManager.settings.insulinReqFraction, 0))
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
