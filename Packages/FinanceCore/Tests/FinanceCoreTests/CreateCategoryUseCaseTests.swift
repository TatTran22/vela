import Testing
import Foundation

@testable import FinanceCore

@Suite("CreateCategoryUseCase Tests")
struct CreateCategoryUseCaseTests {
    // MARK: - Test: Valid category creation succeeds

    @Test("Create category with valid name succeeds")
    func createValid() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let useCase = CreateCategoryUseCase(repository: repository)
        let category = FinanceCategory(name: "Test", type: .expense)

        // Act
        let result = try await useCase.execute(category)

        // Assert
        #expect(result.name == "Test")
        #expect(result.sortOrder == 0)
    }

    // MARK: - Test: Empty name throws nameEmpty

    @Test("Create category with empty name throws nameEmpty")
    func createEmptyName() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let useCase = CreateCategoryUseCase(repository: repository)
        let category = FinanceCategory(name: "   ", type: .expense)

        // Act & Assert
        await #expect(throws: CategoryError.nameEmpty) {
            try await useCase.execute(category)
        }
    }

    @Test("Create category with completely empty string throws nameEmpty")
    func createCompletelyEmptyName() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let useCase = CreateCategoryUseCase(repository: repository)
        let category = FinanceCategory(name: "", type: .expense)

        // Act & Assert
        await #expect(throws: CategoryError.nameEmpty) {
            try await useCase.execute(category)
        }
    }

    // MARK: - Test: Duplicate name throws nameAlreadyExists

    @Test("Create category with duplicate name in same scope throws nameAlreadyExists")
    func createDuplicate() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let existing = FinanceCategory(name: "Food", type: .expense)
        await repository.seed(existing)
        let useCase = CreateCategoryUseCase(repository: repository)
        let duplicate = FinanceCategory(name: "food", type: .expense) // case-insensitive

        // Act & Assert
        await #expect(throws: CategoryError.self) {
            try await useCase.execute(duplicate)
        }
    }

    @Test("Create category with duplicate name and leading/trailing whitespace throws nameAlreadyExists")
    func createDuplicateWithWhitespace() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let existing = FinanceCategory(name: "Transport", type: .expense)
        await repository.seed(existing)
        let useCase = CreateCategoryUseCase(repository: repository)
        let duplicate = FinanceCategory(name: "  Transport  ", type: .expense)

        // Act & Assert
        await #expect(throws: CategoryError.self) {
            try await useCase.execute(duplicate)
        }
    }

    // MARK: - Test: Same name different type succeeds

    @Test("Same name in different type scope succeeds")
    func createSameNameDifferentType() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let existing = FinanceCategory(name: "Other", type: .expense)
        await repository.seed(existing)
        let useCase = CreateCategoryUseCase(repository: repository)
        let income = FinanceCategory(name: "Other", type: .income)

        // Act
        let result = try await useCase.execute(income)

        // Assert
        #expect(result.name == "Other")
        #expect(result.type == .income)
    }

    // MARK: - Test: Auto-assign sortOrder

    @Test("Auto-assigns sortOrder incrementally based on max existing sortOrder")
    func autoSortOrder() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        await repository.seed(FinanceCategory(name: "A", type: .expense, sortOrder: 0))
        await repository.seed(FinanceCategory(name: "B", type: .expense, sortOrder: 5))
        let useCase = CreateCategoryUseCase(repository: repository)

        // Act
        let result = try await useCase.execute(FinanceCategory(name: "C", type: .expense))

        // Assert
        #expect(result.sortOrder == 6)
    }

    @Test("Auto-assigns sortOrder of 0 when no existing categories")
    func autoSortOrderEmpty() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let useCase = CreateCategoryUseCase(repository: repository)

        // Act
        let result = try await useCase.execute(FinanceCategory(name: "First", type: .expense))

        // Assert
        #expect(result.sortOrder == 0)
    }

    @Test("sortOrder is scoped to same type — income and expense sort independently")
    func sortOrderScopedByType() async throws {
        // Arrange — seed 3 expense categories with high sort orders
        let repository = MockCategoryRepository()
        await repository.seed(FinanceCategory(name: "Expense A", type: .expense, sortOrder: 10))
        await repository.seed(FinanceCategory(name: "Expense B", type: .expense, sortOrder: 20))
        let useCase = CreateCategoryUseCase(repository: repository)

        // Act — creating a new income category should start at 0, not 21
        let result = try await useCase.execute(FinanceCategory(name: "Income A", type: .income))

        // Assert
        #expect(result.sortOrder == 0)
    }

    // MARK: - Test: Parent ID validation

    @Test("Parent ID validation — parent not found throws parentCategoryNotFound")
    func parentNotFound() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let useCase = CreateCategoryUseCase(repository: repository)
        let badParentID = UUID()
        let category = FinanceCategory(name: "Child", type: .expense, parentID: badParentID)

        // Act & Assert
        await #expect(throws: CategoryError.parentCategoryNotFound(badParentID)) {
            try await useCase.execute(category)
        }
    }

    @Test("Create child category with valid parent succeeds")
    func createChildWithValidParent() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let parent = FinanceCategory(name: "Food", type: .expense)
        await repository.seed(parent)
        let useCase = CreateCategoryUseCase(repository: repository)
        let child = FinanceCategory(name: "Restaurant", type: .expense, parentID: parent.id)

        // Act
        let result = try await useCase.execute(child)

        // Assert
        #expect(result.name == "Restaurant")
        #expect(result.parentID == parent.id)
    }

    @Test("Duplicate name in different parent scope succeeds")
    func duplicateNameDifferentParentScope() async throws {
        // Arrange — two siblings "Lunch" under parent A; creating "Lunch" under parent B should pass
        let repository = MockCategoryRepository()
        let parentA = FinanceCategory(name: "Food", type: .expense)
        let parentB = FinanceCategory(name: "Entertainment", type: .expense)
        let existingChild = FinanceCategory(name: "Lunch", type: .expense, parentID: parentA.id)
        await repository.seed(parentA)
        await repository.seed(parentB)
        await repository.seed(existingChild)
        let useCase = CreateCategoryUseCase(repository: repository)
        let newChild = FinanceCategory(name: "Lunch", type: .expense, parentID: parentB.id)

        // Act
        let result = try await useCase.execute(newChild)

        // Assert
        #expect(result.name == "Lunch")
        #expect(result.parentID == parentB.id)
    }
}
