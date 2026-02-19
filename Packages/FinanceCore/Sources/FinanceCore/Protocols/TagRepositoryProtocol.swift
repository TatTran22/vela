import Foundation

/// Protocol for tag data persistence and retrieval operations.
///
/// Tags are lightweight labels applied to transactions. This protocol defines
/// the minimal contract required to manage the tag catalogue, abstracting
/// the underlying storage mechanism.
public protocol TagRepositoryProtocol: Sendable {
    /// Fetches all tags, ordered alphabetically by name.
    ///
    /// - Returns: An array containing every tag in the repository.
    /// - Throws: Repository errors if the fetch operation fails.
    func fetchAll() async throws -> [Tag]

    /// Saves or updates a tag in the repository.
    ///
    /// If a tag with the same `id` already exists it will be updated;
    /// otherwise a new tag record is created.
    ///
    /// - Parameter tag: The tag to persist.
    /// - Throws: Repository errors if the save operation fails.
    func save(_ tag: Tag) async throws

    /// Permanently deletes a tag and removes it from all associated transactions.
    ///
    /// - Parameter id: The unique identifier of the tag to delete.
    /// - Throws: Repository errors if the delete operation fails.
    func delete(by id: UUID) async throws
}
