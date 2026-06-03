import Foundation

// Full traceability tree for a single Gasto.
// Walks back: Gasto → VES allocations → VES lots → USDT allocations → USDT lots.
struct GastoTrace {
    struct VESLeg: Identifiable {
        let id: UUID
        let vesLot: VESLot
        let vesAmount: Double           // VES taken from this lot
        let usdCost: Double             // USD this slice cost
        let usdtLegs: [USDTLeg]         // the USDT lots that originally fed this VES lot, prorated
    }

    struct USDTLeg: Identifiable {
        let id: UUID
        let usdtLot: USDTLot
        let usdtAmount: Double          // USDT (prorated share) feeding this VES leg
        let usdAmount: Double           // USD that share originally cost
    }

    let gasto: Gasto
    let vesLegs: [VESLeg]
    let totalUsdCost: Double
    let effRate: Double
    let paralela: Double
    let diffVsParalela: Double          // realUsd − (ves/paralela). Negative = cheaper than paralela.
}
