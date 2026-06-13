import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID = UUID()
    var name: String = ""
    var glyph: String = "·"
    var colorHex: String = "5A7A6E"
    var kindRaw: String = TransactionKind.expense.rawValue
    var isDefault: Bool = false
    var sortIndex: Int = 0
    var archived: Bool = false

    init(
        id: UUID = UUID(),
        name: String = "",
        glyph: String = "·",
        colorHex: String = "5A7A6E",
        kind: TransactionKind = .expense,
        isDefault: Bool = false,
        sortIndex: Int = 0,
        archived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.glyph = glyph
        self.colorHex = colorHex
        self.kindRaw = kind.rawValue
        self.isDefault = isDefault
        self.sortIndex = sortIndex
        self.archived = archived
    }

    var kind: TransactionKind { TransactionKind(rawValue: kindRaw) ?? .expense }
}
