import Testing
import Foundation

@testable import FinanceCore

@Suite("UpdateCategoryUseCase Tests")
struct UpdateCategoryUseCaseTests {
    // MARK: - Test: Valid update succeeds

    @Test("Update name successfully")
    func updateNameSucceeds() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let original = FinanceCategory(name: "Old Name", type: .expense)
        await repository.seed(original)
        let useCase = UpdateCategoryUseCase(repository: repository)
        var updated = original
        updated.name = "New Name"

        // Act
        let result = try await useCase.execute(updated)

        // Assert
        #expect(result.name == "New Name")
        #expect(result.id == original.id)
        #expect(result.type == .expense)
    }

    @Test("Update icon and color successfully")
    func updateIconAndColorSucceeds() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let original = FinanceCategory(name: "Food", iconName: "fork.knife", colorHex: "#FF0000", type: .expense)
        await repository.seed(original)
        let useCase = UpdateCategoryUseCase(repository: repository)
        var updated = original
        updated.iconName = "cart.fill"
        updated.colorHex = "#00FF00"

        // Act
        let result = try await useCase.execute(updated)

        // Assert
        #expect(result.iconName == "cart.fill")
        #expect(result.colorHex == "#00FF00")
    }

    // MARK: - Test: Empty name throws nameEmpty

    @Test("Empty name throws nameEmpty")
    func emptyNameThrowsError() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let original = FinanceCategory(name: "Valid", type: .expense)
        await repository.seed(original)
        let useCase = UpdateCategoryUseCase(repository: repository)
        var updated = original
        updated.name = ""

        // Act & Assert
        await #expect(throws: CategoryError.nameEmpty) {
            try await useCase.execute(updated)
        }
    }

    @Test("Whitespace-only name throws nameEmpty")
    func whitespaceOnlyNameThrowsError() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let original = FinanceCategory(name: "Valid", type: .expense)
        await repository.seed(original)
        let useCase = UpdateCategoryUseCase(repository: repository)
        var updated = original
        updated.name = "   "

        // Act & Assert
        await #expect(throws: CategoryError.nameEmpty) {
            try await useCase.execute(updated)
        }
    }

    // MARK: - Test: Category not found throws categoryNotFound

    @Test("Category not found throws categoryNotFound")
    func categoryNotFoundThrowsError() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let useCase = UpdateCategoryUseCase(repository: repository)
        let nonExistent = FinanceCategory(name: "Ghost", type: .expense)

        // Act & Assert
        await #expect(throws: CategoryError.categoryNotFound(nonExistent.id)) {
            try await useCase.execute(nonExistent)
        }
    }

    // MARK: - Test: Duplicate name (excluding self) throws nameAlreadyExists

    @Test("Duplicate name excluding self throws nameAlreadyExists")
    func duplicateNameExcludingSelfThrowsError() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let other = FinanceCategory(name: "Transport", type: .expense)
        let target = FinanceCategory(name: "Food", type: .expense)
        await repository.seed(other)
        await repository.seed(target)
        let useCase = UpdateCategoryUseCase(repository: repository)
        var updated = target
        updated.name = "transport" // case-insensitive match against "other"

        // Act & Assert
        await #expect(throws: CategoryError.self) {
            try await useCase.execute(updated)
        }
    }

    @Test("Renaming to same name (different case) succeeds — self is excluded from duplicate check")
    func renamingToSameNameDifferentCaseSucceeds() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let original = FinanceCategory(name: "Food", type: .expense)
        await repository.seed(original)
        let useCase = UpdateCategoryUseCase(repository: repository)
        var updated = original
        updated.name = "FOOD"

        // Act
        let result = try await useCase.execute(updated)

        // Assert
        #expect(result.name == "FOOD")
    }

    // MARK: - Test: Type change

    @Test("Type change with no transactions succeeds")
    func typeChangeWithoutTransactionsSucceeds() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let original = FinanceCategory(name: "Salary", type: .expense)
        await repository.seed(original)
        let useCase = UpdateCategoryUseCase(repository: repository)
        var updated = original
        updated.type = .income

        // Act
        let result = try await useCase.execute(updated)

        // Assert
        #expect(result.type == .income)
    }

    @Test("Type change with transactions throws cannotChangeTypeWithTransactions")
    func typeChangeWithTransactionsThrowsError() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let original = FinanceCategory(name: "Salary", type: .expense)
        await repository.seed(original)
        await repository.markHasTransactions(original.id)
        let useCase = UpdateCategoryUseCase(repository: repository)
        var updated = original
        updated.type = .income

        // Act & Assert
        await #expect(throws: CategoryError.cannotChangeTypeWithTransactions) {
            try await useCase.execute(updated)
        }
    }

    @Test("Same type update with transactions succeeds")
    func sameTypeUpdateWithTransactionsSucceeds() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let original = FinanceCategory(name: "Food", type: .expense)
        await repository.seed(original)
        await repository.markHasTransactions(original.id)
        let useCase = UpdateCategoryUseCase(repository: repository)
        var updated = original
        updated.name = "Groceries" // name change only, same type

        // Act
        let result = try await useCase.execute(updated)

        // Assert
        #expect(result.name == "Groceries")
        #expect(result.type == .expense)
    }

    // MARK: - Test: Circular parent reference

    @Test("Circular parent reference throws circularParentReference")
    func circularParentReferenceThrowsError() async throws {
        // Arrange: A -> B -> (trying to set B's parent to A, while A's parent is B)
        // More directly: A is parent of B; attempting to set A's parent to B creates a cycle.
        let repository = MockCategoryRepository()
        let parentA = FinanceCategory(name: "Parent A", type: .expense)
        let childB = FinanceCategory(name: "Child B", type: .expense, parentID: parentA.id)
        await repository.seed(parentA)
        await repository.seed(childB)
        let useCase = UpdateCategoryUseCase(repository: repository)

        // Try to make A a child of B — this would create a cycle: B -> A -> B
        var updatedA = parentA
        updatedA.parentID = childB.id

        // Act & Assert
        await #expect(throws: CategoryError.circularParentReference) {
            try await useCase.execute(updatedA)
        }
    }

    @Test("Assigning category as its own parent throws circularParentReference")
    func selfParentThrowsCircularReferenceError() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let category = FinanceCategory(name: "Self-referencing", type: .expense)
        await repository.seed(category)
        let useCase = UpdateCategoryUseCase(repository: repository)
        var updated = category
        updated.parentID = category.id // points to itself

        // Act & Assert
        await #expect(throws: CategoryError.circularParentReference) {
            try await useCase.execute(updated)
        }
    }

    @Test("Deep circular parent chain throws circularParentReference")
    func deepCircularParentChainThrowsError() async throws {
        // Arrange: A -> B -> C; now try to set A's parent to C (A -> C -> B -> A)
        let repository = MockCategoryRepository()
        let catA = FinanceCategory(name: "A", type: .expense)
        let catB = FinanceCategory(name: "B", type: .expense, parentID: catA.id)
        let catC = FinanceCategory(name: "C", type: .expense, parentID: catB.id)
        await repository.seed(catA)
        await repository.seed(catB)
        await repository.seed(catC)
        let useCase = UpdateCategoryUseCase(repository: repository)

        // Try to set A's parent to C — would create: C -> B -> A -> C
        var updatedA = catA
        updatedA.parentID = catC.id

        // Act & Assert
        await #expect(throws: CategoryError.circularParentReference) {
            try await useCase.execute(updatedA)
        }
    }

    // MARK: - Test: Parent not found

    @Test("Setting non-existent parent throws parentCategoryNotFound")
    func nonExistentParentThrowsError() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let original = FinanceCategory(name: "Category", type: .expense)
        await repository.seed(original)
        let useCase = UpdateCategoryUseCase(repository: repository)
        let fakeParentID = UUID()
        var updated = original
        updated.parentID = fakeParentID

        // Act & Assert
        await #expect(throws: CategoryError.parentCategoryNotFound(fakeParentID)) {
            try await useCase.execute(updated)
        }
    }

    @Test("Changing parent to valid existing category succeeds")
    func changingToValidParentSucceeds() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let original = FinanceCategory(name: "Category", type: .expense)
        let newParent = FinanceCategory(name: "New Parent", type: .expense)
        await repository.seed(original)
        await repository.seed(newParent)
        let useCase = UpdateCategoryUseCase(repository: repository)
        var updated = original
        updated.parentID = newParent.id

        // Act
        let result = try await useCase.execute(updated)

        // Assert
        #expect(result.parentID == newParent.id)
    }
}
