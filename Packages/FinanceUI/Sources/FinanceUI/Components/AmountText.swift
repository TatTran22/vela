import FinanceCore
import SwiftUI

/// Size variants for AmountText display.
public enum AmountStyle: Sendable {
    /// 34pt bold rounded — dashboard total balance
    case hero
    /// 28pt bold rounded — card balances
    case large
    /// 20pt semibold rounded — list item amounts
    case regular
    /// 17pt semibold monospaced — budget progress values
    case small

    var font: Font {
        switch self {
        case .hero: return DesignTokens.Typography.heroAmount
        case .large: return DesignTokens.Typography.largeAmount
        case .regular: return DesignTokens.Typography.amount
        case .small: return DesignTokens.Typography.smallAmount
        }
    }
}

/// Displays a formatted monetary amount with color coding based on transaction type.
///
/// `AmountText` is the standard way to render currency values throughout the app.
/// It supports size variants from hero (dashboard) to small (inline), optional
/// sign prefixes, compact notation for large numbers, and automatic color coding.
///
/// Example usage:
/// ```swift
/// AmountText(amount: 1_500_000, currencyCode: .VND, type: .income, style: .large, showSign: true)
/// AmountText(amount: 85_000, currencyCode: .VND, type: .expense, style: .regular, compact: true)
/// ```
public struct AmountText: View {
    private let amount: Decimal
    private let currencyCode: CurrencyCode
    private let type: TransactionType?
    private let style: AmountStyle
    private let showSign: Bool
    private let compact: Bool

    /// Creates a formatted amount text view.
    ///
    /// - Parameters:
    ///   - amount: The monetary amount to display.
    ///   - currencyCode: The currency for formatting. Defaults to `.VND`.
    ///   - type: Transaction type for color coding. `nil` uses primary text color.
    ///   - style: Size variant. Defaults to `.regular`.
    ///   - showSign: Whether to show `+`/`-` prefix. Defaults to `false`.
    ///   - compact: Whether to use compact notation (e.g., "1.5tr"). Defaults to `false`.
    public init(
        amount: Decimal,
        currencyCode: CurrencyCode = .VND,
        type: TransactionType? = nil,
        style: AmountStyle = .regular,
        showSign: Bool = false,
        compact: Bool = false
    ) {
        self.amount = amount
        self.currencyCode = currencyCode
        self.type = type
        self.style = style
        self.showSign = showSign
        self.compact = compact
    }

    public var body: some View {
        Text(formatted)
            .font(style.font)
            .foregroundStyle(color)
            .monospacedDigit()
            .accessibilityLabel(accessibilityText)
    }

    // MARK: - Formatting

    private var formatted: String {
        let formatter = CurrencyFormatter(currencyCode: currencyCode)
        let base = compact ? formatter.formatCompact(amount) : formatter.format(amount)

        guard showSign else { return base }

        switch type {
        case .income:
            return "+\(base)"
        case .expense:
            return "-\(base)"
        case .transfer:
            return "↔ \(base)"
        case .none:
            if amount > 0 { return "+\(base)" }
            if amount < 0 { return base } // Already has negative sign
            return base
        }
    }

    private var color: Color {
        switch type {
        case .income:
            return DesignTokens.Colors.income
        case .expense:
            return DesignTokens.Colors.expense
        case .transfer:
            return DesignTokens.Colors.transfer
        case .none:
            return DesignTokens.Colors.textPrimary
        }
    }

    private var accessibilityText: String {
        let formatter = CurrencyFormatter(currencyCode: currencyCode)
        let amountText = formatter.format(amount)
        let typeLabel: String
        switch type {
        case .income: typeLabel = "income "
        case .expense: typeLabel = "expense "
        case .transfer: typeLabel = "transfer "
        case .none: typeLabel = ""
        }
        return "\(typeLabel)\(amountText)"
    }
}

// MARK: - Previews

#Preview("All Styles") {
    VStack(alignment: .trailing, spacing: DesignTokens.Spacing.lg) {
        AmountText(amount: 15_200_000, currencyCode: .VND, style: .hero)
        AmountText(amount: 5_000_000, currencyCode: .VND, style: .large)
        AmountText(amount: 85_000, currencyCode: .VND, style: .regular)
        AmountText(amount: 45_000, currencyCode: .VND, style: .small)
    }
    .padding()
}

#Preview("Color Coded") {
    VStack(alignment: .trailing, spacing: DesignTokens.Spacing.md) {
        AmountText(amount: 5_000_000, currencyCode: .VND, type: .income, showSign: true)
        AmountText(amount: 85_000, currencyCode: .VND, type: .expense, showSign: true)
        AmountText(amount: 1_000_000, currencyCode: .VND, type: .transfer, showSign: true)
        AmountText(amount: 500, currencyCode: .USD)
    }
    .padding()
}

#Preview("Compact") {
    VStack(alignment: .trailing, spacing: DesignTokens.Spacing.md) {
        AmountText(amount: 1_500_000, currencyCode: .VND, compact: true)
        AmountText(amount: 1_500_000_000, currencyCode: .VND, compact: true)
        AmountText(amount: 1_500_000, currencyCode: .VND, compact: false)
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(alignment: .trailing, spacing: DesignTokens.Spacing.md) {
        AmountText(amount: 5_000_000, currencyCode: .VND, type: .income, style: .large, showSign: true)
        AmountText(amount: 85_000, currencyCode: .VND, type: .expense, style: .regular, showSign: true)
    }
    .padding()
    .background(.background)
    .preferredColorScheme(.dark)
}
