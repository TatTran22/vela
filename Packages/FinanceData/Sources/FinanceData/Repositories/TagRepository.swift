import FinanceCore
import Foundation
import SwiftData

/// SwiftData-backed repository for Tag entities.
///
/// This actor provides thread-safe access to tag data using SwiftData's
/// `@ModelActor` macro. Tags use hard delete (physical removal) because they
/// carry no audit or CloudKit-sync requirements that necessitate soft deletion.
@ModelActor
public actor TagRepository: TagRepositoryProtocol {
    // The @ModelActor macro automatically provides:
    // - modelContainer: ModelContainer
    // - modelExecutor: ModelExecutor
    // - init(modelContainer: ModelContainer)

    /// Fetches all tags, ordered alphabetically by name.
    ///
    /// - Returns: An array containing every tag in the repository.
    /// - Throws: Repository errors if the fetch operation fails.
    public func fetchAll() async throws -> [Tag] {
        var descriptor = FetchDescriptor<TagEntity>()
        descriptor.sortBy = [SortDescriptor(\.name)]
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomain() }
    }

    /// Saves or updates a tag in the repository.
    ///
    /// If a tag with the same `id` already exists it will be updated;
    /// otherwise a new tag record is inserted.
    ///
    /// - Parameter tag: The tag to persist.
    /// - Throws: Repository errors if the save operation fails.
    public func save(_ tag: Tag) async throws {
        var descriptor = FetchDescriptor<TagEntity>()
        descriptor.predicate = #Predicate<TagEntity> { $0.id == tag.id }
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.update(from: tag)
        } else {
            let entity = TagEntity.from(domain: tag)
            modelContext.insert(entity)
        }

        try modelContext.save()
    }

    /// Permanently deletes a tag from the repository.
    ///
    /// Unlike transactions, tags use hard delete. After deletion the tag is no
    /// longer referenced in any UI query; `TransactionEntity.tags` stores UUIDs
    /// as a JSON string and is not enforced by a foreign key, so orphaned UUIDs
    /// are simply ignored during mapping.
    ///
    /// - Parameter id: The unique identifier of the tag to delete.
    /// - Throws: Repository errors if the delete operation fails.
    public func delete(by id: UUID) async throws {
        var descriptor = FetchDescriptor<TagEntity>()
        descriptor.predicate = #Predicate<TagEntity> { $0.id == id }
        descriptor.fetchLimit = 1

        guard let entity = try modelContext.fetch(descriptor).first else {
            return
        }

        modelContext.delete(entity)
        try modelContext.save()
    }
}
