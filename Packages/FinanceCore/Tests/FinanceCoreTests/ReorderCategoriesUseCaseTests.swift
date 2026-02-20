import Testing
import Foundation

@testable import FinanceCore

@Suite("ReorderCategoriesUseCase Tests")
struct ReorderCategoriesUseCaseTests {
    // MARK: - Test: Reorder updates sortOrder correctly

    @Test("Reorder updates sortOrder for all categories in the provided order")
    func reorderUpdatesSortOrderCorrectly() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let cat1 = FinanceCategory(name: "First", type: .expense, sortOrder: 0)
        let cat2 = FinanceCategory(name: "Second", type: .expense, sortOrder: 1)
        let cat3 = FinanceCategory(name: "Third", type: .expense, sortOrder: 2)
        await repository.seed(cat1)
        await repository.seed(cat2)
        await repository.seed(cat3)
        let useCase = ReorderCategoriesUseCase(repository: repository)

        // Act — reverse the order
        try await useCase.execute(orderedIDs: [cat3.id, cat2.id, cat1.id])

        // Assert
        let updated1 = try await repository.fetch(by: cat1.id)
        let updated2 = try await repository.fetch(by: cat2.id)
        let updated3 = try await repository.fetch(by: cat3.id)
        #expect(updated3?.sortOrder == 0)
        #expect(updated2?.sortOrder == 1)
        #expect(updated1?.sortOrder == 2)
    }

    @Test("Reorder preserves category data beyond sortOrder")
    func reorderPreservesCategoryData() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let category = FinanceCategory(
            name: "Food",
            iconName: "fork.knife",
            colorHex: "#FF0000",
            type: .expense,
            sortOrder: 5
        )
        await repository.seed(category)
        let useCase = ReorderCategoriesUseCase(repository: repository)

        // Act
        try await useCase.execute(orderedIDs: [category.id])

        // Assert
        let updated = try await repository.fetch(by: category.id)
        #expect(updated?.name == "Food")
        #expect(updated?.type == .expense)
        #expect(updated?.iconName == "fork.knife")
        #expect(updated?.colorHex == "#FF0000")
        #expect(updated?.sortOrder == 0)
    }

    // MARK: - Test: Empty list is a no-op

    @Test("Reorder with empty list does not throw")
    func reorderEmptyListIsNoOp() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let useCase = ReorderCategoriesUseCase(repository: repository)

        // Act & Assert — should not throw
        try await useCase.execute(orderedIDs: [], startingAt: 0)
    }

    @Test("Reorder with empty list leaves existing categories unchanged")
    func reorderEmptyListDoesNotChangeSortOrders() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let cat = FinanceCategory(name: "Stable", type: .expense, sortOrder: 7)
        await repository.seed(cat)
        let useCase = ReorderCategoriesUseCase(repository: repository)

        // Act
        try await useCase.execute(orderedIDs: [])

        // Assert — sortOrder unchanged
        let fetched = try await repository.fetch(by: cat.id)
        #expect(fetched?.sortOrder == 7)
    }

    // MARK: - Test: Offset is applied correctly

    @Test("Reorder with offset assigns sortOrders starting from the offset value")
    func reorderWithOffsetAppliesCorrectly() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let catA = FinanceCategory(name: "Cat A", type: .expense, sortOrder: 0)
        let catB = FinanceCategory(name: "Cat B", type: .expense, sortOrder: 1)
        await repository.seed(catA)
        await repository.seed(catB)
        let useCase = ReorderCategoriesUseCase(repository: repository)

        // Act — offset of 10 means first item gets sortOrder 10, second gets 11
        try await useCase.execute(orderedIDs: [catA.id, catB.id], startingAt: 10)

        // Assert
        let updatedA = try await repository.fetch(by: catA.id)
        let updatedB = try await repository.fetch(by: catB.id)
        #expect(updatedA?.sortOrder == 10)
        #expect(updatedB?.sortOrder == 11)
    }

    @Test("Reorder with zero offset behaves like default (sortOrders start at 0)")
    func reorderWithZeroOffsetStartsAtZero() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let cat1 = FinanceCategory(name: "Alpha", type: .income, sortOrder: 99)
        let cat2 = FinanceCategory(name: "Beta", type: .income, sortOrder: 100)
        await repository.seed(cat1)
        await repository.seed(cat2)
        let useCase = ReorderCategoriesUseCase(repository: repository)

        // Act
        try await useCase.execute(orderedIDs: [cat1.id, cat2.id], startingAt: 0)

        // Assert
        let updated1 = try await repository.fetch(by: cat1.id)
        let updated2 = try await repository.fetch(by: cat2.id)
        #expect(updated1?.sortOrder == 0)
        #expect(updated2?.sortOrder == 1)
    }

    @Test("Reorder single item with offset assigns that offset as sortOrder")
    func reorderSingleItemWithOffset() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let cat = FinanceCategory(name: "Only", type: .income, sortOrder: 3)
        await repository.seed(cat)
        let useCase = ReorderCategoriesUseCase(repository: repository)

        // Act
        try await useCase.execute(orderedIDs: [cat.id], startingAt: 5)

        // Assert
        let updated = try await repository.fetch(by: cat.id)
        #expect(updated?.sortOrder == 5)
    }

    @Test("Default offset of 0 assigns sortOrders starting at 0")
    func defaultOffsetStartsAtZero() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let cat1 = FinanceCategory(name: "X", type: .expense, sortOrder: 50)
        let cat2 = FinanceCategory(name: "Y", type: .expense, sortOrder: 51)
        await repository.seed(cat1)
        await repository.seed(cat2)
        let useCase = ReorderCategoriesUseCase(repository: repository)

        // Act — call without explicit offset, relying on default
        try await useCase.execute(orderedIDs: [cat1.id, cat2.id])

        // Assert
        let updated1 = try await repository.fetch(by: cat1.id)
        let updated2 = try await repository.fetch(by: cat2.id)
        #expect(updated1?.sortOrder == 0)
        #expect(updated2?.sortOrder == 1)
    }
}
