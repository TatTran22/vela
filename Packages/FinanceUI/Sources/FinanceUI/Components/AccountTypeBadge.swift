import FinanceCore
import SwiftUI

/// A compact capsule-shaped badge displaying an account type with icon and label.
///
/// AccountTypeBadge provides a consistent visual representation of account types
/// throughout the application. It combines the account type's icon and display name
/// in a colored capsule using the type's theme color.
///
/// Example usage:
/// ```swift
/// AccountTypeBadge(accountType: .cash)
/// AccountTypeBadge(accountType: .creditCard)
/// ```
public struct AccountTypeBadge: View {
    private let accountType: AccountType

    /// Creates an account type badge.
    ///
    /// - Parameter accountType: The account type to display.
    public init(accountType: AccountType) {
        self.accountType = accountType
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: accountType.defaultIconName)
                .font(.caption2)
            Text(accountType.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(Color(hex: accountType.defaultColorHex).opacity(0.15))
        .foregroundStyle(Color(hex: accountType.defaultColorHex))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(accountType.displayName) account")
    }
}

#Preview("All Account Types") {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
        ForEach(AccountType.allCases, id: \.self) { type in
            AccountTypeBadge(accountType: type)
        }
    }
    .padding()
}

#Preview("In Context") {
    VStack(spacing: DesignTokens.Spacing.lg) {
        // Light background
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Account Types")
                .font(.headline)
            HStack {
                AccountTypeBadge(accountType: .cash)
                AccountTypeBadge(accountType: .bank)
                AccountTypeBadge(accountType: .creditCard)
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))

        // Dark background
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Account Types")
                .font(.headline)
                .foregroundStyle(.white)
            HStack {
                AccountTypeBadge(accountType: .eWallet)
                AccountTypeBadge(accountType: .savings)
                AccountTypeBadge(accountType: .investment)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
    }
    .padding()
}

#Preview("Horizontal Wrap") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(AccountType.allCases, id: \.self) { type in
                AccountTypeBadge(accountType: type)
            }
        }
        .padding()
    }
}
