import Testing
import Foundation

@testable import FinanceUI

@Suite("UIStrings Localization Tests")
struct UIStringsLocalizationTests {
    // MARK: - Empty States

    @Test("Empty state strings are non-empty")
    func emptyStateStrings() {
        #expect(!UIStrings.noTransactionsTitle.isEmpty)
        #expect(!UIStrings.noTransactionsSubtitle.isEmpty)
        #expect(!UIStrings.noTransactionsAction.isEmpty)
        #expect(!UIStrings.noAccountsTitle.isEmpty)
        #expect(!UIStrings.noAccountsSubtitle.isEmpty)
        #expect(!UIStrings.noAccountsAction.isEmpty)
        #expect(!UIStrings.noResultsTitle.isEmpty)
        #expect(!UIStrings.noResultsSubtitle.isEmpty)
    }

    // MARK: - Sync Status

    @Test("Sync status strings are non-empty")
    func syncStatusStrings() {
        #expect(!UIStrings.syncSynced.isEmpty)
        #expect(!UIStrings.syncSyncing.isEmpty)
        #expect(!UIStrings.syncOffline.isEmpty)
        #expect(!UIStrings.syncError.isEmpty)
    }

    @Test("Sync accessibility strings are non-empty")
    func syncAccessibilityStrings() {
        #expect(!UIStrings.syncAccessibilitySynced.isEmpty)
        #expect(!UIStrings.syncAccessibilitySyncing.isEmpty)
        #expect(!UIStrings.syncAccessibilityOffline.isEmpty)
        #expect(!UIStrings.syncAccessibilityError.isEmpty)
    }

    // MARK: - Premium

    @Test("Premium strings are non-empty")
    func premiumStrings() {
        #expect(!UIStrings.premiumLabel.isEmpty)
        #expect(!UIStrings.premiumAccessibility.isEmpty)
        #expect(!UIStrings.premiumAccessibilityHint.isEmpty)
    }

    // MARK: - Transaction Row

    @Test("Transaction row accessibility string is non-empty")
    func transactionRowStrings() {
        #expect(!UIStrings.transactionRowHint.isEmpty)
    }

    // MARK: - Amount Accessibility

    @Test("Amount accessibility strings are non-empty")
    func amountAccessibilityStrings() {
        #expect(!UIStrings.amountIncome.isEmpty)
        #expect(!UIStrings.amountExpense.isEmpty)
        #expect(!UIStrings.amountTransfer.isEmpty)
    }

    // MARK: - Filter

    @Test("Filter strings are non-empty")
    func filterStrings() {
        #expect(!UIStrings.filterTitle.isEmpty)
        #expect(!UIStrings.filterClearAll.isEmpty)
        #expect(!UIStrings.filterApply.isEmpty)
        #expect(!UIStrings.filterSectionType.isEmpty)
        #expect(!UIStrings.filterSectionDate.isEmpty)
        #expect(!UIStrings.filterSectionAccounts.isEmpty)
        #expect(!UIStrings.filterSectionCategories.isEmpty)
        #expect(!UIStrings.filterSectionAmount.isEmpty)
        #expect(!UIStrings.filterDateAll.isEmpty)
        #expect(!UIStrings.filterDateToday.isEmpty)
        #expect(!UIStrings.filterDateWeek.isEmpty)
        #expect(!UIStrings.filterDateMonth.isEmpty)
        #expect(!UIStrings.filterDateCustom.isEmpty)
        #expect(!UIStrings.filterAmountMin.isEmpty)
        #expect(!UIStrings.filterAmountMax.isEmpty)
        #expect(!UIStrings.filterAmountNoLimit.isEmpty)
    }

    @Test("filterTitleWithCount returns non-empty string")
    func filterTitleWithCount() {
        let result = UIStrings.filterTitleWithCount(3)
        #expect(!result.isEmpty)
    }

    // MARK: - Common

    @Test("Common strings are non-empty")
    func commonStrings() {
        #expect(!UIStrings.noAccountsAvailable.isEmpty)
        #expect(!UIStrings.noCategoriesAvailable.isEmpty)
        #expect(!UIStrings.loadingMessage.isEmpty)
    }
}
