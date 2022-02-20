import Combine
import Foundation
import SwiftDate
import Swinject

protocol FetchStatsManager {}

final class BaseFetchStatsManager: FetchStatsManager, Injectable {
    private let processQueue = DispatchQueue(label: "BaseFetchStatsManager.processQueue")
    @Injected() var nightscoutManager: NightscoutManager!
    @Injected() private var storage: FileStorage!

    private var lifetime = Lifetime()
    private let timer = DispatchTimer(timeInterval: 60.minutes.timeInterval)

    init(resolver: Resolver) {
        injectServices(resolver)
        subscribe()
    }

    private func subscribe() {
        timer.publisher
            .receive(on: processQueue)
            .flatMap { _ -> AnyPublisher<NSHistoryStats, Never> in
                debug(.nightscout, "FetchStatsManager heartbeat")
                debug(.nightscout, "Start fetching stats")
                return
                    self.nightscoutManager.fetchStats()
                // ).eraseToAnyPublisher()
            }
            .sink { stats in
                debug(.nightscout, "\(stats)")
                if let tdd = stats.tdd, tdd.avg > 0 {
                    self.storage.save(stats, as: OpenAPS.NSHistory.stats)
                }
            }
            .store(in: &lifetime)
        timer.fire()
        timer.resume()
    }
}
