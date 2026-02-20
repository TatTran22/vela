import Testing
import Foundation

@testable import FinanceCore

@Suite("GetCategoriesUseCase Tests")
struct GetCategoriesUseCaseTests {
    // MARK: - Test: Returns categories sorted by sortOrder

    @Test("Returns categories sorted by sortOrder ascending")
    func returnsSortedBySortOrder() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        await repository.seed(FinanceCategory(name: "Third", type: .expense, sortOrder: 2))
        await repository.seed(FinanceCategory(name: "First", type: .expense, sortOrder: 0))
        await repository.seed(FinanceCategory(name: "Second", type: .expense, sortOrder: 1))
        let useCase = GetCategoriesUseCase(repository: repository)

        // Act
        let results = try await useCase.execute(type: .expense, includeArchived: false)

        // Assert
        #expect(results.count == 3)
        #expect(results[0].name == "First")
        #expect(results[1].name == "Second")
        #expect(results[2].name == "Third")
    }

    @Test("Returns all categories when type is nil")
    func returnsAllCategoriesWhenTypeNil() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        await repository.seed(FinanceCategory(name: "Salary", type: .income, sortOrder: 0))
        await repository.seed(FinanceCategory(name: "Food", type: .expense, sortOrder: 1))
        let useCase = GetCategoriesUseCase(repository: repository)

        // Act
        let results = try await useCase.execute(type: nil, includeArchived: false)

        // Assert
        #expect(results.count == 2)
    }

    @Test("Returns only categories of the requested type")
    func returnsOnlyRequestedType() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        await repository.seed(FinanceCategory(name: "Salary", type: .income))
        await repository.seed(FinanceCategory(name: "Food", type: .expense))
        await repository.seed(FinanceCategory(name: "Freelance", type: .income))
        let useCase = GetCategoriesUseCase(repository: repository)

        // Act
        let incomeResults = try await useCase.execute(type: .income, includeArchived: false)

        // Assert
        #expect(incomeResults.count == 2)
        #expect(incomeResults.allSatisfy { $0.type == .income })
    }

    @Test("Tie-breaking sorts by name when sortOrders are equal")
    func tieBrakingByName() async throws {
        // Arrange — all same sortOrder, expect alphabetical name ordering
        let repository = MockCategoryRepository()
        await repository.seed(FinanceCategory(name: "Zebra", type: .expense, sortOrder: 0))
        await repository.seed(FinanceCategory(name: "Apple", type: .expense, sortOrder: 0))
        await repository.seed(FinanceCategory(name: "Mango", type: .expense, sortOrder: 0))
        let useCase = GetCategoriesUseCase(repository: repository)

        // Act
        let results = try await useCase.execute(type: .expense, includeArchived: false)

        // Assert
        #expect(results[0].name == "Apple")
        #expect(results[1].name == "Mango")
        #expect(results[2].name == "Zebra")
    }

    // MARK: - Test: Archived categories excluded by default

    @Test("Archived categories excluded by default")
    func archivedCategoriesExcludedByDefault() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        await repository.seed(FinanceCategory(name: "Active", type: .expense, isArchived: false))
        await repository.seed(FinanceCategory(name: "Archived", type: .expense, isArchived: true))
        let useCase = GetCategoriesUseCase(repository: repository)

        // Act
        let results = try await useCase.execute(type: .expense, includeArchived: false)

        // Assert
        #expect(results.count == 1)
        #expect(results.first?.name == "Active")
    }

    // MARK: - Test: Archived categories included when requested

    @Test("Archived categories included when includeArchived is true")
    func archivedCategoriesIncludedWhenRequested() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        await repository.seed(FinanceCategory(name: "Active", type: .expense, isArchived: false))
        await repository.seed(FinanceCategory(name: "Archived", type: .expense, isArchived: true))
        let useCase = GetCategoriesUseCase(repository: repository)

        // Act
        let results = try await useCase.execute(type: .expense, includeArchived: true)

        // Assert
        #expect(results.count == 2)
        #expect(results.contains { $0.name == "Active" })
        #expect(results.contains { $0.name == "Archived" })
    }

    // MARK: - Test: Empty repository returns empty array

    @Test("Empty repository returns empty array")
    func emptyRepositoryReturnsEmptyArray() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let useCase = GetCategoriesUseCase(repository: repository)

        // Act
        let results = try await useCase.execute(type: nil, includeArchived: false)

        // Assert
        #expect(results.isEmpty)
    }

    // MARK: - Test: executeGrouped groups by type correctly

    @Test("executeGrouped groups categories by transaction type")
    func executeGroupedGroupsByType() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        await repository.seed(FinanceCategory(name: "Salary", type: .income, sortOrder: 0))
        await repository.seed(FinanceCategory(name: "Freelance", type: .income, sortOrder: 1))
        await repository.seed(FinanceCategory(name: "Food", type: .expense, sortOrder: 0))
        let useCase = GetCategoriesUseCase(repository: repository)

        // Act
        let grouped = try await useCase.executeGrouped(includeArchived: false)

        // Assert
        #expect(grouped[.income]?.count == 2)
        #expect(grouped[.expense]?.count == 1)
    }

    @Test("executeGrouped returns empty dictionary for empty repository")
    func executeGroupedEmptyRepository() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let useCase = GetCategoriesUseCase(repository: repository)

        // Act
        let grouped = try await useCase.executeGrouped(includeArchived: false)

        // Assert
        #expect(grouped.isEmpty)
    }

    @Test("executeGrouped excludes archived categories by default")
    func executeGroupedExcludesArchivedByDefault() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        await repository.seed(FinanceCategory(name: "Active Income", type: .income, isArchived: false))
        await repository.seed(FinanceCategory(name: "Archived Income", type: .income, isArchived: true))
        await repository.seed(FinanceCategory(name: "Active Expense", type: .expense, isArchived: false))
        let useCase = GetCategoriesUseCase(repository: repository)

        // Act
        let grouped = try await useCase.executeGrouped(includeArchived: false)

        // Assert
        #expect(grouped[.income]?.count == 1)
        #expect(grouped[.income]?.first?.name == "Active Income")
        #expect(grouped[.expense]?.count == 1)
    }

    @Test("executeGrouped includes archived when requested")
    func executeGroupedIncludesArchivedWhenRequested() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        await repository.seed(FinanceCategory(name: "Active", type: .expense, isArchived: false))
        await repository.seed(FinanceCategory(name: "Archived", type: .expense, isArchived: true))
        let useCase = GetCategoriesUseCase(repository: repository)

        // Act
        let grouped = try await useCase.executeGrouped(includeArchived: true)

        // Assert
        #expect(grouped[.expense]?.count == 2)
    }

    @Test("executeGrouped returns categories sorted by sortOrder within each group")
    func executeGroupedSortedWithinGroups() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        await repository.seed(FinanceCategory(name: "C Expense", type: .expense, sortOrder: 2))
        await repository.seed(FinanceCategory(name: "A Expense", type: .expense, sortOrder: 0))
        await repository.seed(FinanceCategory(name: "B Expense", type: .expense, sortOrder: 1))
        let useCase = GetCategoriesUseCase(repository: repository)

        // Act
        let grouped = try await useCase.executeGrouped(includeArchived: false)

        // Assert
        let expenseGroup = grouped[.expense]!
        #expect(expenseGroup[0].name == "A Expense")
        #expect(expenseGroup[1].name == "B Expense")
        #expect(expenseGroup[2].name == "C Expense")
    }

    // MARK: - Test: executeNested returns parent-child groups

    @Test("executeNested returns parent-child groups correctly")
    func executeNestedReturnsParentChildGroups() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let parent = FinanceCategory(name: "Food", type: .expense, sortOrder: 0)
        let child1 = FinanceCategory(name: "Restaurant", type: .expense, parentID: parent.id, sortOrder: 0)
        let child2 = FinanceCategory(name: "Groceries", type: .expense, parentID: parent.id, sortOrder: 1)
        await repository.seed(parent)
        await repository.seed(child1)
        await repository.seed(child2)
        let useCase = GetCategoriesUseCase(repository: repository)

        // Act
        let nested = try await useCase.executeNested(type: .expense, includeArchived: false)

        // Assert
        #expect(nested.count == 1)
        #expect(nested[0].parent.name == "Food")
        #expect(nested[0].children.count == 2)
        #expect(nested[0].children[0].name == "Restaurant")
        #expect(nested[0].children[1].name == "Groceries")
    }

    @Test("executeNested groups are sorted by parent sortOrder")
    func executeNestedGroupsSortedByParentSortOrder() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let parentB = FinanceCategory(name: "Transport", type: .expense, sortOrder: 1)
        let parentA = FinanceCategory(name: "Food", type: .expense, sortOrder: 0)
        await repository.seed(parentB)
        await repository.seed(parentA)
        let useCase = GetCategoriesUseCase(repository: repository)

        // Act
        let nested = try await useCase.executeNested(type: .expense, includeArchived: false)

        // Assert
        #expect(nested[0].parent.name == "Food")
        #expect(nested[1].parent.name == "Transport")
    }

    @Test("executeNested children are sorted by sortOrder within each group")
    func executeNestedChildrenSortedWithinGroups() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let parent = FinanceCategory(name: "Food", type: .expense, sortOrder: 0)
        let childC = FinanceCategory(name: "C", type: .expense, parentID: parent.id, sortOrder: 2)
        let childA = FinanceCategory(name: "A", type: .expense, parentID: parent.id, sortOrder: 0)
        let childB = FinanceCategory(name: "B", type: .expense, parentID: parent.id, sortOrder: 1)
        await repository.seed(parent)
        await repository.seed(childC)
        await repository.seed(childA)
        await repository.seed(childB)
        let useCase = GetCategoriesUseCase(repository: repository)

        // Act
        let nested = try await useCase.executeNested(type: .expense, includeArchived: false)

        // Assert
        let children = nested[0].children
        #expect(children[0].name == "A")
        #expect(children[1].name == "B")
        #expect(children[2].name == "C")
    }

    @Test("executeNested excludes archived parents by default")
    func executeNestedExcludesArchivedParents() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let activeParent = FinanceCategory(name: "Active", type: .expense, isArchived: false)
        let archivedParent = FinanceCategory(name: "Archived", type: .expense, isArchived: true)
        await repository.seed(activeParent)
        await repository.seed(archivedParent)
        let useCase = GetCategoriesUseCase(repository: repository)

        // Act
        let nested = try await useCase.executeNested(type: .expense, includeArchived: false)

        // Assert
        #expect(nested.count == 1)
        #expect(nested[0].parent.name == "Active")
    }

    @Test("executeNested excludes archived children by default")
    func executeNestedExcludesArchivedChildren() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let parent = FinanceCategory(name: "Food", type: .expense)
        let activeChild = FinanceCategory(name: "Active Child", type: .expense, parentID: parent.id, isArchived: false)
        let archivedChild = FinanceCategory(name: "Archived Child", type: .expense, parentID: parent.id, isArchived: true)
        await repository.seed(parent)
        await repository.seed(activeChild)
        await repository.seed(archivedChild)
        let useCase = GetCategoriesUseCase(repository: repository)

        // Act
        let nested = try await useCase.executeNested(type: .expense, includeArchived: false)

        // Assert
        #expect(nested[0].children.count == 1)
        #expect(nested[0].children[0].name == "Active Child")
    }

    @Test("executeNested includes archived when requested")
    func executeNestedIncludesArchivedWhenRequested() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let parent = FinanceCategory(name: "Food", type: .expense, isArchived: false)
        let archivedChild = FinanceCategory(name: "Archived Child", type: .expense, parentID: parent.id, isArchived: true)
        let archivedParent = FinanceCategory(name: "Archived Parent", type: .expense, isArchived: true)
        await repository.seed(parent)
        await repository.seed(archivedChild)
        await repository.seed(archivedParent)
        let useCase = GetCategoriesUseCase(repository: repository)

        // Act
        let nested = try await useCase.executeNested(type: .expense, includeArchived: true)

        // Assert
        #expect(nested.count == 2) // both active parent and archived parent
        let foodGroup = nested.first { $0.parent.name == "Food" }
        #expect(foodGroup?.children.count == 1) // includes archived child
        #expect(foodGroup?.children.first?.name == "Archived Child")
    }

    @Test("executeNested returns empty groups for a parent with no children")
    func executeNestedReturnsEmptyChildrenForLeafParent() async throws {
        // Arrange
        let repository = MockCategoryRepository()
        let parent = FinanceCategory(name: "Lone Parent", type: .income)
        await repository.seed(parent)
        let useCase = GetCategoriesUseCase(repository: repository)

        // Act
        let nested = try await useCase.executeNested(type: .income, includeArchived: false)

        // Assert
        #expect(nested.count == 1)
        #expect(nested[0].parent.name == "Lone Parent")
        #expect(nested[0].children.isEmpty)
    }
}
