import Foundation

/// Protocol for reordering categories.
///
/// This use case handles manual reordering of categories for customized
/// display order in the category picker and management screens.
public protocol ReorderCategoriesUseCaseProtocol: Sendable {
    /// Updates the sort order of multiple categories based on their new positions.
    ///
    /// This method is typically called after a drag-and-drop reordering operation
    /// in the UI. Each category in `orderedIDs` receives a `sortOrder` equal to
    /// `offset + index`, where `index` is its zero-based position in the array.
    ///
    /// Providing an `offset` lets callers assign non-overlapping sort-order ranges
    /// across different sections (e.g., across different parent categories or types).
    ///
    /// The operation is atomic — either all sort orders are updated successfully,
    /// or none are changed if an error occurs.
    ///
    /// - Parameters:
    ///   - orderedIDs: An array of category IDs in their desired display order.
    ///   - offset: The starting sort order value. Defaults to 0.
    /// - Throws: Repository errors if the update operation fails.
    func execute(orderedIDs: [UUID], startingAt offset: Int) async throws
}

/// Implementation of category reordering use case.
///
/// Delegates directly to the repository's atomic reorder operation,
/// mapping array positions to sort-order values starting at `offset`.
public struct ReorderCategoriesUseCase: ReorderCategoriesUseCaseProtocol {
    private let repository: CategoryRepositoryProtocol

    /// Creates a new category reordering use case.
    ///
    /// - Parameter repository: The repository for category persistence.
    public init(repository: CategoryRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(orderedIDs: [UUID], startingAt offset: Int = 0) async throws {
        // Delegate the atomic sort-order update to the repository
        try await repository.reorder(orderedIDs, startingAt: offset)
    }
}
