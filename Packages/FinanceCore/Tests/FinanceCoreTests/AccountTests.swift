import Testing

@testable import FinanceCore

@Suite("Account Model Tests")
struct AccountTests {
    @Test("Create account with defaults")
    func createAccountWithDefaults() {
        let account = Account(name: "Cash", type: .cash)

        #expect(account.name == "Cash")
        #expect(account.type == .cash)
        #expect(account.currency == "VND")
        #expect(account.initialBalance == 0)
        #expect(account.isArchived == false)
    }

    @Test("Account types are exhaustive")
    func accountTypesExist() {
        let allTypes = AccountType.allCases
        #expect(allTypes.count == 7)
    }
}
