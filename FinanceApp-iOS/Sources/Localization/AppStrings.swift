import Foundation

/// Type-safe accessors for localized strings in the iOS app target.
enum AppStrings {
    // MARK: - Tabs

    static var tabDashboard: String { String(localized: "tab.dashboard") }
    static var tabTransactions: String { String(localized: "tab.transactions") }
    static var tabAccounts: String { String(localized: "tab.accounts") }
    static var tabReports: String { String(localized: "tab.reports") }
    static var tabSettings: String { String(localized: "tab.settings") }

    // MARK: - Transaction List

    static var transactionListTitle: String { String(localized: "transaction.list.title") }
    static var transactionListSearchPrompt: String { String(localized: "transaction.list.searchPrompt") }
    static var transactionListEmptyTitle: String { String(localized: "transaction.list.empty.title") }
    static var transactionListEmptySubtitle: String { String(localized: "transaction.list.empty.subtitle") }
    static var transactionListEmptyAction: String { String(localized: "transaction.list.empty.action") }

    // MARK: - Transaction Detail

    static var transactionDetailTitle: String { String(localized: "transaction.detail.title") }
    static var transactionDetailEditTitle: String { String(localized: "transaction.detail.editTitle") }
    static var transactionDetailDeleteTitle: String { String(localized: "transaction.detail.deleteTitle") }
    static var transactionDetailDeleteMessage: String { String(localized: "transaction.detail.deleteMessage") }
    static var transactionDetailCategory: String { String(localized: "transaction.detail.category") }
    static var transactionDetailAccount: String { String(localized: "transaction.detail.account") }
    static var transactionDetailToAccount: String { String(localized: "transaction.detail.toAccount") }
    static var transactionDetailDate: String { String(localized: "transaction.detail.date") }
    static var transactionDetailNote: String { String(localized: "transaction.detail.note") }
    static var transactionDetailTags: String { String(localized: "transaction.detail.tags") }
    static var transactionDetailAmount: String { String(localized: "transaction.detail.amount") }
    static var transactionDetailUnknown: String { String(localized: "transaction.detail.unknown") }

    // MARK: - Quick Input

    static var quickInputTitleAmount: String { String(localized: "quickInput.title.amount") }
    static var quickInputTitleCategory: String { String(localized: "quickInput.title.category") }
    static var quickInputTitleReview: String { String(localized: "quickInput.title.review") }
    static var quickInputNextCategory: String { String(localized: "quickInput.nextCategory") }
    static var quickInputAddDetails: String { String(localized: "quickInput.addDetails") }
    static var quickInputDetails: String { String(localized: "quickInput.details") }
    static var quickInputNoCategory: String { String(localized: "quickInput.noCategory") }
    static var quickInputNoAccount: String { String(localized: "quickInput.noAccount") }
    static var quickInputOptionalNote: String { String(localized: "quickInput.optionalNote") }
    static var quickInputSaveTransaction: String { String(localized: "quickInput.saveTransaction") }

    // MARK: - Transfer

    static var transferTitle: String { String(localized: "transfer.title") }
    static var transferFromTo: String { String(localized: "transfer.fromTo") }
    static var transferFrom: String { String(localized: "transfer.from") }
    static var transferTo: String { String(localized: "transfer.to") }
    static var transferNoAccount: String { String(localized: "transfer.noAccount") }
    static var transferSelect: String { String(localized: "transfer.select") }
    static var transferAmount: String { String(localized: "transfer.amount") }
    static var transferExchangeRate: String { String(localized: "transfer.exchangeRate") }
    static var transferRate: String { String(localized: "transfer.rate") }
    static var transferYouReceive: String { String(localized: "transfer.youReceive") }
    static var transferFeeOptional: String { String(localized: "transfer.feeOptional") }
    static var transferNoteOptional: String { String(localized: "transfer.noteOptional") }
    static var transferAddNote: String { String(localized: "transfer.addNote") }

    // MARK: - Account List

    static var accountListTitle: String { String(localized: "account.list.title") }
    static var accountListTotalBalance: String { String(localized: "account.list.totalBalance") }
    static var accountListEmptyTitle: String { String(localized: "account.list.empty.title") }
    static var accountListEmptySubtitle: String { String(localized: "account.list.empty.subtitle") }
    static var accountListEmptyAction: String { String(localized: "account.list.empty.action") }

    // MARK: - Account Detail

