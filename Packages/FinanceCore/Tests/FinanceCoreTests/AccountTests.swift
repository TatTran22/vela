import Testing

@testable import FinanceCore

@Suite("Account Model Tests")
struct AccountTests {
    @Test("Create account with defaults")
    func createAccountWithDefaults() {
        let account = Account(name: "Cash", type: .cash)

        #expect(account.name == "Cash")
        #expect(account.type == .cash)
        #expect(account.currency == .VND)
        #expect(account.initialBalance == 0)
        #expect(account.balance == 0)
        #expect(account.isArchived == false)
        #expect(account.isHidden == false)
        #expect(account.sortOrder == 0)
        #expect(account.note == nil)
        #expect(account.eWalletProvider == nil)
        #expect(account.deletedAt == nil)
    }

    @Test("Account types are exhaustive")
    func accountTypesExist() {
        let allTypes = AccountType.allCases
        #expect(allTypes.count == 8) // Updated to 8 to include .loan
    }

    @Test("Account type display properties")
    func accountTypeDisplayProperties() {
        let bankType = AccountType.bank
        #expect(bankType.displayName == "Bank")
        #expect(bankType.defaultIconName == "building.columns")
        #expect(bankType.defaultColorHex == "#007AFF")

        let loanType = AccountType.loan
        #expect(loanType.displayName == "Loan")
        #expect(loanType.defaultIconName == "doc.text")
        #expect(loanType.defaultColorHex == "#FF3B30")
    }

    @Test("Account with e-wallet provider")
    func accountWithEWallet() {
        let account = Account(
            name: "MoMo Wallet",
            type: .eWallet,
            currency: .VND,
            eWalletProvider: .momo
        )

        #expect(account.type == .eWallet)
        #expect(account.eWalletProvider == .momo)
        #expect(account.eWalletProvider?.displayName == "MoMo")
        #expect(account.eWalletProvider?.iconName == "m.circle.fill")
    }

    @Test("Account with different currency")
    func accountWithDifferentCurrency() {
        let account = Account(
            name: "USD Savings",
            type: .savings,
            currency: .USD,
            initialBalance: 1000,
            balance: 1000
        )

        #expect(account.currency == .USD)
        #expect(account.currency.symbol == "$")
        #expect(account.currency.decimalPlaces == 2)
    }
}
