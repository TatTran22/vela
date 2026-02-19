import Testing
import Foundation

@testable import FinanceCore

@Suite("ReorderAccountsUseCase Tests")
struct ReorderAccountsUseCaseTests {
    @Test("Reorder updates sort orders correctly")
    func reorderUpdatesSortOrders() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = ReorderAccountsUseCase(repository: repository)

        let account1 = Account(name: "First", type: .cash)
        let account2 = Account(name: "Second", type: .bank)
        let account3 = Account(name: "Third", type: .creditCard)

        try await repository.save(account1)
        try await repository.save(account2)
        try await repository.save(account3)

        // Act - reorder to: Third, First, Second
        try await useCase.execute(orderedIDs: [account3.id, account1.id, account2.id])

        // Assert
        let updated1 = try await repository.fetch(by: account1.id)
        let updated2 = try await repository.fetch(by: account2.id)
        let updated3 = try await repository.fetch(by: account3.id)

        #expect(updated3?.sortOrder == 0)
        #expect(updated1?.sortOrder == 1)
        #expect(updated2?.sortOrder == 2)
    }

    @Test("Reorder with empty list does not throw")
    func reorderEmptyList() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = ReorderAccountsUseCase(repository: repository)

        // Act & Assert - should not throw
        try await useCase.execute(orderedIDs: [])
    }

    @Test("Reorder single item sets sort order to 0")
    func reorderSingleItem() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = ReorderAccountsUseCase(repository: repository)

        let account = Account(name: "Only", type: .cash, sortOrder: 5)
        try await repository.save(account)

        // Act
        try await useCase.execute(orderedIDs: [account.id])

        // Assert
        let updated = try await repository.fetch(by: account.id)
        #expect(updated?.sortOrder == 0)
    }

    @Test("Reorder preserves other account data")
    func reorderPreservesData() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = ReorderAccountsUseCase(repository: repository)

        let account = Account(
            name: "Savings",
            type: .savings,
            currency: .USD,
            initialBalance: 1000,
            balance: 1500,
            note: "My savings"
        )
        try await repository.save(account)

        // Act
        try await useCase.execute(orderedIDs: [account.id])

        // Assert
        let updated = try await repository.fetch(by: account.id)
        #expect(updated?.name == "Savings")
        #expect(updated?.type == .savings)
        #expect(updated?.currency == .USD)
        #expect(updated?.balance == 1500)
        #expect(updated?.note == "My savings")
    }

    // MARK: - Test: offset parameter prevents cross-section collision

    @Test("Reorder with offset assigns sort orders starting from offset")
    func reorderWithOffset() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = ReorderAccountsUseCase(repository: repository)

        let account1 = Account(name: "BankA", type: .bank)
        let account2 = Account(name: "BankB", type: .bank)

        try await repository.save(account1)
        try await repository.save(account2)

        // Act — simulate that 3 cash accounts occupy sortOrders 0-2, so bank section
        // starts at offset 3
        try await useCase.execute(orderedIDs: [account2.id, account1.id], startingAt: 3)

        // Assert — sort orders should be 3 and 4, not 0 and 1
        let updatedA = try await repository.fetch(by: account1.id)
        let updatedB = try await repository.fetch(by: account2.id)

        #expect(updatedB?.sortOrder == 3)
        #expect(updatedA?.sortOrder == 4)
    }

    @Test("Reorder with zero offset behaves identically to default")
    func reorderWithZeroOffset() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = ReorderAccountsUseCase(repository: repository)

        let account1 = Account(name: "Cash A", type: .cash)
        let account2 = Account(name: "Cash B", type: .cash)

        try await repository.save(account1)
        try await repository.save(account2)

        // Act — explicit offset of 0 should be identical to the default
        try await useCase.execute(orderedIDs: [account1.id, account2.id], startingAt: 0)

        // Assert
        let updatedA = try await repository.fetch(by: account1.id)
        let updatedB = try await repository.fetch(by: account2.id)

        #expect(updatedA?.sortOrder == 0)
        #expect(updatedB?.sortOrder == 1)
    }
}
