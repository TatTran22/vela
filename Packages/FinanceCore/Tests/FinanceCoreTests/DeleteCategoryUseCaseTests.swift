import Testing
import Foundation

@testable import FinanceCore

@Suite("DeleteCategoryUseCase Tests")
struct DeleteCategoryUseCaseTests {
    // MARK: - Test: Delete custom category with no transactions succeeds

    @Test("Delete custom category with no transactions removes it from repository")
    func deleteCustomCategoryNoTransactionsSucceeds() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let category = FinanceCategory(name: "Custom Category", type: .expense, isDefault: false)
        await repository.seed(category)
        let useCase = DeleteCategoryUseCase(repository: repository)

        // Act
        try await useCase.execute(id: category.id)

        // Assert — non-default category should be permanently deleted
        let fetched = try await repository.fetch(by: category.id)
        #expect(fetched == nil)
    }

    // MARK: - Test: Delete category with transactions throws error

    @Test("Delete category with transactions throws cannotDeleteCategoryWithTransactions")
    func deleteCategoryWithTransactionsThrowsError() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let category = FinanceCategory(name: "Active Category", type: .expense, isDefault: false)
        await repository.seed(category)
        await repository.markHasTransactions(category.id)
        let useCase = DeleteCategoryUseCase(repository: repository)

        // Act & Assert
        await #expect(throws: CategoryError.self) {
            try await useCase.execute(id: category.id)
        }
    }

    @Test("Delete category with transactions throws the correct error case")
    func deleteCategoryWithTransactionsThrowsCorrectCase() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let category = FinanceCategory(name: "Budgeted", type: .expense, isDefault: false)
        await repository.seed(category)
        await repository.markHasTransactions(category.id)
        let useCase = DeleteCategoryUseCase(repository: repository)

        // Act & Assert
        await #expect(throws: CategoryError.cannotDeleteCategoryWithTransactions(reassignTo: nil)) {
            try await useCase.execute(id: category.id)
        }
    }

    // MARK: - Test: Delete default (system) category archives instead

    @Test("Delete default (system) category archives it instead of deleting")
    func deleteDefaultCategoryArchivesInstead() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let defaultCategory = FinanceCategory(
            name: "Housing",
            type: .expense,
            isDefault: true,
            isArchived: false
        )
        await repository.seed(defaultCategory)
        let useCase = DeleteCategoryUseCase(repository: repository)

        // Act
        try await useCase.execute(id: defaultCategory.id)

        // Assert — default category should still exist but be archived
        let fetched = try await repository.fetch(by: defaultCategory.id)
        #expect(fetched != nil)
        #expect(fetched?.isArchived == true)
    }

    @Test("Delete default category preserves all other fields")
    func deleteDefaultCategoryPreservesFields() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let defaultCategory = FinanceCategory(
            name: "Utilities",
            iconName: "bolt.fill",
            colorHex: "#FFD700",
            type: .expense,
            isDefault: true,
            isArchived: false
        )
        await repository.seed(defaultCategory)
        let useCase = DeleteCategoryUseCase(repository: repository)

        // Act
        try await useCase.execute(id: defaultCategory.id)

        // Assert
        let fetched = try await repository.fetch(by: defaultCategory.id)
        #expect(fetched?.name == "Utilities")
        #expect(fetched?.iconName == "bolt.fill")
        #expect(fetched?.colorHex == "#FFD700")
        #expect(fetched?.isArchived == true)
    }

    // MARK: - Test: Delete parent archives children

    @Test("Delete parent category archives all direct children")
    func deleteParentArchivesChildren() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let parent = FinanceCategory(name: "Food", type: .expense, isDefault: false)
        let child1 = FinanceCategory(name: "Restaurant", type: .expense, parentID: parent.id, isArchived: false)
        let child2 = FinanceCategory(name: "Groceries", type: .expense, parentID: parent.id, isArchived: false)
        await repository.seed(parent)
        await repository.seed(child1)
        await repository.seed(child2)
        let useCase = DeleteCategoryUseCase(repository: repository)

        // Act
        try await useCase.execute(id: parent.id)

        // Assert — children should be archived
        let fetchedChild1 = try await repository.fetch(by: child1.id)
        let fetchedChild2 = try await repository.fetch(by: child2.id)
        #expect(fetchedChild1?.isArchived == true)
        #expect(fetchedChild2?.isArchived == true)
    }

    @Test("Delete default parent archives both parent and children")
    func deleteDefaultParentArchivesParentAndChildren() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let defaultParent = FinanceCategory(name: "Food", type: .expense, isDefault: true, isArchived: false)
        let child = FinanceCategory(name: "Takeout", type: .expense, parentID: defaultParent.id, isArchived: false)
        await repository.seed(defaultParent)
        await repository.seed(child)
        let useCase = DeleteCategoryUseCase(repository: repository)

        // Act
        try await useCase.execute(id: defaultParent.id)

        // Assert — parent archived, child archived, parent still exists in repo
        let fetchedParent = try await repository.fetch(by: defaultParent.id)
        let fetchedChild = try await repository.fetch(by: child.id)
        #expect(fetchedParent?.isArchived == true)
        #expect(fetchedChild?.isArchived == true)
    }

    @Test("Delete custom parent with children: parent deleted, children archived")
    func deleteCustomParentDeletesParentArchivesChildren() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let parent = FinanceCategory(name: "Custom Parent", type: .expense, isDefault: false)
        let child = FinanceCategory(name: "Custom Child", type: .expense, parentID: parent.id, isArchived: false)
        await repository.seed(parent)
        await repository.seed(child)
        let useCase = DeleteCategoryUseCase(repository: repository)

        // Act
        try await useCase.execute(id: parent.id)

        // Assert — parent permanently deleted; child archived
        let fetchedParent = try await repository.fetch(by: parent.id)
        let fetchedChild = try await repository.fetch(by: child.id)
        #expect(fetchedParent == nil)
        #expect(fetchedChild?.isArchived == true)
    }

    // MARK: - Test: Delete non-existent category throws categoryNotFound

    @Test("Delete non-existent category throws categoryNotFound")
    func deleteNonExistentCategoryThrowsError() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let useCase = DeleteCategoryUseCase(repository: repository)
        let nonExistentID = UUID()

        // Act & Assert
        await #expect(throws: CategoryError.categoryNotFound(nonExistentID)) {
            try await useCase.execute(id: nonExistentID)
        }
    }

    // MARK: - Test: Category without children

    @Test("Delete category with no children succeeds cleanly")
    func deleteCategoryWithNoChildren() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let leafCategory = FinanceCategory(name: "Leaf", type: .income, isDefault: false)
        await repository.seed(leafCategory)
        let useCase = DeleteCategoryUseCase(repository: repository)

        // Act
        try await useCase.execute(id: leafCategory.id)

        // Assert
        let fetched = try await repository.fetch(by: leafCategory.id)
        #expect(fetched == nil)
    }
}
