import Foundation
import SwiftData

// Persisted snapshot of the latest known rates.
// Kept as a single-row table; latest snapshot wins.
@Model
final class RateSnapshot {
    var id: UUID = UUID()
    var capturedAt: Date = Date()
    var bcv: Double = 0
    var paralela: Double = 0
    var paralelaPrev: Double = 0
    var spreadPrevPct: Double = 0

    init(
        id: UUID = UUID(),
        capturedAt: Date = .now,
        bcv: Double,
        paralela: Double,
        paralelaPrev: Double,
        spreadPrevPct: Double
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.bcv = bcv
        self.paralela = paralela
        self.paralelaPrev = paralelaPrev
        self.spreadPrevPct = spreadPrevPct
    }
}

// Plain-data snapshot used by the UI (decoupled from SwiftData).
struct ExchangeRates {
    var bcv: Double
    var paralela: Double
    var paralelaPrev: Double
    var spreadPrevPct: Double
    var date: String

    static let placeholder = ExchangeRates(
        bcv: 40.20, paralela: 41.85, paralelaPrev: 41.60,
        spreadPrevPct: 0.3, date: "—"
    )
}
