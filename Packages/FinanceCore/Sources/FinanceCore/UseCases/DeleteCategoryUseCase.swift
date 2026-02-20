import Foundation

/// Protocol for deleting categories.
///
/// This use case handles category deletion with protection against removing
/// categories that still have associated transactions. System (default) categories
/// are archived rather than permanently deleted to preserve referential integrity.
public protocol DeleteCategoryUseCaseProtocol: Sendable {
    /// Deletes or archives a category after validating business rules.
    ///
    /// Behaviour depends on whether the category is a system default:
    /// - **Default categories**: archived (`isArchived = true`) instead of deleted.
    ///   Their direct children are also archived.
    /// - **Non-default categories**: permanently deleted via the repository.
    ///   Their direct children are archived first (to avoid orphaned records).
    ///
    /// In all cases, if the category has existing transactions the operation is
    /// rejected — the caller must reassign or delete those transactions first.
    ///
    /// - Parameter id: The unique identifier of the category to delete.
    /// - Throws: `CategoryError.categoryNotFound` if the category does not exist,
    ///           `CategoryError.cannotDeleteCategoryWithTransactions` if the category
    ///           has associated transactions,
    ///           or repository errors for persistence failures.
    func execute(id: UUID) async throws
}

/// Implementation of category deletion use case.
///
/// Validates business rules before deleting or archiving a category, ensuring
/// no transactions are left without a valid category reference.
public struct DeleteCategoryUseCase: DeleteCategoryUseCaseProtocol {
    private let repository: CategoryRepositoryProtocol

    /// Creates a new category deletion use case.
    ///
    /// - Parameter repository: The repository for category persistence.
    public init(repository: CategoryRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(id: UUID) async throws {
        // 1. Fetch the category — throw if not found
        guard var category = try await repository.fetch(by: id) else {
            throw CategoryError.categoryNotFound(id)
        }

        // 2. Reject deletion when transactions reference this category
        let hasTransactions = try await repository.hasTransactions(categoryID: id)
        if hasTransactions {
            throw CategoryError.cannotDeleteCategoryWithTransactions(reassignTo: nil)
        }

        // 3. Handle children before acting on the parent
        let children = try await repository.fetchChildren(of: id)
        for var child in children {
            // Archive each child regardless of parent disposition
            child.isArchived = true
            try await repository.save(child)
        }

        // 4. Act on the parent based on whether it is a system default
        if category.isDefault {
            // System categories: archive instead of deleting
            category.isArchived = true
            try await repository.save(category)
        } else {
            // Non-default categories: permanently delete
            try await repository.delete(id)
        }
    }
}
