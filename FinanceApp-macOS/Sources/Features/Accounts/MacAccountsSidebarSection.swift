import FinanceCore
import FinanceUI
import SwiftUI

/// Sidebar section that displays accounts grouped by type using disclosure groups.
///
/// This component renders account groups in a macOS sidebar with expandable sections,
/// displaying account icons, names, and balances in a compact format suitable for
/// sidebar navigation. Supports context menus for account operations.
struct MacAccountsSidebarSection: View {
    /// Accounts grouped by their account type
    let groupedAccounts: [AccountType: [Account]]

    /// Currently selected account binding
    let selectedAccount: Binding<Account?>

    /// Callback invoked when an account should be edited
    let onEdit: (Account) -> Void

    /// Callback invoked when an account should be archived/unarchived
    let onArchive: (Account) -> Void

    /// Callback invoked when an account should be shown/hidden
    let onHide: (Account) -> Void

    /// Callback invoked when an account should be deleted
    let onDelete: (Account) -> Void

    /// Account types sorted for display, filtered to only show types with accounts
    var sortedTypes: [AccountType] {
        AccountType.allCases.filter { groupedAccounts[$0]?.isEmpty == false }
    }

    var body: some View {
        ForEach(sortedTypes, id: \.self) { type in
            DisclosureGroup {
                ForEach(groupedAccounts[type] ?? []) { account in
                    Button {
                        selectedAccount.wrappedValue = account
                    } label: {
                        HStack {
                            AccountIcon(iconName: account.iconName, colorHex: account.colorHex, size: .small)
                            Text(account.name)
                                .lineLimit(1)
                            Spacer()
                            BalanceText(amount: account.balance, currencyCode: account.currency, size: .small, compact: true)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                    .accountContextMenu(
                        account: account,
                        onEdit: { onEdit(account) },
                        onArchive: { onArchive(account) },
                        onHide: { onHide(account) },
                        onDelete: { onDelete(account) }
                    )
                }
            } label: {
                Label {
                    Text(type.displayName)
                } icon: {
                    Image(systemName: type.defaultIconName)
                        .foregroundStyle(Color(hex: type.defaultColorHex))
                }
            }
        }
    }
}
