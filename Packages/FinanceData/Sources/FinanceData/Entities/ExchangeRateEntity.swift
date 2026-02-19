import Foundation
import SwiftData

/// SwiftData entity for persisting exchange rate data.
///
/// Stores currency exchange rates with their date and source information
/// for multi-currency support. All properties use default values for
/// CloudKit compatibility.
@Model
public final class ExchangeRateEntity {
    public var id: UUID = UUID()
    public var baseCurrency: String = "VND"
    public var targetCurrency: String = "USD"
    public var rate: Decimal = 0
    public var date: Date = Date()
    public var source: String = ""

    public init(
        id: UUID = UUID(),
        baseCurrency: String,
        targetCurrency: String,
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
