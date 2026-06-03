import Foundation
import Observation

@Observable
final class GastosViewModel {
    private let engine: VaultEngine

    var expandedGastoId: UUID? = nil

    var gastos: [Gasto] { engine.gastos }

    init(engine: VaultEngine) {
        self.engine = engine
    }

    func trace(for gasto: Gasto) -> GastoTrace {
        engine.trace(gasto)
    }

    func toggleExpand(_ id: UUID) {
        expandedGastoId = expandedGastoId == id ? nil : id
    }
}
