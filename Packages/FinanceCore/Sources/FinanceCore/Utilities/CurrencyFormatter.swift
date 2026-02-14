import Foundation

/// Formats monetary values for display
public struct CurrencyFormatter: Sendable {
    private let currencyCode: String
    private let locale: Locale

    public init(currencyCode: String = "VND", locale: Locale = Locale(identifier: "vi_VN")) {
        self.currencyCode = currencyCode
        self.locale = locale
    }

    /// Formats a Decimal amount as a currency string
    public func format(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = locale
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
}
