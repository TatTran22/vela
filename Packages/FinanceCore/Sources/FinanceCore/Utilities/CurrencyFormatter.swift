import Foundation

/// Formats monetary values for display with currency-specific locales and symbols.
///
/// This formatter handles multi-currency formatting with proper locale-specific
/// thousands separators, decimal places, and currency symbols. It also provides
/// compact formatting for large numbers and utility methods for multi-currency displays.
public struct CurrencyFormatter: Sendable {
    private let currencyCode: CurrencyCode
    private let locale: Locale

    /// Creates a currency formatter with a specific currency code.
    ///
    /// The locale is automatically selected based on the currency for proper formatting.
    ///
    /// - Parameter currencyCode: The currency code to format. Defaults to VND.
    public init(currencyCode: CurrencyCode = .VND) {
        self.currencyCode = currencyCode
        self.locale = Self.locale(for: currencyCode)
    }

    /// Creates a currency formatter with a string currency code (for backwards compatibility).
    ///
    /// This initializer exists for compatibility with data layer code that may use string codes.
    ///
    /// - Parameters:
    ///   - currencyCodeString: The ISO 4217 currency code as a string.
    ///   - locale: The locale to use for formatting.
    public init(currencyCodeString: String, locale: Locale) {
        // Try to convert to CurrencyCode enum, fallback to VND
        self.currencyCode = CurrencyCode(rawValue: currencyCodeString) ?? .VND
        self.locale = locale
    }

    /// Formats a decimal amount as a currency string with symbol.
    ///
    /// Examples:
    /// - VND: `1.000.000 ₫`
    /// - USD: `$1,000.00`
    /// - EUR: `€1.000,00`
    ///
    /// - Parameter amount: The monetary amount to format.
    /// - Returns: A formatted currency string.
    public func format(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode.rawValue
        formatter.locale = locale
        formatter.maximumFractionDigits = currencyCode.decimalPlaces
        formatter.minimumFractionDigits = currencyCode.decimalPlaces
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }

    /// Formats a decimal amount as a compact string for large numbers.
    ///
    /// This method abbreviates large numbers for better readability in limited space:
    /// - VND: "1.5tr" (trieu/million), "1.5 tỷ" (billion), "150k"
    /// - Other currencies: "1.5M", "1.5B", "150K"
    ///
    /// - Parameter amount: The monetary amount to format.
    /// - Returns: A compact formatted string.
    public func formatCompact(_ amount: Decimal) -> String {
        let doubleValue = (amount as NSDecimalNumber).doubleValue
        let absAmount = Swift.abs(doubleValue)
        let sign = doubleValue < 0 ? "-" : ""

        let (value, suffix) = if currencyCode == .VND {
            // Vietnamese: tỷ (billion), tr (trieu/million), k (nghìn/thousand)
            if absAmount >= 1_000_000_000 {
                (absAmount / 1_000_000_000, " tỷ")
            } else if absAmount >= 1_000_000 {
                (absAmount / 1_000_000, "tr")
            } else if absAmount >= 1_000 {
                (absAmount / 1_000, "k")
            } else {
                (absAmount, "")
            }
        } else {
            // International: B (billion), M (million), K (thousand)
            if absAmount >= 1_000_000_000 {
                (absAmount / 1_000_000_000, "B")
            } else if absAmount >= 1_000_000 {
                (absAmount / 1_000_000, "M")
            } else if absAmount >= 1_000 {
                (absAmount / 1_000, "K")
            } else {
                (absAmount, "")
            }
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.maximumFractionDigits = suffix.isEmpty ? currencyCode.decimalPlaces : 1
        formatter.minimumFractionDigits = 0

        let formattedValue = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(sign)\(formattedValue)\(suffix) \(currencyCode.symbol)"
    }

    /// Formats a decimal amount without the currency symbol.
    ///
    /// This is useful for input fields or scenarios where the currency is already clear from context.
    ///
    /// Examples:
    /// - VND: `1.000.000`
    /// - USD: `1,000.00`
    ///
    /// - Parameter amount: The monetary amount to format.
    /// - Returns: A formatted number string without currency symbol.
    public func formatWithoutSymbol(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.maximumFractionDigits = currencyCode.decimalPlaces
        formatter.minimumFractionDigits = currencyCode.decimalPlaces
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }

    /// Formats a currency conversion pair showing both amounts and their relationship.
    ///
    /// This method displays a source amount, its converted equivalent, and the currencies involved.
    ///
    /// Example: `1,000 $ ≈ 25.000.000 ₫`
    ///
    /// - Parameters:
    ///   - amount: The source amount to display.
    ///   - from: The source currency.
    ///   - to: The target currency.
    ///   - rate: The exchange rate from source to target.
    /// - Returns: A formatted string showing the conversion.
    public func formatPair(amount: Decimal, from: CurrencyCode, to: CurrencyCode, rate: Decimal) -> String {
        let fromFormatter = CurrencyFormatter(currencyCode: from)
        let toFormatter = CurrencyFormatter(currencyCode: to)

        let convertedAmount = amount * rate

        let fromStr = fromFormatter.formatWithoutSymbol(amount)
        let toStr = toFormatter.formatWithoutSymbol(convertedAmount)

        return "\(fromStr) \(from.symbol) ≈ \(toStr) \(to.symbol)"
    }

    // MARK: - Private Helpers

    /// Returns the appropriate locale for a given currency code.
    ///
    /// Each currency uses its primary country's locale for proper formatting conventions.
    ///
    /// - Parameter currencyCode: The currency code.
    /// - Returns: The locale for formatting that currency.
    private static func locale(for currencyCode: CurrencyCode) -> Locale {
        switch currencyCode {
        case .VND:
            return Locale(identifier: "vi_VN")
        case .USD:
            return Locale(identifier: "en_US")
        case .EUR:
            return Locale(identifier: "de_DE") // Use German locale for EUR (1.000,00 format)
        case .JPY:
            return Locale(identifier: "ja_JP")
        case .KRW:
            return Locale(identifier: "ko_KR")
        case .THB:
            return Locale(identifier: "th_TH")
        case .SGD:
            return Locale(identifier: "en_SG")
        case .AUD:
            return Locale(identifier: "en_AU")
        case .GBP:
            return Locale(identifier: "en_GB")
        case .CNY:
            return Locale(identifier: "zh_CN")
        }
    }
}
