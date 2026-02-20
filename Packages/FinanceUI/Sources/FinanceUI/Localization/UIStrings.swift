import Foundation

/// Type-safe accessors for localized strings in the FinanceUI module.
public enum UIStrings {
    // MARK: - Empty States

    public static var noTransactionsTitle: String { String(localized: "empty.noTransactions.title", bundle: .module) }
    public static var noTransactionsSubtitle: String { String(localized: "empty.noTransactions.subtitle", bundle: .module) }
    public static var noTransactionsAction: String { String(localized: "empty.noTransactions.action", bundle: .module) }

    public static var noAccountsTitle: String { String(localized: "empty.noAccounts.title", bundle: .module) }
    public static var noAccountsSubtitle: String { String(localized: "empty.noAccounts.subtitle", bundle: .module) }
    public static var noAccountsAction: String { String(localized: "empty.noAccounts.action", bundle: .module) }

    public static var noResultsTitle: String { String(localized: "empty.noResults.title", bundle: .module) }
    public static var noResultsSubtitle: String { String(localized: "empty.noResults.subtitle", bundle: .module) }

    // MARK: - Sync Status

    public static var syncSynced: String { String(localized: "sync.synced", bundle: .module) }
    public static var syncSyncing: String { String(localized: "sync.syncing", bundle: .module) }
    public static var syncOffline: String { String(localized: "sync.offline", bundle: .module) }
    public static var syncError: String { String(localized: "sync.error", bundle: .module) }

    public static var syncAccessibilitySynced: String { String(localized: "sync.accessibility.synced", bundle: .module) }
    public static var syncAccessibilitySyncing: String { String(localized: "sync.accessibility.syncing", bundle: .module) }
    public static var syncAccessibilityOffline: String { String(localized: "sync.accessibility.offline", bundle: .module) }
    public static var syncAccessibilityError: String { String(localized: "sync.accessibility.error", bundle: .module) }

    // MARK: - Premium

    public static var premiumLabel: String { String(localized: "premium.label", bundle: .module) }
    public static var premiumAccessibility: String { String(localized: "premium.accessibility", bundle: .module) }
    public static var premiumAccessibilityHint: String { String(localized: "premium.accessibility.hint", bundle: .module) }

    // MARK: - Transaction Row

    public static var transactionRowHint: String { String(localized: "transaction.row.accessibility.hint", bundle: .module) }

    // MARK: - Amount Accessibility

    public static var amountIncome: String { String(localized: "amount.accessibility.income", bundle: .module) }
    public static var amountExpense: String { String(localized: "amount.accessibility.expense", bundle: .module) }
    public static var amountTransfer: String { String(localized: "amount.accessibility.transfer", bundle: .module) }

    // MARK: - Filter

    public static var filterTitle: String { String(localized: "filter.title", bundle: .module) }
    public static func filterTitleWithCount(_ count: Int) -> String {
        String(localized: "filter.titleWithCount", bundle: .module).replacingOccurrences(of: "%lld", with: "\(count)")
    }
    public static var filterClearAll: String { String(localized: "filter.clearAll", bundle: .module) }
    public static var filterApply: String { String(localized: "filter.apply", bundle: .module) }
    public static var filterSectionType: String { String(localized: "filter.section.type", bundle: .module) }
    public static var filterSectionDate: String { String(localized: "filter.section.date", bundle: .module) }
    public static var filterSectionAccounts: String { String(localized: "filter.section.accounts", bundle: .module) }
    public static var filterSectionCategories: String { String(localized: "filter.section.categories", bundle: .module) }
    public static var filterSectionAmount: String { String(localized: "filter.section.amount", bundle: .module) }
    public static var filterDateAll: String { String(localized: "filter.date.all", bundle: .module) }
    public static var filterDateToday: String { String(localized: "filter.date.today", bundle: .module) }
    public static var filterDateWeek: String { String(localized: "filter.date.week", bundle: .module) }
    public static var filterDateMonth: String { String(localized: "filter.date.month", bundle: .module) }
    public static var filterDateCustom: String { String(localized: "filter.date.custom", bundle: .module) }
    public static var filterAmountMin: String { String(localized: "filter.amount.min", bundle: .module) }
    public static var filterAmountMax: String { String(localized: "filter.amount.max", bundle: .module) }
    public static var filterAmountNoLimit: String { String(localized: "filter.amount.noLimit", bundle: .module) }

    // MARK: - Common

    public static var noAccountsAvailable: String { String(localized: "common.noAccountsAvailable", bundle: .module) }
    public static var noCategoriesAvailable: String { String(localized: "common.noCategoriesAvailable", bundle: .module) }
    public static var loadingMessage: String { String(localized: "loading.message", bundle: .module) }
}
