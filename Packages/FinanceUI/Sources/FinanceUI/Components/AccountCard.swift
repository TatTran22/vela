import FinanceCore
import SwiftUI

/// Layout variants for AccountCard display
public enum AccountCardLayout: Sendable {
    case compact  // Horizontal layout for list rows
    case expanded // Vertical layout for detail headers
}

/// Displays comprehensive account information combining icon, name, balance, and type.
///
/// AccountCard is a versatile component that adapts its layout based on context.
/// In compact mode, it works well as a list row. In expanded mode, it serves as
/// a prominent header for account detail views.
///
/// Example usage:
/// ```swift
/// AccountCard(account: myAccount, layout: .compact)
/// AccountCard(account: myAccount, layout: .expanded)
/// ```
public struct AccountCard: View {
    private let account: Account
    private let layout: AccountCardLayout

    /// Creates an account card view.
    ///
    /// - Parameters:
    ///   - account: The account to display.
    ///   - layout: The layout variant to use. Defaults to .compact.
    public init(account: Account, layout: AccountCardLayout = .compact) {
        self.account = account
        self.layout = layout
    }

    public var body: some View {
        Group {
            switch layout {
            case .compact:
                compactLayout
            case .expanded:
                expandedLayout
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Compact Layout

    private var compactLayout: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Icon
            AccountIcon(iconName: account.iconName, colorHex: account.colorHex, size: .medium)

            // Name and type
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(account.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                AccountTypeBadge(accountType: account.type)
            }

            Spacer(minLength: DesignTokens.Spacing.sm)

            // Balance
            BalanceText(
                amount: account.balance,
                currencyCode: account.currency,
                size: .medium
            )
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    // MARK: - Expanded Layout

    private var expandedLayout: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Icon
            AccountIcon(iconName: account.iconName, colorHex: account.colorHex, size: .large)

            // Name
            Text(account.name)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Balance
            BalanceText(
                amount: account.balance,
                currencyCode: account.currency,
                size: .large
            )

            // Type badge
            AccountTypeBadge(accountType: account.type)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        let balanceFormatter = CurrencyFormatter(currencyCode: account.currency)
        let balanceText = balanceFormatter.format(account.balance)
        return "\(account.name), \(account.type.displayName) account, balance \(balanceText)"
    }
}

#Preview("Compact Layout") {
    VStack(spacing: 0) {
        ForEach(sampleAccounts) { account in
            AccountCard(account: account, layout: .compact)
            Divider()
        }
    }
    .padding(.horizontal)
}

#Preview("Expanded Layout") {
    ScrollView {
        VStack(spacing: DesignTokens.Spacing.lg) {
            ForEach(sampleAccounts) { account in
                AccountCard(account: account, layout: .expanded)
            }
        }
        .padding()
    }
}

#Preview("Different Balances") {
    VStack(spacing: 0) {
        AccountCard(
            account: Account(
                name: "Positive Balance",
                type: .bank,
                currency: .USD,
                balance: 5_000.00,
                colorHex: "#007AFF"
            ),
            layout: .compact
        )
        Divider()

        AccountCard(
            account: Account(
                name: "Zero Balance",
                type: .cash,
                currency: .VND,
                balance: 0,
                colorHex: "#34C759"
            ),
            layout: .compact
        )
        Divider()

        AccountCard(
            account: Account(
                name: "Negative Balance",
                type: .creditCard,
                currency: .EUR,
                balance: -1_234.56,
                colorHex: "#FF9500"
            ),
            layout: .compact
        )
    }
    .padding(.horizontal)
}

#Preview("Long Account Names") {
    VStack(spacing: 0) {
        AccountCard(
            account: Account(
                name: "My Primary Checking Account for Daily Expenses",
                type: .bank,
                currency: .USD,
                balance: 10_000.00,
                iconName: "building.columns",
                colorHex: "#007AFF"
            ),
            layout: .compact
        )
        Divider()

        AccountCard(
            account: Account(
                name: "Emergency Savings Fund",
                type: .savings,
                currency: .USD,
                balance: 50_000.00,
                iconName: "chart.line.uptrend.xyaxis",
                colorHex: "#30B0C7"
            ),
            layout: .compact
        )
    }
    .padding(.horizontal)
}

#Preview("Dark Mode") {
    VStack(spacing: DesignTokens.Spacing.lg) {
        AccountCard(account: sampleAccounts[0], layout: .compact)
            .padding(.horizontal)

        AccountCard(account: sampleAccounts[0], layout: .expanded)
            .padding()
    }
    .background(.background)
    .preferredColorScheme(.dark)
}

// MARK: - Preview Helpers

private let sampleAccounts: [Account] = [
    Account(
        name: "Cash Wallet",
        type: .cash,
        currency: .VND,
        balance: 1_500_000,
        iconName: "banknote",
        colorHex: "#34C759"
    ),
    Account(
        name: "Main Checking",
        type: .bank,
        currency: .USD,
        balance: 5_432.10,
        iconName: "building.columns",
        colorHex: "#007AFF"
    ),
    Account(
        name: "Credit Card",
        type: .creditCard,
        currency: .USD,
        balance: -1_234.56,
        iconName: "creditcard",
        colorHex: "#FF9500"
    ),
    Account(
        name: "MoMo Wallet",
        type: .eWallet,
        currency: .VND,
        balance: 500_000,
        iconName: "wallet.pass",
        colorHex: "#5856D6"
    ),
    Account(
        name: "Emergency Fund",
        type: .savings,
        currency: .USD,
        balance: 15_000.00,
        iconName: "chart.line.uptrend.xyaxis",
        colorHex: "#30B0C7"
    ),
]
