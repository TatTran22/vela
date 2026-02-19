import Testing
import Foundation
import SwiftData

@testable import FinanceCore
@testable import FinanceData

// Use a typealias to avoid ambiguity with ObjC Category type from objc/runtime.h
private typealias AppCategory = FinanceCore.Category

// MARK: - T26: CategoryRepository Tests

@Suite("CategoryRepository Tests")
struct CategoryRepositoryTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        try ModelContainerSetup.createContainer(inMemory: true)
    }

    private func makeCategory(
        name: String = "Test Category",
        type: TransactionType = .expense,
        parentID: UUID? = nil,
        sortOrder: Int = 0
    ) -> AppCategory {
        AppCategory(
            name: name,
            type: type,
            parentID: parentID,
            sortOrder: sortOrder
        )
    }

    // MARK: - seedDefaults

    @Test("seedDefaults creates 16 default categories")
    func testSeedDefaultsCreates16Categories() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        try await repo.seedDefaults()

        let all = try await repo.fetchAll(type: nil)
        // 10 expense + 5 income + 1 transfer = 16
        #expect(all.count == 16)
    }

    @Test("seedDefaults is idempotent: calling twice does not create duplicates")
    func testSeedDefaultsIdempotent() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        try await repo.seedDefaults()
        try await repo.seedDefaults()

        let all = try await repo.fetchAll(type: nil)
        #expect(all.count == 16)
    }

    @Test("seedDefaults creates 10 expense categories")
    func testSeedDefaultsExpenseCount() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        try await repo.seedDefaults()

        let expense = try await repo.fetchAll(type: .expense)
        #expect(expense.count == 10)
    }

    @Test("seedDefaults creates 5 income categories")
    func testSeedDefaultsIncomeCount() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        try await repo.seedDefaults()

        let income = try await repo.fetchAll(type: .income)
        #expect(income.count == 5)
    }

    @Test("seedDefaults creates 1 transfer category")
    func testSeedDefaultsTransferCount() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        try await repo.seedDefaults()

        let transfer = try await repo.fetchAll(type: .transfer)
        #expect(transfer.count == 1)
    }

    @Test("seedDefaults does not run when categories already exist")
    func testSeedDefaultsSkipsWhenNotEmpty() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        // Pre-populate with a single custom category
        let custom = makeCategory(name: "My Custom", type: .expense)
        try await repo.save(custom)

        // Seed should not overwrite because the table is not empty
        try await repo.seedDefaults()

        let all = try await repo.fetchAll(type: nil)
        // Only the one custom category; defaults were not inserted
        #expect(all.count == 1)
    }

    // MARK: - Save and Fetch

    @Test("Save and fetch category by ID")
    func testSaveAndFetchByID() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        let category = makeCategory(name: "Food", type: .expense)
        try await repo.save(category)

        let fetched = try await repo.fetch(by: category.id)

        #expect(fetched != nil)
        #expect(fetched?.id == category.id)
        #expect(fetched?.name == "Food")
        #expect(fetched?.type == .expense)
    }

    @Test("Fetch non-existent category by ID returns nil")
    func testFetchNonExistentReturnsNil() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        let fetched = try await repo.fetch(by: UUID())
        #expect(fetched == nil)
    }

    @Test("Save overwrites existing category with same ID (upsert)")
    func testSaveUpserts() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        var category = makeCategory(name: "Original")
        try await repo.save(category)

        category.name = "Updated"
        try await repo.save(category)

        let all = try await repo.fetchAll(type: nil)
        #expect(all.count == 1)
        #expect(all.first?.name == "Updated")
    }

    // MARK: - fetchAll with Type Filter

    @Test("fetchAll with nil type returns all categories")
    func testFetchAllNoFilter() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        let expense = makeCategory(name: "Food", type: .expense)
        let income = makeCategory(name: "Salary", type: .income)
        let transfer = makeCategory(name: "Transfer", type: .transfer)

        try await repo.save(expense)
        try await repo.save(income)
        try await repo.save(transfer)

        let all = try await repo.fetchAll(type: nil)
        #expect(all.count == 3)
    }

    @Test("fetchAll with expense type returns only expense categories")
    func testFetchAllFilteredByExpense() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        let expense1 = makeCategory(name: "Food", type: .expense)
        let expense2 = makeCategory(name: "Transport", type: .expense)
        let income = makeCategory(name: "Salary", type: .income)

        try await repo.save(expense1)
        try await repo.save(expense2)
        try await repo.save(income)

        let expenses = try await repo.fetchAll(type: .expense)
        #expect(expenses.count == 2)
        #expect(expenses.allSatisfy { $0.type == .expense })
    }

    @Test("fetchAll with income type returns only income categories")
    func testFetchAllFilteredByIncome() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        let expense = makeCategory(name: "Food", type: .expense)
        let income = makeCategory(name: "Salary", type: .income)

        try await repo.save(expense)
        try await repo.save(income)

        let incomes = try await repo.fetchAll(type: .income)
        #expect(incomes.count == 1)
        #expect(incomes.first?.type == .income)
    }

    @Test("fetchAll returns empty array when no matching type")
    func testFetchAllEmptyForMissingType() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        let expense = makeCategory(name: "Food", type: .expense)
        try await repo.save(expense)

        let transfers = try await repo.fetchAll(type: .transfer)
        #expect(transfers.isEmpty)
    }

    @Test("fetchAll returns categories ordered by sortOrder then name")
    func testFetchAllOrdering() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        let catB = makeCategory(name: "Bravo", type: .expense, sortOrder: 1)
        let catA = makeCategory(name: "Alpha", type: .expense, sortOrder: 0)
        let catC = makeCategory(name: "Charlie", type: .expense, sortOrder: 2)

        try await repo.save(catB)
        try await repo.save(catA)
        try await repo.save(catC)

        let all = try await repo.fetchAll(type: .expense)
        #expect(all.count == 3)
        #expect(all[0].name == "Alpha")
        #expect(all[1].name == "Bravo")
        #expect(all[2].name == "Charlie")
    }

    // MARK: - fetchTopLevel

    @Test("fetchTopLevel returns only root-level categories for given type")
    func testFetchTopLevel() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        let parent = makeCategory(name: "Food", type: .expense, parentID: nil)
        let child = makeCategory(name: "Snacks", type: .expense, parentID: parent.id)
        let otherTopLevel = makeCategory(name: "Transport", type: .expense, parentID: nil)

        try await repo.save(parent)
        try await repo.save(child)
        try await repo.save(otherTopLevel)

        let topLevel = try await repo.fetchTopLevel(type: .expense)

        #expect(topLevel.count == 2)
        #expect(topLevel.allSatisfy { $0.parentID == nil })
        let names = topLevel.map(\.name)
        #expect(names.contains("Food"))
        #expect(names.contains("Transport"))
    }

    @Test("fetchTopLevel does not return categories of a different type")
    func testFetchTopLevelTypeIsolation() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        let expenseRoot = makeCategory(name: "Food", type: .expense)
        let incomeRoot = makeCategory(name: "Salary", type: .income)

        try await repo.save(expenseRoot)
        try await repo.save(incomeRoot)

        let topLevelExpense = try await repo.fetchTopLevel(type: .expense)
        let topLevelIncome = try await repo.fetchTopLevel(type: .income)

        #expect(topLevelExpense.count == 1)
        #expect(topLevelExpense.first?.name == "Food")
        #expect(topLevelIncome.count == 1)
        #expect(topLevelIncome.first?.name == "Salary")
    }

    @Test("fetchTopLevel returns empty array when no root categories exist for type")
    func testFetchTopLevelEmpty() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        let top = try await repo.fetchTopLevel(type: .expense)
        #expect(top.isEmpty)
    }

    // MARK: - fetchChildren

    @Test("fetchChildren returns only direct children of parent")
    func testFetchChildren() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        let parent = makeCategory(name: "Food", type: .expense)
        let child1 = makeCategory(name: "Lunch", type: .expense, parentID: parent.id, sortOrder: 0)
        let child2 = makeCategory(name: "Dinner", type: .expense, parentID: parent.id, sortOrder: 1)
        let unrelated = makeCategory(name: "Transport", type: .expense, parentID: nil)

        try await repo.save(parent)
        try await repo.save(child1)
        try await repo.save(child2)
        try await repo.save(unrelated)

        let children = try await repo.fetchChildren(of: parent.id)

        #expect(children.count == 2)
        #expect(children.allSatisfy { $0.parentID == parent.id })
        let names = children.map(\.name)
        #expect(names.contains("Lunch"))
        #expect(names.contains("Dinner"))
    }

    @Test("fetchChildren returns empty array when parent has no children")
    func testFetchChildrenEmpty() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        let parent = makeCategory(name: "Food", type: .expense)
        try await repo.save(parent)

        let children = try await repo.fetchChildren(of: parent.id)
        #expect(children.isEmpty)
    }

    @Test("fetchChildren returns empty array for non-existent parent ID")
    func testFetchChildrenNonExistentParent() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        let children = try await repo.fetchChildren(of: UUID())
        #expect(children.isEmpty)
    }

    @Test("fetchChildren returns results ordered by sortOrder then name")
    func testFetchChildrenOrdering() async throws {
        let container = try makeContainer()
        let repo = CategoryRepository(modelContainer: container)

        let parent = makeCategory(name: "Food", type: .expense)
        let childB = makeCategory(name: "Bravo", type: .expense, parentID: parent.id, sortOrder: 1)
        let childA = makeCategory(name: "Alpha", type: .expense, parentID: parent.id, sortOrder: 0)

        try await repo.save(parent)
        try await repo.save(childB)
        try await repo.save(childA)

        let children = try await repo.fetchChildren(of: parent.id)

        #expect(children.count == 2)
        #expect(children[0].name == "Alpha")
        #expect(children[1].name == "Bravo")
    }
}
