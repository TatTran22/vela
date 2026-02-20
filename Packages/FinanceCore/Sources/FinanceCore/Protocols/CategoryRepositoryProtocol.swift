import Foundation

/// Protocol for category data persistence and retrieval operations.
///
/// Categories form a two-level hierarchy (parent → children). Each category
/// is associated with a `TransactionType` so that income and expense categories
/// are kept separate. This protocol abstracts the underlying storage mechanism.
public protocol CategoryRepositoryProtocol: Sendable {
    /// Fetches all categories, optionally filtered by transaction type.
    ///
    /// - Parameter type: When provided, only categories of that type are returned.
    ///   When nil, categories of all types are returned.
    /// - Returns: An array of matching categories ordered by `sortOrder` then `name`.
    /// - Throws: Repository errors if the fetch operation fails.
    func fetchAll(type: TransactionType?) async throws -> [Category]

    /// Fetches a single category by its unique identifier.
    ///
    /// - Parameter id: The unique identifier of the category.
    /// - Returns: The category if found, nil otherwise.
    /// - Throws: Repository errors if the fetch operation fails.
    func fetch(by id: UUID) async throws -> Category?

    /// Fetches top-level (parentless) categories for the given transaction type.
    ///
    /// These are the categories shown at the root level of the category picker.
    ///
    /// - Parameter type: The transaction type whose root categories are needed.
    /// - Returns: An array of top-level categories ordered by `sortOrder` then `name`.
    /// - Throws: Repository errors if the fetch operation fails.
    func fetchTopLevel(type: TransactionType) async throws -> [Category]

    /// Fetches all direct children of the specified parent category.
    ///
    /// - Parameter parentID: The unique identifier of the parent category.
    /// - Returns: An array of child categories ordered by `sortOrder` then `name`.
    /// - Throws: Repository errors if the fetch operation fails.
    func fetchChildren(of parentID: UUID) async throws -> [Category]

    /// Saves or updates a category in the repository.
    ///
    /// If a category with the same `id` already exists it will be updated;
    /// otherwise a new category record is created.
    ///
    /// - Parameter category: The category to persist.
    /// - Throws: Repository errors if the save operation fails.
    func save(_ category: Category) async throws

    /// Inserts the built-in default categories for all transaction types if they
    /// do not already exist.
    ///
    /// This method is idempotent: calling it multiple times has the same effect
    /// as calling it once. It is typically invoked during first launch or after
    /// a database reset.
    ///
    /// - Throws: Repository errors if the seeding operation fails.
    func seedDefaults() async throws

    /// Deletes a category by its unique identifier.
    ///
    /// For system (default) categories, the implementation may choose to archive
    /// rather than permanently delete. Callers should check `isDefault` before
    /// calling this method when permanent deletion is required.
    ///
    /// - Parameter id: The unique identifier of the category to delete.
    /// - Throws: Repository errors if the delete operation fails.
    func delete(_ id: UUID) async throws

    /// Updates sort orders for multiple categories atomically.
    ///
    /// Each ID in `orderedIDs` receives a `sortOrder` equal to `offset + index`,
    /// where `index` is its zero-based position in the array. This allows
    /// callers to assign non-overlapping ranges across different sections.
    ///
    /// The operation is atomic — either all sort orders are updated or none are.
    ///
    /// - Parameters:
    ///   - orderedIDs: An array of category IDs in their desired display order.
    ///   - offset: The starting sort order value.
    /// - Throws: Repository errors if the update operation fails.
    func reorder(_ orderedIDs: [UUID], startingAt offset: Int) async throws

    /// Checks whether any transaction references the given category.
    ///
    /// - Parameter categoryID: The unique identifier of the category to check.
    /// - Returns: `true` if at least one transaction references this category; otherwise `false`.
    /// - Throws: Repository errors if the check operation fails.
    func hasTransactions(categoryID: UUID) async throws -> Bool
}
