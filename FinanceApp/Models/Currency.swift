import Foundation

// Curated list of currencies the app supports out of the box.
// Adding a new currency only requires extending this enum.
enum Currency: String, CaseIterable, Codable, Identifiable, Hashable {
    case usd, eur, gbp, ves, usdt, cop, mxn, ars, brl, pen, clp, uyu

    var id: String { rawValue }

    var code: String {
        switch self {
        case .usd:  "USD"
        case .eur:  "EUR"
        case .gbp:  "GBP"
        case .ves:  "VES"
        case .usdt: "USDT"
        case .cop:  "COP"
        case .mxn:  "MXN"
        case .ars:  "ARS"
        case .brl:  "BRL"
        case .pen:  "PEN"
        case .clp:  "CLP"
        case .uyu:  "UYU"
        }
    }

    var symbol: String {
        switch self {
        case .usd:  "$"
        case .eur:  "€"
        case .gbp:  "£"
        case .ves:  "Bs"
        case .usdt: "₮"
        case .cop:  "$"
        case .mxn:  "$"
        case .ars:  "$"
        case .brl:  "R$"
        case .pen:  "S/"
        case .clp:  "$"
        case .uyu:  "$"
        }
    }

    var label: String {
        switch self {
        case .usd:  "Dólar"
        case .eur:  "Euro"
        case .gbp:  "Libra"
        case .ves:  "Bolívar"
        case .usdt: "USDT"
        case .cop:  "Peso COL"
        case .mxn:  "Peso MX"
        case .ars:  "Peso ARG"
        case .brl:  "Real"
        case .pen:  "Sol"
        case .clp:  "Peso CHL"
        case .uyu:  "Peso UYU"
        }
    }

    var defaultDecimals: Int {
        switch self {
        case .clp, .cop: 0
        default: 2
        }
    }

    // Format a numeric amount with this currency's symbol & decimals.
    func format(_ amount: Double, dec: Int? = nil) -> String {
        let d = dec ?? defaultDecimals
        let n = vFmt(amount, dec: d)
        return "\(symbol) \(n)"
    }

    static func from(raw: String) -> Currency {
        Currency(rawValue: raw) ?? .usd
    }
}
