import FinanceCore
import SwiftUI

/// A row component for displaying a single transaction in a list.
///
/// `TransactionRow` renders a horizontal layout with a category icon on the
/// left, category name and note in the center, and the formatted amount on the
/// right. The amount is color-coded by transaction type: green for income,
/// red for expense, blue for transfer. An account name caption sits beneath
/// the amount for additional context.
///
/// Example usage:
/// ```swift
/// TransactionRow(
///     transaction: transaction,
///     categoryName: "Food & Drink",
///     categoryIcon: "fork.knife",
///     categoryColor: "#FF9500",
///     accountName: "Cash Wallet",
///     currencyCode: .VND
/// )
/// ```
public struct TransactionRow: View {
    private let transaction: FinanceCore.Transaction
    private let categoryName: String
    private let categoryIcon: String
    private let categoryColor: String
    private let accountName: String
    private let currencyCode: CurrencyCode

    /// Creates a transaction row view.
    ///
    /// - Parameters:
    ///   - transaction: The transaction to display.
    ///   - categoryName: Human-readable name of the transaction's category.
    ///   - categoryIcon: SF Symbol name for the category icon.
    ///   - categoryColor: Hexadecimal color code for the category icon background.
    ///   - accountName: Name of the source account.
    ///   - currencyCode: Currency used to format the amount.
    public init(
        transaction: FinanceCore.Transaction,
        categoryName: String,
        categoryIcon: String,
        categoryColor: String,
        accountName: String,
        currencyCode: CurrencyCode
    ) {
        self.transaction = transaction
        self.categoryName = categoryName
        self.categoryIcon = categoryIcon
        self.categoryColor = categoryColor
        self.accountName = accountName
        self.currencyCode = currencyCode
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            categoryIconView

            categoryInfoView

            Spacer(minLength: DesignTokens.Spacing.sm)

            amountView
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view transaction details.")
    }

    // MARK: - Subviews

    private var categoryIconView: some View {
        ZStack {
            Circle()
                .fill(Color(hex: categoryColor))
                .frame(width: 40, height: 40)
            Image(systemName: categoryIcon)
                .font(.body)
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }

    private var categoryInfoView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Text(categoryName)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(1)

            if !transaction.note.isEmpty {
                Text(transaction.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var amountView: some View {
        VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xxs) {
            Text(formattedAmount)
                .font(.body)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(amountColor)

            Text(accountName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    // MARK: - Helpers

    private var formattedAmount: String {
        let formatter = CurrencyFormatter(currencyCode: currencyCode)
        let formatted = formatter.format(transaction.amount)
        switch transaction.type {
        case .income:
            return "+\(formatted)"
        case .expense:
            return "-\(formatted)"
        case .transfer:
            return "↔ \(formatted)"
        }
    }

    private var amountColor: Color {
        switch transaction.type {
        case .income:
            return DesignTokens.Colors.income
        case .expense:
            return DesignTokens.Colors.expense
        case .transfer:
            return DesignTokens.Colors.transfer
        }
    }

    private var accessibilityLabel: String {
        let formatter = CurrencyFormatter(currencyCode: currencyCode)
        let amountText = formatter.format(transaction.amount)
        let typeText = transaction.type.displayName
        let noteText = transaction.note.isEmpty ? "" : ", note: \(transaction.note)"
        return "\(categoryName), \(typeText), \(amountText)\(noteText), from \(accountName)"
    }
}

// MARK: - Previews

#Preview("Income") {
    let categoryID = UUID()
    let accountID = UUID()
    TransactionRow(
        transaction: FinanceCore.Transaction(
            amount: 5_000_000,
            type: .income,
            categoryID: categoryID,
            accountID: accountID,
            note: "Monthly salary"
        ),
        categoryName: "Salary",
        categoryIcon: "briefcase.fill",
        categoryColor: "#34C759",
        accountName: "Main Checking",
        currencyCode: .VND
    )
    .padding(.horizontal)
}

#Preview("Expense") {
    let categoryID = UUID()
    let accountID = UUID()
    TransactionRow(
        transaction: FinanceCore.Transaction(
            amount: 85_000,
            type: .expense,
            categoryID: categoryID,
            accountID: accountID,
            note: "Lunch with colleagues"
        ),
        categoryName: "Food & Drink",
        categoryIcon: "fork.knife",
        categoryColor: "#FF9500",
        accountName: "Cash Wallet",
        currencyCode: .VND
    )
    .padding(.horizontal)
}

#Preview("Transfer") {
    let categoryID = UUID()
    let accountID = UUID()
    let toAccountID = UUID()
    TransactionRow(
        transaction: FinanceCore.Transaction(
            amount: 1_000_000,
            type: .transfer,
            categoryID: categoryID,
            accountID: accountID,
            toAccountID: toAccountID
        ),
        categoryName: "Transfer",
        categoryIcon: "arrow.left.arrow.right",
        categoryColor: "#007AFF",
        accountName: "Cash Wallet",
        currencyCode: .VND
    )
    .padding(.horizontal)
}

#Preview("List") {
    let catID = UUID()
    let accID = UUID()
    List {
        TransactionRow(
            transaction: FinanceCore.Transaction(amount: 5_000_000, type: .income, categoryID: catID, accountID: accID, note: "Salary"),
            categoryName: "Salary",
            categoryIcon: "briefcase.fill",
            categoryColor: "#34C759",
            accountName: "Main Checking",
            currencyCode: .VND
        )
        TransactionRow(
            transaction: FinanceCore.Transaction(amount: 85_000, type: .expense, categoryID: catID, accountID: accID, note: "Lunch"),
            categoryName: "Food & Drink",
            categoryIcon: "fork.knife",
            categoryColor: "#FF9500",
            accountName: "Cash Wallet",
            currencyCode: .VND
        )
        TransactionRow(
            transaction: FinanceCore.Transaction(amount: 1_000_000, type: .transfer, categoryID: catID, accountID: accID),
            categoryName: "Transfer",
            categoryIcon: "arrow.left.arrow.right",
            categoryColor: "#007AFF",
            accountName: "Cash Wallet",
            currencyCode: .VND
        )
    }
}
