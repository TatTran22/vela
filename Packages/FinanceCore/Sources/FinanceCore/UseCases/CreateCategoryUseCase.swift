import Foundation

/// Protocol for creating new categories.
///
/// This use case handles category creation with validation of business rules
/// including name uniqueness within the same type and parent scope, parent
/// existence, and automatic sort-order assignment.
public protocol CreateCategoryUseCaseProtocol: Sendable {
    /// Creates a new category after validating business rules.
    ///
    /// The category will be validated for:
    /// - Non-empty name (trimmed)
    /// - Name uniqueness within the same `type` and `parentID` scope (case-insensitive)
    /// - Parent category existence when `parentID` is set
    ///
    /// The `sortOrder` is automatically assigned as the current maximum sort order
    /// within the same type and parent scope plus one.
    ///
    /// - Parameter category: The category to create.
    /// - Returns: The created category with the assigned `sortOrder`.
    /// - Throws: `CategoryError.nameEmpty` if the name is blank,
    ///           `CategoryError.nameAlreadyExists` if the name is taken in the same scope,
    ///           `CategoryError.parentCategoryNotFound` if the specified parent does not exist,
    ///           or repository errors for persistence failures.
    func execute(_ category: Category) async throws -> Category
}

/// Implementation of category creation use case.
///
/// Validates business rules before persisting a new category, ensuring
/// uniqueness within the correct hierarchy scope and assigning a proper
/// sort order automatically.
public struct CreateCategoryUseCase: CreateCategoryUseCaseProtocol {
    private let repository: CategoryRepositoryProtocol

    /// Creates a new category creation use case.
    ///
    /// - Parameter repository: The repository for category persistence.
    public init(repository: CategoryRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ category: Category) async throws -> Category {
        // 1. Validate name not empty
        let trimmedName = category.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw CategoryError.nameEmpty
        }

        // 2. Check name uniqueness within the same type and parentID scope (case-insensitive)
        let siblings = try await repository.fetchAll(type: category.type)
        let scopedSiblings = siblings.filter { $0.parentID == category.parentID }
        if let duplicate = scopedSiblings.first(where: {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(trimmedName) == .orderedSame
        }) {
            throw CategoryError.nameAlreadyExists(duplicate.name)
        }

        // 3. Validate parent exists when parentID is provided
        if let parentID = category.parentID {
            guard try await repository.fetch(by: parentID) != nil else {
                throw CategoryError.parentCategoryNotFound(parentID)
            }
        }

        // 4. Auto-assign sortOrder = max sortOrder within same scope + 1
        let maxSortOrder = scopedSiblings.map(\.sortOrder).max() ?? -1
        let newSortOrder = maxSortOrder + 1

        // 5. Build the category to persist with the computed sort order
        var newCategory = category
        newCategory.sortOrder = newSortOrder

        // 6. Save and return
        try await repository.save(newCategory)
        return newCategory
    }
}
