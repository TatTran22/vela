import Foundation

/// Protocol for updating existing categories.
///
/// This use case handles category updates with validation of business rules
/// including name uniqueness, type-change restrictions, and circular-parent
/// reference detection.
public protocol UpdateCategoryUseCaseProtocol: Sendable {
    /// Updates an existing category after validating business rules.
    ///
    /// The category will be validated for:
    /// - Existence (must be fetchable by ID)
    /// - Non-empty name (trimmed)
    /// - Name uniqueness within the same `type` and `parentID` scope (case-insensitive, excluding self)
    /// - Type changes are forbidden when the category has existing transactions
    /// - Parent changes must not create a circular reference in the hierarchy
    /// - Parent existence when `parentID` is set
    ///
    /// - Parameter category: The category with updated values.
    /// - Returns: The saved category.
    /// - Throws: `CategoryError.categoryNotFound` if the category does not exist,
    ///           `CategoryError.nameEmpty` if the name is blank,
    ///           `CategoryError.nameAlreadyExists` if the name is taken in the same scope by another category,
    ///           `CategoryError.cannotChangeTypeWithTransactions` if the type changed and transactions exist,
    ///           `CategoryError.circularParentReference` if the new parent creates a cycle,
    ///           `CategoryError.parentCategoryNotFound` if the specified parent does not exist,
    ///           or repository errors for persistence failures.
    func execute(_ category: Category) async throws -> Category
}

/// Implementation of category update use case.
///
/// Validates business rules before persisting category changes, protecting
/// transaction integrity and preventing invalid hierarchy mutations.
public struct UpdateCategoryUseCase: UpdateCategoryUseCaseProtocol {
    private let repository: CategoryRepositoryProtocol

    /// Creates a new category update use case.
    ///
    /// - Parameter repository: The repository for category persistence.
    public init(repository: CategoryRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ category: Category) async throws -> Category {
        // 1. Verify the category exists
        guard let original = try await repository.fetch(by: category.id) else {
            throw CategoryError.categoryNotFound(category.id)
        }

        // 2. Validate name not empty
        let trimmedName = category.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw CategoryError.nameEmpty
        }

        // 3. Check name uniqueness within same type + parentID scope (excluding self)
        let siblings = try await repository.fetchAll(type: category.type)
        let scopedSiblings = siblings.filter {
            $0.parentID == category.parentID && $0.id != category.id
        }
        if let duplicate = scopedSiblings.first(where: {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(trimmedName) == .orderedSame
        }) {
            throw CategoryError.nameAlreadyExists(duplicate.name)
        }

        // 4. Check type change restriction when transactions exist
        if original.type != category.type {
            let hasTransactions = try await repository.hasTransactions(categoryID: category.id)
            if hasTransactions {
                throw CategoryError.cannotChangeTypeWithTransactions
            }
        }

        // 5. Validate parent change does not introduce a circular reference
        if original.parentID != category.parentID, let newParentID = category.parentID {
            // Confirm the parent exists
            guard try await repository.fetch(by: newParentID) != nil else {
                throw CategoryError.parentCategoryNotFound(newParentID)
            }

            // Walk the ancestor chain from newParentID upward; if we encounter
            // category.id at any point the assignment would create a cycle.
            var currentID: UUID? = newParentID
            while let ancestorID = currentID {
                if ancestorID == category.id {
                    throw CategoryError.circularParentReference
                }
                guard let ancestor = try await repository.fetch(by: ancestorID) else {
                    break
                }
                currentID = ancestor.parentID
            }
        }

        // 6. Save and return
        try await repository.save(category)
        return category
    }
}
