import FinanceCore
import FinanceUI
import SwiftUI

/// Desktop-optimized detail view for displaying account information.
///
/// This view presents comprehensive account details including balance statistics,
/// transaction history placeholder, and editing capabilities. Designed for macOS
/// with toolbar integration and keyboard shortcuts.
struct MacAccountDetailView: View {
    /// The account to display
    let account: Account

    /// Callback invoked when the edit button is pressed
    let onEdit: () -> Void

    /// Callback invoked when the delete button is pressed
    let onDelete: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header card
                AccountCard(account: account, layout: .expanded)

                // Stats grid
                HStack(spacing: 16) {
                    statCard(title: "Income", amount: 0, icon: "arrow.down.circle", color: .green)
                    statCard(title: "Expense", amount: 0, icon: "arrow.up.circle", color: .red)
                    statCard(title: "Net", amount: 0, icon: "equal.circle", color: .blue)
                }

                // Transaction table placeholder
                GroupBox("Recent Transactions") {
                    ContentUnavailableView {
                        Label("No Transactions", systemImage: "list.bullet")
                    } description: {
                        Text("Transactions will appear here once the Transactions feature is implemented.")
                    }
                    .frame(minHeight: 200)
                }
            }
            .padding()
        }
        .navigationTitle(account.name)
        .toolbar {
            ToolbarItemGroup {
                Button { onEdit() } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .keyboardShortcut("e", modifiers: .command)

                Button(role: .destructive) { onDelete() } label: {
                    Label("Delete", systemImage: "trash")
                }
                .keyboardShortcut(.delete, modifiers: .command)
            }
        }
    }

    /// Creates a statistics card displaying an amount with an icon and label.
    ///
    /// - Parameters:
    ///   - title: The label for the statistic
    ///   - amount: The monetary amount to display
    ///   - icon: SF Symbol name for the icon
    ///   - color: Color for the icon
    /// - Returns: A view displaying the statistic card
    private func statCard(title: String, amount: Decimal, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            BalanceText(amount: amount, currencyCode: account.currency, size: .medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
