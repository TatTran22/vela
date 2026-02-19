import Foundation
import SwiftData
import Testing

@testable import FinanceCore
@testable import FinanceData

@Suite("AccountRepository Tests")
struct AccountRepositoryTests {
    private func createTestContainer() throws -> ModelContainer {
        try ModelContainerSetup.createContainer(inMemory: true)
    }

    @Test("Fetch all accounts returns empty array initially")
    func fetchAllEmpty() async throws {
        let container = try createTestContainer()
        let repository = AccountRepository(modelContainer: container)

        let accounts = try await repository.fetchAll()
        #expect(accounts.isEmpty)
    }

    @Test("Save and fetch account by ID")
    func saveAndFetchByID() async throws {
        let container = try createTestContainer()
        let repository = AccountRepository(modelContainer: container)

        let account = Account(
            name: "Test Account",
            type: .cash,
            currency: .VND,
            balance: 1000
        )

        try await repository.save(account)
        let fetched = try await repository.fetch(by: account.id)

        #expect(fetched != nil)
        #expect(fetched?.name == "Test Account")
        #expect(fetched?.type == .cash)
        #expect(fetched?.balance == 1000)
    }

    @Test("Update existing account")
    func updateAccount() async throws {
        let container = try createTestContainer()
        let repository = AccountRepository(modelContainer: container)

        var account = Account(
            name: "Original Name",
            type: .bank,
            currency: .USD
        )

        try await repository.save(account)

        account.name = "Updated Name"
        account.balance = 5000

        try await repository.save(account)
        let fetched = try await repository.fetch(by: account.id)

        #expect(fetched?.name == "Updated Name")
        #expect(fetched?.balance == 5000)
    }

    @Test("Soft delete account")
    func softDeleteAccount() async throws {
        let container = try createTestContainer()
        let repository = AccountRepository(modelContainer: container)

        let account = Account(
            name: "To Be Deleted",
            type: .cash
        )

        try await repository.save(account)
        try await repository.delete(by: account.id)

        let fetched = try await repository.fetch(by: account.id)
        #expect(fetched == nil)

        let allAccounts = try await repository.fetchAll()
        #expect(allAccounts.isEmpty)
    }

    @Test("Delete non-existent account throws error")
    func deleteNonExistentAccount() async throws {
        let container = try createTestContainer()
        let repository = AccountRepository(modelContainer: container)

        let randomID = UUID()

        await #expect(throws: AccountError.accountNotFound(randomID)) {
            try await repository.delete(by: randomID)
        }
    }

    @Test("Fetch accounts grouped by type")
    func fetchGroupedByType() async throws {
        let container = try createTestContainer()
        let repository = AccountRepository(modelContainer: container)

        let cashAccount = Account(name: "Cash", type: .cash)
        let bankAccount1 = Account(name: "Bank 1", type: .bank)
        let bankAccount2 = Account(name: "Bank 2", type: .bank)

        try await repository.save(cashAccount)
        try await repository.save(bankAccount1)
        try await repository.save(bankAccount2)

        let grouped = try await repository.fetchGroupedByType()

        #expect(grouped[.cash]?.count == 1)
        #expect(grouped[.bank]?.count == 2)
    }

    @Test("Fetch total balance in specific currency")
    func fetchTotalBalance() async throws {
        let container = try createTestContainer()
        let repository = AccountRepository(modelContainer: container)

        let account1 = Account(name: "VND 1", type: .cash, currency: .VND, balance: 1000)
        let account2 = Account(name: "VND 2", type: .bank, currency: .VND, balance: 2000)
        let account3 = Account(name: "USD", type: .bank, currency: .USD, balance: 500)

        try await repository.save(account1)
        try await repository.save(account2)
        try await repository.save(account3)

        let vndTotal = try await repository.fetchTotalBalance(in: .VND)
        let usdTotal = try await repository.fetchTotalBalance(in: .USD)

        #expect(vndTotal == 3000)
        #expect(usdTotal == 500)
    }

    @Test("Update account balance")
    func updateBalance() async throws {
        let container = try createTestContainer()
        let repository = AccountRepository(modelContainer: container)

        let account = Account(name: "Test", type: .cash, balance: 1000)
        try await repository.save(account)

        try await repository.updateBalance(account.id, delta: 500)
        let updated = try await repository.fetch(by: account.id)
        #expect(updated?.balance == 1500)

        try await repository.updateBalance(account.id, delta: -300)
        let updated2 = try await repository.fetch(by: account.id)
        #expect(updated2?.balance == 1200)
    }

    @Test("Fetch active count excludes archived and deleted")
    func fetchActiveCount() async throws {
        let container = try createTestContainer()
        let repository = AccountRepository(modelContainer: container)

        let active = Account(name: "Active", type: .cash, isArchived: false)
        let archived = Account(name: "Archived", type: .bank, isArchived: true)
        let deleted = Account(name: "Deleted", type: .creditCard, deletedAt: Date())

        try await repository.save(active)
        try await repository.save(archived)
        try await repository.save(deleted)

        let count = try await repository.fetchActiveCount()
        #expect(count == 1)
    }

    @Test("Update sort orders")
    func updateSortOrders() async throws {
        let container = try createTestContainer()
        let repository = AccountRepository(modelContainer: container)

        let account1 = Account(name: "First", type: .cash, sortOrder: 0)
        let account2 = Account(name: "Second", type: .bank, sortOrder: 1)

        try await repository.save(account1)
        try await repository.save(account2)

        let orders = [(account1.id, 10), (account2.id, 5)]
        try await repository.updateSortOrders(orders)

        let updated1 = try await repository.fetch(by: account1.id)
        let updated2 = try await repository.fetch(by: account2.id)

        #expect(updated1?.sortOrder == 10)
        #expect(updated2?.sortOrder == 5)
    }

    @Test("Fetch all returns accounts sorted by sort order")
    func fetchAllSorted() async throws {
        let container = try createTestContainer()
        let repository = AccountRepository(modelContainer: container)

        let account1 = Account(name: "Third", type: .cash, sortOrder: 3)
        let account2 = Account(name: "First", type: .bank, sortOrder: 1)
        let account3 = Account(name: "Second", type: .creditCard, sortOrder: 2)

        try await repository.save(account1)
        try await repository.save(account2)
        try await repository.save(account3)

        let accounts = try await repository.fetchAll()

        #expect(accounts.count == 3)
        #expect(accounts[0].name == "First")
        #expect(accounts[1].name == "Second")
        #expect(accounts[2].name == "Third")
    }
}
