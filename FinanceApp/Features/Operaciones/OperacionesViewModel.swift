import Foundation
import Observation

@Observable
final class OperacionesViewModel {
    private let engine: VaultEngine

    enum LoteItem: Identifiable {
        case usdt(USDTLot)
        case ves(VESLot)

        var id: String {
            switch self {
            case .usdt(let l): "u\(l.id.uuidString)"
            case .ves(let l):  "v\(l.id.uuidString)"
            }
        }
        var date: Date {
            switch self {
            case .usdt(let l): l.date
            case .ves(let l):  l.date
            }
        }
    }

    var sortedLotes: [LoteItem] {
        let all: [LoteItem] =
            engine.usdtLots.map { .usdt($0) } +
            engine.vesLots.map  { .ves($0) }
        return all.sorted { $0.date > $1.date }
    }

    init(engine: VaultEngine) {
        self.engine = engine
    }
}
