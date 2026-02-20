import Foundation

@testable import FinanceCore

// Use type alias to disambiguate from Objective-C's Category type from objc/runtime.h
typealias FinanceCategory = FinanceCore.Category

/// Mock implementation of CategoryRepositoryProtocol for testing.
///
/// This mock repository stores categories in memory and supports all standard
/// repository operations for use in unit tests.
actor MockCategoryRepository: CategoryRepositoryProtocol {
    private var categories: [UUID: FinanceCategory] = [:]

    /// Tracks which category IDs have associated transactions.
    var categoriesWithTransactions: Set<UUID> = []

    func fetchAll(type: TransactionType?) async throws -> [FinanceCategory] {
        let all = Array(categories.values)
        guard let type else { return all }
        return all.filter { $0.type == type }
    }

    func fetch(by id: UUID) async throws -> FinanceCategory? {
        categories[id]
    }

    func fetchTopLevel(type: TransactionType) async throws -> [FinanceCategory] {
        categories.values.filter { $0.type == type && $0.parentID == nil }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func fetchChildren(of parentID: UUID) async throws -> [FinanceCategory] {
        categories.values.filter { $0.parentID == parentID }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func save(_ category: FinanceCategory) async throws {
        categories[category.id] = category
    }

    func seedDefaults() async throws {
        // No-op for testing
    }

    func delete(_ id: UUID) async throws {
        categories.removeValue(forKey: id)
    }

    func reorder(_ orderedIDs: [UUID], startingAt offset: Int) async throws {
        for (index, id) in orderedIDs.enumerated() {
            categories[id]?.sortOrder = offset + index
        }
    }

    func hasTransactions(categoryID: UUID) async throws -> Bool {
        categoriesWithTransactions.contains(categoryID)
    }

    // MARK: - Testing helpers

    /// Resets the repository to an empty state.
    func reset() {
        categories.removeAll()
        categoriesWithTransactions.removeAll()
    }

    /// Seeds a single category for use in tests.
    func seed(_ category: FinanceCategory) {
        categories[category.id] = category
    }

    /// Marks a category as having associated transactions.
    func markHasTransactions(_ categoryID: UUID) {
        categoriesWithTransactions.insert(categoryID)
    }
}
