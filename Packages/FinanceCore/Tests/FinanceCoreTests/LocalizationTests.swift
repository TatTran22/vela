import Testing
import Foundation

@testable import FinanceCore

@Suite("CoreStrings Localization Tests")
struct CoreStringsLocalizationTests {
    // MARK: - Transaction Types

    @Test("All transaction type strings are non-empty")
    func transactionTypeStrings() {
        #expect(!CoreStrings.transactionTypeIncome.isEmpty)
        #expect(!CoreStrings.transactionTypeExpense.isEmpty)
        #expect(!CoreStrings.transactionTypeTransfer.isEmpty)
    }

    @Test("TransactionType.displayName uses CoreStrings")
    func transactionTypeDisplayName() {
        #expect(TransactionType.income.displayName == CoreStrings.transactionTypeIncome)
        #expect(TransactionType.expense.displayName == CoreStrings.transactionTypeExpense)
        #expect(TransactionType.transfer.displayName == CoreStrings.transactionTypeTransfer)
    }

    // MARK: - Account Types

    @Test("All account type strings are non-empty")
    func accountTypeStrings() {
        #expect(!CoreStrings.accountTypeCash.isEmpty)
        #expect(!CoreStrings.accountTypeBank.isEmpty)
        #expect(!CoreStrings.accountTypeCreditCard.isEmpty)
        #expect(!CoreStrings.accountTypeEWallet.isEmpty)
        #expect(!CoreStrings.accountTypeSavings.isEmpty)
        #expect(!CoreStrings.accountTypeInvestment.isEmpty)
        #expect(!CoreStrings.accountTypeLoan.isEmpty)
        #expect(!CoreStrings.accountTypeOther.isEmpty)
    }

    @Test("AccountType.displayName uses CoreStrings")
    func accountTypeDisplayName() {
        #expect(AccountType.cash.displayName == CoreStrings.accountTypeCash)
        #expect(AccountType.bank.displayName == CoreStrings.accountTypeBank)
        #expect(AccountType.creditCard.displayName == CoreStrings.accountTypeCreditCard)
        #expect(AccountType.eWallet.displayName == CoreStrings.accountTypeEWallet)
        #expect(AccountType.savings.displayName == CoreStrings.accountTypeSavings)
        #expect(AccountType.investment.displayName == CoreStrings.accountTypeInvestment)
        #expect(AccountType.loan.displayName == CoreStrings.accountTypeLoan)
        #expect(AccountType.other.displayName == CoreStrings.accountTypeOther)
    }

    // MARK: - E-Wallet Providers

    @Test("All e-wallet provider strings are non-empty")
    func ewalletProviderStrings() {
        #expect(!CoreStrings.ewalletMomo.isEmpty)
        #expect(!CoreStrings.ewalletZalopay.isEmpty)
        #expect(!CoreStrings.ewalletVnpay.isEmpty)
        #expect(!CoreStrings.ewalletOther.isEmpty)
    }

    @Test("EWalletProvider.displayName uses CoreStrings")
    func ewalletProviderDisplayName() {
        #expect(EWalletProvider.momo.displayName == CoreStrings.ewalletMomo)
        #expect(EWalletProvider.zalopay.displayName == CoreStrings.ewalletZalopay)
        #expect(EWalletProvider.vnpay.displayName == CoreStrings.ewalletVnpay)
        #expect(EWalletProvider.other.displayName == CoreStrings.ewalletOther)
    }

    // MARK: - Currency Names

    @Test("All currency names are non-empty")
    func currencyNameStrings() {
        for currency in CurrencyCode.allCases {
            let name = CoreStrings.currencyName(currency.rawValue)
            #expect(!name.isEmpty, "Currency name for \(currency.rawValue) should not be empty")
        }
    }

    @Test("CurrencyCode.name uses CoreStrings")
    func currencyCodeName() {
        for currency in CurrencyCode.allCases {
            #expect(currency.name == CoreStrings.currencyName(currency.rawValue))
        }
    }

    // MARK: - Date Strings

    @Test("Date strings are non-empty")
    func dateStrings() {
        #expect(!CoreStrings.dateToday.isEmpty)
        #expect(!CoreStrings.dateYesterday.isEmpty)
    }

    @Test("dateDaysAgo returns non-empty string")
    func dateDaysAgo() {
        let result = CoreStrings.dateDaysAgo(3)
        #expect(!result.isEmpty)
    }
}
