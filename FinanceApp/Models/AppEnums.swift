import Foundation

enum ActiveRate: String, CaseIterable, Codable {
    case paralela, bcv
    var label: String { self == .paralela ? "PARALELA" : "BCV" }
}

enum DashboardLayout: String, CaseIterable, Codable {
    case stack, pipeline, ledger
    var label: String {
        switch self {
        case .stack:    return "Consola"
        case .pipeline: return "Pipeline"
        case .ledger:   return "Ledger"
        }
    }
}

enum GastoCategory: String, CaseIterable, Codable {
    case mercado, salud, transporte, restaurantes, servicios, ocio, otros

    var label: String {
        switch self {
        case .mercado:      return "Mercado"
        case .salud:        return "Salud"
        case .transporte:   return "Transporte"
        case .restaurantes: return "Restaurantes"
        case .servicios:    return "Servicios"
        case .ocio:         return "Ocio"
        case .otros:        return "Otros"
        }
    }

    var glyph: String {
        switch self {
        case .mercado:      return "▣"
        case .salud:        return "✚"
        case .transporte:   return "▶"
        case .restaurantes: return "◆"
        case .servicios:    return "≣"
        case .ocio:         return "◉"
        case .otros:        return "·"
        }
    }
}
