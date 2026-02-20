import Foundation

/// Type-safe accessors for localized strings in the macOS app target.
enum AppStrings {
    // MARK: - Navigation

    static var navFinanceApp: String { String(localized: "nav.financeApp") }
    static var navSelectSection: String { String(localized: "nav.selectSection") }
    static var navDashboard: String { String(localized: "nav.dashboard") }
    static var navTransactions: String { String(localized: "nav.transactions") }
    static var navAccounts: String { String(localized: "nav.accounts") }
    static var navReports: String { String(localized: "nav.reports") }
    static var navSettings: String { String(localized: "nav.settings") }
    static var navCategories: String { String(localized: "nav.categories") }

    // MARK: - Transaction

    static var transactionLoading: String { String(localized: "transaction.loading") }
    static var transactionEmptyTitle: String { String(localized: "transaction.empty.title") }
    static var transactionEmptyNoResults: String { String(localized: "transaction.empty.noResults") }
    static var transactionEmptyAddFirst: String { String(localized: "transaction.empty.addFirst") }
    static var transactionNew: String { String(localized: "transaction.new") }
    static var transactionEdit: String { String(localized: "transaction.edit") }
    static var transactionSearch: String { String(localized: "transaction.search") }
    static var transactionDeleteConfirm: String { String(localized: "transaction.deleteConfirm") }
    static var transactionDuplicate: String { String(localized: "transaction.duplicate") }
    static var transactionRefresh: String { String(localized: "transaction.refresh") }

    // MARK: - Transaction Table

    static var tableDate: String { String(localized: "transaction.table.date") }
    static var tableCategory: String { String(localized: "transaction.table.category") }
    static var tableNote: String { String(localized: "transaction.table.note") }
    static var tableAmount: String { String(localized: "transaction.table.amount") }
    static var tableAccount: String { String(localized: "transaction.table.account") }

    // MARK: - Transaction Entry

    static var entryType: String { String(localized: "transaction.entry.type") }
    static var entryAmount: String { String(localized: "transaction.entry.amount") }
    static var entryCategory: String { String(localized: "transaction.entry.category") }
    static var entrySelectCategory: String { String(localized: "transaction.entry.selectCategory") }
    static var entryNoCategoriesAvailable: String { String(localized: "transaction.entry.noCategoriesAvailable") }
    static var entryAccount: String { String(localized: "transaction.entry.account") }
    static var entryFromAccount: String { String(localized: "transaction.entry.fromAccount") }
    static var entrySelectAccount: String { String(localized: "transaction.entry.selectAccount") }
    static var entryNoAccountsAvailable: String { String(localized: "transaction.entry.noAccountsAvailable") }
    static var entryTransferDestination: String { String(localized: "transaction.entry.transferDestination") }
    static var entryToAccount: String { String(localized: "transaction.entry.toAccount") }
    static var entrySelectDestination: String { String(localized: "transaction.entry.selectDestination") }
    static var entryExchangeRate: String { String(localized: "transaction.entry.exchangeRate") }
    static var entryDate: String { String(localized: "transaction.entry.date") }
    static var entryNote: String { String(localized: "transaction.entry.note") }
    static var entryOptionalDescription: String { String(localized: "transaction.entry.optionalDescription") }

    // MARK: - Accounts

    static var accountEmptyTitle: String { String(localized: "account.empty.title") }
    static var accountEmptySubtitle: String { String(localized: "account.empty.subtitle") }
    static var accountNew: String { String(localized: "account.new") }
    static var accountEdit: String { String(localized: "account.edit") }
    static var accountSelectAccount: String { String(localized: "account.selectAccount") }

    // MARK: - Account Detail

    static var accountDetailIncome: String { String(localized: "account.detail.income") }
    static var accountDetailExpense: String { String(localized: "account.detail.expense") }
    static var accountDetailNet: String { String(localized: "account.detail.net") }
    static var accountDetailRecentTransactions: String { String(localized: "account.detail.recentTransactions") }
    static var accountDetailNoTransactions: String { String(localized: "account.detail.noTransactions") }
    static var accountDetailTransactionsPlaceholder: String { String(localized: "account.detail.transactionsPlaceholder") }

    // MARK: - Account Context Menu

    static var contextEdit: String { String(localized: "account.context.edit") }
    static var contextArchive: String { String(localized: "account.context.archive") }
    static var contextUnarchive: String { String(localized: "account.context.unarchive") }
    static var contextShow: String { String(localized: "account.context.show") }
    static var contextHide: String { String(localized: "account.context.hide") }
    static var contextDelete: String { String(localized: "account.context.delete") }

    // MARK: - Account Edit

    static var editGeneral: String { String(localized: "account.edit.general") }
    static var editAccountName: String { String(localized: "account.edit.accountName") }
    static var editNamePlaceholder: String { String(localized: "account.edit.namePlaceholder") }
    static var editAppearance: String { String(localized: "account.edit.appearance") }
    static var editIcon: String { String(localized: "account.edit.icon") }
    static var editColor: String { String(localized: "account.edit.color") }
    static var editChooseColor: String { String(localized: "account.edit.chooseColor") }
    static var editCurrency: String { String(localized: "account.edit.currency") }
    static var editCurrencyCannotChange: String { String(localized: "account.edit.currencyCannotChange") }
    static var editInitialBalance: String { String(localized: "account.edit.initialBalance") }
    static var editNotes: String { String(localized: "account.edit.notes") }
    static var editOptionalNotes: String { String(localized: "account.edit.optionalNotes") }
    static var editNameRequired: String { String(localized: "account.edit.nameRequired") }
    static var editNameExists: String { String(localized: "account.edit.nameExists") }
    static var editProvider: String { String(localized: "account.edit.provider") }

    // MARK: - Categories

    static var categoryListTitle: String { String(localized: "category.list.title") }
    static var categoryNew: String { String(localized: "category.new") }
    static var categoryEdit: String { String(localized: "category.edit") }
    static var categoryDelete: String { String(localized: "category.delete") }
    static var categoryArchive: String { String(localized: "category.archive") }
    static var categoryAddSubcategory: String { String(localized: "category.addSubcategory") }
    static var categoryEditName: String { String(localized: "category.edit.name") }
    static var categoryEditType: String { String(localized: "category.edit.type") }
    static var categoryEditParent: String { String(localized: "category.edit.parent") }
    static var categoryEditIcon: String { String(localized: "category.edit.icon") }
    static var categoryEditColor: String { String(localized: "category.edit.color") }
    static var categoryEditPreview: String { String(localized: "category.edit.preview") }
    static var categoryNoParent: String { String(localized: "category.noParent") }
    static var categoryEmptyTitle: String { String(localized: "category.empty.title") }
    static var categoryEmptySubtitle: String { String(localized: "category.empty.subtitle") }
    static var categorySubcategories: String { String(localized: "category.subcategories") }
    static var categoryExpense: String { String(localized: "category.type.expense") }
    static var categoryIncome: String { String(localized: "category.type.income") }

    // MARK: - Common

    static var cancel: String { String(localized: "common.cancel") }
    static var save: String { String(localized: "common.save") }
    static var delete: String { String(localized: "common.delete") }
    static var edit: String { String(localized: "common.edit") }
    static var ok: String { String(localized: "common.ok") }
    static var error: String { String(localized: "common.error") }
}
