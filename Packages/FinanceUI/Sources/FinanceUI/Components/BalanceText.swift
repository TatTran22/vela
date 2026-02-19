import FinanceCore
import SwiftUI

/// Size variants for BalanceText display
public enum BalanceTextSize: Sendable {
    case small   // caption
    case medium  // body
    case large   // title2

    /// The font for the balance text
    var font: Font {
        switch self {
        case .small: return .caption
        case .medium: return .body
        case .large: return .title2
        }
    }
}

/// Displays a formatted account balance with currency.
///
/// BalanceText provides a consistent way to display monetary balances throughout
/// the application. It supports multiple sizes and an optional compact format for
/// large numbers.
///
/// Example usage:
/// ```swift
/// BalanceText(amount: 1_500_000, currencyCode: .VND, size: .large)
/// BalanceText(amount: 5_000, currencyCode: .USD, size: .medium, compact: true)
/// ```
public struct BalanceText: View {
    private let amount: Decimal
    private let currencyCode: CurrencyCode
    private let size: BalanceTextSize
    private let compact: Bool

    /// Creates a balance text view.
    ///
    /// - Parameters:
    ///   - amount: The monetary amount to display.
    ///   - currencyCode: The currency code for formatting. Defaults to VND.
    ///   - size: The size variant for the text. Defaults to .medium.
    ///   - compact: Whether to use compact notation for large numbers. Defaults to false.
    public init(
        amount: Decimal,
        currencyCode: CurrencyCode = .VND,
        size: BalanceTextSize = .medium,
        compact: Bool = false
    ) {
        self.amount = amount
        self.currencyCode = currencyCode
        self.size = size
        self.compact = compact
    }

    public var body: some View {
        Text(formatted)
            .font(size.font)
            .fontWeight(size == .large ? .bold : .regular)
            .monospacedDigit()
            .accessibilityLabel("Balance: \(formatted)")
    }

    private var formatted: String {
        let formatter = CurrencyFormatter(currencyCode: currencyCode)
        return compact ? formatter.formatCompact(amount) : formatter.format(amount)
    }
}

#Preview("All Sizes") {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("Small")
                .font(.caption2)
                .foregroundStyle(.secondary)
            BalanceText(amount: 1_500_000, currencyCode: .VND, size: .small)
        }

        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("Medium")
                .font(.caption2)
                .foregroundStyle(.secondary)
            BalanceText(amount: 1_500_000, currencyCode: .VND, size: .medium)
        }

        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("Large")
                .font(.caption2)
                .foregroundStyle(.secondary)
            BalanceText(amount: 1_500_000, currencyCode: .VND, size: .large)
        }
    }
    .padding()
}

#Preview("Compact Format") {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("VND - Full")
                .font(.caption2)
                .foregroundStyle(.secondary)
            BalanceText(amount: 1_500_000_000, currencyCode: .VND, size: .medium)
        }

        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("VND - Compact")
                .font(.caption2)
                .foregroundStyle(.secondary)
            BalanceText(amount: 1_500_000_000, currencyCode: .VND, size: .medium, compact: true)
        }

        Divider()

        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("USD - Full")
                .font(.caption2)
                .foregroundStyle(.secondary)
            BalanceText(amount: 1_500_000, currencyCode: .USD, size: .medium)
        }

        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("USD - Compact")
                .font(.caption2)
                .foregroundStyle(.secondary)
            BalanceText(amount: 1_500_000, currencyCode: .USD, size: .medium, compact: true)
        }
    }
    .padding()
}

#Preview("Multiple Currencies") {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
        Group {
            HStack {
                Text("VND:")
                    .frame(width: 60, alignment: .leading)
                BalanceText(amount: 1_500_000, currencyCode: .VND)
            }
            HStack {
                Text("USD:")
                    .frame(width: 60, alignment: .leading)
                BalanceText(amount: 1_234.56, currencyCode: .USD)
            }
            HStack {
                Text("EUR:")
                    .frame(width: 60, alignment: .leading)
                BalanceText(amount: 999.99, currencyCode: .EUR)
            }
            HStack {
                Text("JPY:")
                    .frame(width: 60, alignment: .leading)
                BalanceText(amount: 150_000, currencyCode: .JPY)
            }
            HStack {
                Text("GBP:")
                    .frame(width: 60, alignment: .leading)
                BalanceText(amount: 750.25, currencyCode: .GBP)
            }
        }
    }
    .padding()
}

#Preview("Negative Balances") {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
        BalanceText(amount: 1_500_000, currencyCode: .VND, size: .large)
            .foregroundStyle(.green)
        BalanceText(amount: -500_000, currencyCode: .VND, size: .large)
            .foregroundStyle(.red)
        BalanceText(amount: 0, currencyCode: .VND, size: .large)
            .foregroundStyle(.secondary)
    }
    .padding()
}
