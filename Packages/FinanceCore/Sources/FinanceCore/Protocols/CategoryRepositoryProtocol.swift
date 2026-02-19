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
}
