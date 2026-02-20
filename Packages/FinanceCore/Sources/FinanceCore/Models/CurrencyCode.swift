import Foundation

/// Supported currency codes for financial accounts.
///
/// This enum represents the currencies that the application supports for multi-currency
/// account management. Each currency includes metadata such as symbol, name, decimal
/// precision, and flag emoji for UI display.
public enum CurrencyCode: String, Sendable, CaseIterable, Codable, Hashable {
    case VND
    case USD
    case EUR
    case JPY
    case KRW
    case THB
    case SGD
    case AUD
    case GBP
    case CNY

    /// Currency symbol used for display.
    ///
    /// Returns the standard symbol for each currency (e.g., "$", "€", "₫").
    public var symbol: String {
        switch self {
        case .VND: return "₫"
        case .USD: return "$"
        case .EUR: return "€"
        case .JPY: return "¥"
        case .KRW: return "₩"
        case .THB: return "฿"
        case .SGD: return "S$"
        case .AUD: return "A$"
        case .GBP: return "£"
        case .CNY: return "¥"
        }
    }

    /// Localized full name of the currency.
    ///
    /// Returns the complete currency name for display purposes.
    public var name: String {
        CoreStrings.currencyName(rawValue)
    }

    /// Number of decimal places used for this currency.
    ///
    /// Some currencies like VND, JPY, and KRW do not use decimal subdivisions,
    /// while most others use 2 decimal places (cents, pence, etc.).
    public var decimalPlaces: Int {
        switch self {
        case .VND, .JPY, .KRW:
            return 0
        case .USD, .EUR, .THB, .SGD, .AUD, .GBP, .CNY:
            return 2
        }
    }

    /// Flag emoji representing the currency's primary country or region.
    ///
    /// Returns an emoji flag for visual representation in the UI.
    public var flag: String {
        switch self {
        case .VND: return "🇻🇳"
        case .USD: return "🇺🇸"
        case .EUR: return "🇪🇺"
        case .JPY: return "🇯🇵"
        case .KRW: return "🇰🇷"
        case .THB: return "🇹🇭"
        case .SGD: return "🇸🇬"
        case .AUD: return "🇦🇺"
        case .GBP: return "🇬🇧"
        case .CNY: return "🇨🇳"
        }
    }
}