    static var accountDetailIncome: String { String(localized: "account.detail.income") }
    static var accountDetailExpense: String { String(localized: "account.detail.expense") }
    static var accountDetailRecentTransactions: String { String(localized: "account.detail.recentTransactions") }
    static var accountDetailNoTransactions: String { String(localized: "account.detail.noTransactions") }
    static var accountDetailTransactionsWillAppear: String { String(localized: "account.detail.transactionsWillAppear") }
    static var accountDetailAdjustBalance: String { String(localized: "account.detail.adjustBalance") }
    static var accountDetailDeleteAccount: String { String(localized: "account.detail.deleteAccount") }
    static var accountDetailDeleteConfirmMessage: String { String(localized: "account.detail.deleteConfirmMessage") }

    // MARK: - Account Edit

    static var accountEditNewTitle: String { String(localized: "account.edit.newTitle") }
    static var accountEditEditTitle: String { String(localized: "account.edit.editTitle") }
    static var accountEditNamePlaceholder: String { String(localized: "account.edit.namePlaceholder") }
    static var accountEditSectionName: String { String(localized: "account.edit.sectionName") }
    static var accountEditSectionType: String { String(localized: "account.edit.sectionType") }
    static var accountEditSectionAppearance: String { String(localized: "account.edit.sectionAppearance") }
    static var accountEditSectionCurrency: String { String(localized: "account.edit.sectionCurrency") }
    static var accountEditSectionBalance: String { String(localized: "account.edit.sectionBalance") }
    static var accountEditSectionNotes: String { String(localized: "account.edit.sectionNotes") }
    static var accountEditIcon: String { String(localized: "account.edit.icon") }
    static var accountEditColor: String { String(localized: "account.edit.color") }
    static var accountEditChooseColor: String { String(localized: "account.edit.chooseColor") }
    static var accountEditCurrencyCannotChange: String { String(localized: "account.edit.currencyCannotChange") }
    static var accountEditOptionalNotes: String { String(localized: "account.edit.optionalNotes") }
    static var accountEditProvider: String { String(localized: "account.edit.provider") }

    // MARK: - Balance Adjust

    static var balanceAdjustTitle: String { String(localized: "balance.adjust.title") }
    static var balanceAdjustCurrentBalance: String { String(localized: "balance.adjust.currentBalance") }
    static var balanceAdjustAdjustmentAmount: String { String(localized: "balance.adjust.adjustmentAmount") }
    static var balanceAdjustAmountPlaceholder: String { String(localized: "balance.adjust.amountPlaceholder") }
    static var balanceAdjustHint: String { String(localized: "balance.adjust.hint") }
    static var balanceAdjustNewBalance: String { String(localized: "balance.adjust.newBalance") }

    // MARK: - Common

    static var cancel: String { String(localized: "common.cancel") }
    static var save: String { String(localized: "common.save") }
    static var delete: String { String(localized: "common.delete") }
    static var edit: String { String(localized: "common.edit") }
    static var ok: String { String(localized: "common.ok") }
    static var error: String { String(localized: "common.error") }
    static var back: String { String(localized: "common.back") }
    static var apply: String { String(localized: "common.apply") }
    static var archive: String { String(localized: "common.archive") }
    static var show: String { String(localized: "common.show") }
    static var hide: String { String(localized: "common.hide") }
    static var none: String { String(localized: "common.none") }

    // MARK: - Categories

    static var categoryListTitle: String { String(localized: "category.list.title") }
    static var categoryListEmptyTitle: String { String(localized: "category.list.empty.title") }
    static var categoryListEmptySubtitle: String { String(localized: "category.list.empty.subtitle") }
    static var categoryListEmptyAction: String { String(localized: "category.list.empty.action") }
    static var categoryEditNewTitle: String { String(localized: "category.edit.newTitle") }
    static var categoryEditEditTitle: String { String(localized: "category.edit.editTitle") }
    static var categoryEditName: String { String(localized: "category.edit.name") }
    static var categoryEditType: String { String(localized: "category.edit.type") }
    static var categoryEditParent: String { String(localized: "category.edit.parent") }
    static var categoryEditIcon: String { String(localized: "category.edit.icon") }
    static var categoryEditColor: String { String(localized: "category.edit.color") }
    static var categoryEditPreview: String { String(localized: "category.edit.preview") }
    static var categoryEditNoParent: String { String(localized: "category.edit.noParent") }
    static var categoryDetailSubcategories: String { String(localized: "category.detail.subcategories") }
    static var categoryExpense: String { String(localized: "category.type.expense") }
    static var categoryIncome: String { String(localized: "category.type.income") }
    static var tabCategories: String { String(localized: "tab.categories") }

    // MARK: - Placeholders

    static var placeholderDashboard: String { String(localized: "placeholder.dashboard") }
    static var placeholderCategories: String { String(localized: "placeholder.categories") }
    static var placeholderReports: String { String(localized: "placeholder.reports") }
    static var placeholderSettings: String { String(localized: "placeholder.settings") }
    static var placeholderOnboarding: String { String(localized: "placeholder.onboarding") }
}
