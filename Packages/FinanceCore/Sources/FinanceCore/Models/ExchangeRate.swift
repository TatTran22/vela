import Foundation

/// Represents an exchange rate between two currencies at a specific date.
///
/// Exchange rates are used to convert amounts between different currencies
/// for multi-currency account management and reporting. Each rate includes
/// metadata about its source and date for transparency and cache validation.
public struct ExchangeRate: Identifiable, Sendable, Hashable, Codable {
    /// Unique identifier for the exchange rate record.
    public let id: UUID

    /// The base currency (the currency being converted from).
    public var baseCurrency: CurrencyCode

    /// The target currency (the currency being converted to).
    public var targetCurrency: CurrencyCode

    /// The exchange rate multiplier.
    ///
    /// To convert an amount from base to target currency:
    /// `targetAmount = baseAmount * rate`
    public var rate: Decimal

    /// The date and time when this exchange rate is valid.
    public var date: Date

    /// The source of the exchange rate data.
    ///
    /// Examples: "ECB", "manual", "xe.com", "cached"
    public var source: String

    /// Creates a new exchange rate record.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - baseCurrency: The currency being converted from.
    ///   - targetCurrency: The currency being converted to.
    ///   - rate: The exchange rate multiplier.
    ///   - date: The date when this rate is valid.
    ///   - source: The source of the rate data. Defaults to empty string.
    public init(
        id: UUID = UUID(),
        baseCurrency: CurrencyCode,
        targetCurrency: CurrencyCode,
        rate: Decimal,
        date: Date,
        source: String = ""
    ) {
        self.id = id
        self.baseCurrency = baseCurrency
        self.targetCurrency = targetCurrency
        self.rate = rate
        self.date = date
        self.source = source
    }
}
