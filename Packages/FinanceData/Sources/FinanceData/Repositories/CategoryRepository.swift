import FinanceCore
import Foundation
import SwiftData

// Alias to disambiguate from the Objective-C `Category` type in the SDK.
private typealias AppCategory = FinanceCore.Category

/// SwiftData-backed repository for Category entities.
///
/// This actor provides thread-safe access to category data using SwiftData's
/// `@ModelActor` macro. Categories do not support soft deletion — they are
/// either present or absent. The `seedDefaults()` method inserts built-in
/// Vietnamese default categories on first launch, and is idempotent.
@ModelActor
public actor CategoryRepository: CategoryRepositoryProtocol {
    // The @ModelActor macro automatically provides:
    // - modelContainer: ModelContainer
    // - modelExecutor: ModelExecutor
    // - init(modelContainer: ModelContainer)

    // MARK: - Fetch

    /// Fetches all categories, optionally filtered by transaction type.
    ///
    /// Results are ordered by `sortOrder` ascending, then `name` ascending.
    ///
    /// - Parameter type: When provided, only categories of that type are returned.
    ///   When nil, categories of all types are returned.
    /// - Returns: An array of matching categories.
    /// - Throws: Repository errors if the fetch operation fails.
    public func fetchAll(type: TransactionType?) async throws -> [FinanceCore.Category] {
        var descriptor = FetchDescriptor<CategoryEntity>()
        descriptor.sortBy = [
            SortDescriptor(\.sortOrder),
            SortDescriptor(\.name),
        ]

        var entities = try modelContext.fetch(descriptor)

        if let type {
            entities = entities.filter { $0.typeRawValue == type.rawValue }
        }

        return entities.map { $0.toDomain() }
    }

    /// Fetches a single category by its unique identifier.
    ///
    /// - Parameter id: The unique identifier of the category.
    /// - Returns: The category if found, nil otherwise.
    /// - Throws: Repository errors if the fetch operation fails.
    public func fetch(by id: UUID) async throws -> FinanceCore.Category? {
        var descriptor = FetchDescriptor<CategoryEntity>()
        descriptor.predicate = #Predicate<CategoryEntity> { $0.id == id }
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    /// Fetches top-level (parentless) categories for the given transaction type.
    ///
    /// Results are ordered by `sortOrder` ascending, then `name` ascending.
    ///
    /// - Parameter type: The transaction type whose root categories are needed.
    /// - Returns: An array of top-level categories.
    /// - Throws: Repository errors if the fetch operation fails.
    public func fetchTopLevel(type: TransactionType) async throws -> [FinanceCore.Category] {
        let typeValue = type.rawValue
        var descriptor = FetchDescriptor<CategoryEntity>()
        descriptor.predicate = #Predicate<CategoryEntity> { entity in
            entity.typeRawValue == typeValue && entity.parentID == nil
        }
        descriptor.sortBy = [
            SortDescriptor(\.sortOrder),
            SortDescriptor(\.name),
        ]
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomain() }
    }

    /// Fetches all direct children of the specified parent category.
    ///
    /// Results are ordered by `sortOrder` ascending, then `name` ascending.
    ///
    /// - Parameter parentID: The unique identifier of the parent category.
    /// - Returns: An array of child categories.
    /// - Throws: Repository errors if the fetch operation fails.
    public func fetchChildren(of parentID: UUID) async throws -> [FinanceCore.Category] {
        var descriptor = FetchDescriptor<CategoryEntity>()
        descriptor.predicate = #Predicate<CategoryEntity> { $0.parentID == parentID }
        descriptor.sortBy = [
            SortDescriptor(\.sortOrder),
            SortDescriptor(\.name),
        ]
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomain() }
    }

    // MARK: - Mutations

    /// Saves or updates a category in the repository.
    ///
    /// If a category with the same `id` already exists it will be updated;
    /// otherwise a new category record is inserted.
    ///
    /// - Parameter category: The category to persist.
    /// - Throws: Repository errors if the save operation fails.
    public func save(_ category: FinanceCore.Category) async throws {
        let categoryID = category.id
        var descriptor = FetchDescriptor<CategoryEntity>()
        descriptor.predicate = #Predicate<CategoryEntity> { $0.id == categoryID }
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.update(from: category)
        } else {
            let entity = CategoryEntity.from(domain: category)
            modelContext.insert(entity)
        }

        try modelContext.save()
    }

    // MARK: - Seeding

    /// Inserts the built-in default Vietnamese categories if the category table is empty.
    ///
    /// This method is idempotent. It checks whether any category record already
    /// exists before inserting, so calling it multiple times is safe and produces
    /// the same result as calling it once.
    ///
    /// - Throws: Repository errors if the seeding operation fails.
    public func seedDefaults() async throws {
        var countDescriptor = FetchDescriptor<CategoryEntity>()
        countDescriptor.fetchLimit = 1
        let existing = try modelContext.fetch(countDescriptor)
        guard existing.isEmpty else { return }

        for category in DefaultCategories.all {
            let entity = CategoryEntity.from(domain: category)
            modelContext.insert(entity)
        }

        try modelContext.save()
    }
}
