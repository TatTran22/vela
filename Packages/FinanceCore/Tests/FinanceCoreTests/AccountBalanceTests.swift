import Testing
import Foundation

@testable import FinanceCore

@Suite("Account Balance Tests")
struct AccountBalanceTests {
    // MARK: - Delta Update Tests

    @Test("Positive delta increases balance")
    func positiveDeltaIncreasesBalance() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let account = Account(
            name: "Cash",
            type: .cash,
            currency: .VND,
            initialBalance: 100_000,
            balance: 100_000
        )
        try await repository.save(account)

        // Act
        try await repository.updateBalance(account.id, delta: 50_000)

        // Assert
        let updated = try await repository.fetch(by: account.id)
        #expect(updated?.balance == 150_000)
    }

    @Test("Negative delta decreases balance")
    func negativeDeltaDecreasesBalance() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let account = Account(
            name: "Wallet",
            type: .cash,
            currency: .VND,
            initialBalance: 200_000,
            balance: 200_000
        )
        try await repository.save(account)

        // Act
        try await repository.updateBalance(account.id, delta: -75_000)

        // Assert
        let updated = try await repository.fetch(by: account.id)
        #expect(updated?.balance == 125_000)
    }

    @Test("Balance can go negative")
    func balanceCanGoNegative() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let account = Account(
            name: "Credit Card",
            type: .creditCard,
            currency: .VND,
            balance: 50_000
        )
        try await repository.save(account)

        // Act
        try await repository.updateBalance(account.id, delta: -100_000)

        // Assert
        let updated = try await repository.fetch(by: account.id)
        #expect(updated?.balance == -50_000)
    }

    @Test("Delta update on non-existent account throws error")
    func deltaUpdateOnNonExistentThrows() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let fakeID = UUID()

        // Act & Assert
        await #expect(throws: AccountError.self) {
            try await repository.updateBalance(fakeID, delta: 1000)
        }
    }

    // MARK: - Total Balance Tests

    @Test("Total balance sums all active account balances")
    func totalBalanceSumsActive() async throws {
        // Arrange
        let repository = MockAccountRepository()

        let account1 = Account(name: "Cash", type: .cash, currency: .VND, balance: 100_000)
        let account2 = Account(name: "Bank", type: .bank, currency: .VND, balance: 200_000)
        let account3 = Account(name: "Savings", type: .savings, currency: .VND, balance: 300_000)

        try await repository.save(account1)
        try await repository.save(account2)
        try await repository.save(account3)

        // Act
        let total = try await repository.fetchTotalBalance(in: .VND)

        // Assert
        #expect(total == 600_000)
    }

    @Test("Total balance excludes archived accounts")
    func totalBalanceExcludesArchived() async throws {
        // Arrange
        let repository = MockAccountRepository()

        let activeAccount = Account(name: "Active", type: .cash, currency: .VND, balance: 100_000)
        let archivedAccount = Account(
            name: "Archived",
            type: .cash,
            currency: .VND,
            balance: 500_000,
            isArchived: true
        )

        try await repository.save(activeAccount)
        try await repository.save(archivedAccount)

        // Act
        let total = try await repository.fetchTotalBalance(in: .VND)

        // Assert
        #expect(total == 100_000)
    }

    @Test("Total balance excludes hidden accounts")
    func totalBalanceExcludesHidden() async throws {
        // Arrange
        let repository = MockAccountRepository()

        let visibleAccount = Account(name: "Visible", type: .cash, currency: .VND, balance: 100_000)
        let hiddenAccount = Account(
            name: "Hidden",
            type: .cash,
            currency: .VND,
            balance: 500_000,
            isHidden: true
        )

        try await repository.save(visibleAccount)
        try await repository.save(hiddenAccount)

        // Act
        let total = try await repository.fetchTotalBalance(in: .VND)

        // Assert
        #expect(total == 100_000)
    }

    @Test("Total balance excludes soft-deleted accounts")
    func totalBalanceExcludesSoftDeleted() async throws {
        // Arrange
        let repository = MockAccountRepository()

        let activeAccount = Account(name: "Active", type: .cash, currency: .VND, balance: 100_000)
        var deletedAccount = Account(name: "Deleted", type: .cash, currency: .VND, balance: 999_999)
        deletedAccount.deletedAt = Date()

        try await repository.save(activeAccount)
        try await repository.save(deletedAccount)

        // Act
        let total = try await repository.fetchTotalBalance(in: .VND)

        // Assert
        #expect(total == 100_000)
    }

    @Test("Total balance with no accounts is zero")
    func totalBalanceEmptyIsZero() async throws {
        // Arrange
        let repository = MockAccountRepository()

        // Act
        let total = try await repository.fetchTotalBalance(in: .VND)

        // Assert
        #expect(total == 0)
    }

    // MARK: - Active Count Tests

    @Test("Active count excludes archived and deleted accounts")
    func activeCountExclusion() async throws {
        // Arrange
        let repository = MockAccountRepository()

        let active1 = Account(name: "Active 1", type: .cash)
        let active2 = Account(name: "Active 2", type: .bank)
        let archived = Account(name: "Archived", type: .cash, isArchived: true)
        var deleted = Account(name: "Deleted", type: .cash)
        deleted.deletedAt = Date()

        try await repository.save(active1)
        try await repository.save(active2)
        try await repository.save(archived)
        try await repository.save(deleted)

        // Act
        let count = try await repository.fetchActiveCount()

        // Assert
        #expect(count == 2)
    }
}
