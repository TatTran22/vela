import FinanceCore
import Foundation
import SwiftData

/// SwiftData-backed repository for Transaction entities.
///
/// This actor provides thread-safe access to transaction data using SwiftData's
/// `@ModelActor` macro. All fetch operations exclude soft-deleted records
/// (those with a non-nil `deletedAt` timestamp).
///
/// Because SwiftData's `#Predicate` macro cannot build fully dynamic predicates
/// at compile time, filtering on multi-value fields (account IDs, category IDs,
/// tag IDs, amount ranges, and search text) is applied in-memory after the
/// initial database fetch. The database-level predicate always enforces
/// `deletedAt == nil` and, when available as a single-value optimisation,
/// a date-range clause.
@ModelActor
public actor TransactionRepository: TransactionRepositoryProtocol {
    // The @ModelActor macro automatically provides:
    // - modelContainer: ModelContainer
    // - modelExecutor: ModelExecutor
    // - init(modelContainer: ModelContainer)

    // MARK: - Fetch

    /// Fetches a paginated list of transactions matching the given filter.
    ///
    /// Results are returned in reverse-chronological order (newest first).
    /// Only non-deleted transactions are returned.
    ///
    /// - Parameters:
    ///   - filter: Criteria used to narrow the result set.
    ///   - offset: Number of matching records to skip for pagination. Defaults to 0.
    ///   - limit: Maximum number of records to return. Defaults to 50.
    /// - Returns: An array of matching transactions ordered newest-first.
    /// - Throws: Repository errors if the fetch operation fails.
    public func fetch(filter: TransactionFilter, offset: Int = 0, limit: Int = 50) async throws -> [Transaction] {
        let entities = try fetchEntities(matching: filter)
        let paged = Array(entities.dropFirst(offset).prefix(limit))
        return paged.map { $0.toDomain() }
    }

    /// Fetches transactions matching the given filter and groups them by calendar day.
    ///
    /// Each tuple contains a `Date` normalised to midnight and the transactions
    /// that occurred on that day. Groups are returned in reverse-chronological order.
    ///
    /// - Parameter filter: Criteria used to narrow the result set.
    /// - Returns: An array of `(Date, [Transaction])` pairs ordered newest-first.
    /// - Throws: Repository errors if the fetch operation fails.
    public func fetchGroupedByDate(filter: TransactionFilter) async throws -> [(Date, [Transaction])] {
        let entities = try fetchEntities(matching: filter)
        let calendar = Calendar.current

        var groups: [Date: [Transaction]] = [:]
        for entity in entities {
            let dayKey = calendar.startOfDay(for: entity.date)
            groups[dayKey, default: []].append(entity.toDomain())
        }

        return groups
            .sorted { $0.key > $1.key }
            .map { ($0.key, $0.value) }
    }

    /// Fetches a single transaction by its unique identifier.
    ///
    /// - Parameter id: The unique identifier of the transaction.
    /// - Returns: The transaction if found and not soft-deleted, nil otherwise.
    /// - Throws: Repository errors if the fetch operation fails.
    public func fetch(by id: UUID) async throws -> Transaction? {
        var descriptor = FetchDescriptor<TransactionEntity>()
        descriptor.predicate = #Predicate<TransactionEntity> { entity in
            entity.id == id && entity.deletedAt == nil
        }
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    // MARK: - Mutations

    /// Saves a transaction to the repository.
    ///
    /// If a record with the same `id` already exists it is updated; otherwise a
    /// new record is inserted.
    ///
    /// - Parameter transaction: The transaction to persist.
    /// - Throws: Repository errors if the save operation fails.
    public func save(_ transaction: Transaction) async throws {
        var descriptor = FetchDescriptor<TransactionEntity>()
        descriptor.predicate = #Predicate<TransactionEntity> { $0.id == transaction.id }
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.update(from: transaction)
        } else {
            let entity = TransactionEntity.from(domain: transaction)
            modelContext.insert(entity)
        }

        try modelContext.save()
    }

    /// Updates an existing transaction in the repository.
    ///
    /// - Parameter transaction: The transaction with updated values. The `id`
    ///   field is used to locate the existing record.
    /// - Throws: `TransactionError.transactionNotFound` if no record matches the ID,
    ///   or repository errors for persistence failures.
    public func update(_ transaction: Transaction) async throws {
        var descriptor = FetchDescriptor<TransactionEntity>()
        descriptor.predicate = #Predicate<TransactionEntity> { $0.id == transaction.id }
        descriptor.fetchLimit = 1

        guard let entity = try modelContext.fetch(descriptor).first else {
            throw TransactionError.transactionNotFound(transaction.id)
        }

        entity.update(from: transaction)
        try modelContext.save()
    }

    /// Soft-deletes a transaction by setting its `deletedAt` timestamp to now.
    ///
    /// The record remains in the database for audit and CloudKit sync purposes.
    ///
    /// - Parameter id: The unique identifier of the transaction to delete.
    /// - Throws: `TransactionError.transactionNotFound` if no record matches the ID,
    ///   or repository errors for other failures.
    public func delete(by id: UUID) async throws {
        var descriptor = FetchDescriptor<TransactionEntity>()
        descriptor.predicate = #Predicate<TransactionEntity> { $0.id == id }
        descriptor.fetchLimit = 1

        guard let entity = try modelContext.fetch(descriptor).first else {
            throw TransactionError.transactionNotFound(id)
        }

        entity.deletedAt = Date()
        try modelContext.save()
    }

    // MARK: - Aggregates

    /// Returns the total number of non-deleted transactions matching the given filter.
    ///
    /// - Parameter filter: Criteria used to narrow the counted records.
    /// - Returns: The count of matching non-deleted transactions.
    /// - Throws: Repository errors if the count operation fails.
    public func count(filter: TransactionFilter) async throws -> Int {
        try fetchEntities(matching: filter).count
    }

    /// Calculates per-day income and expense totals for transactions matching the filter.
    ///
    /// Each tuple contains a `Date` normalised to midnight, total income for that
    /// day, and total expense for that day. Days with no matching transactions are
    /// omitted. Results are ordered oldest-first (chronological).
    ///
    /// - Parameter filter: Criteria used to narrow the aggregated transactions.
    /// - Returns: An array of `(date:, income:, expense:)` tuples ordered oldest-first.
    /// - Throws: Repository errors if the aggregation fails.
    public func dailyTotals(
        filter: TransactionFilter
    ) async throws -> [(date: Date, income: Decimal, expense: Decimal)] {
        let entities = try fetchEntities(matching: filter)
        let calendar = Calendar.current

        var totals: [Date: (income: Decimal, expense: Decimal)] = [:]
        for entity in entities {
            let dayKey = calendar.startOfDay(for: entity.date)
            var current = totals[dayKey] ?? (income: 0, expense: 0)
            switch TransactionType(rawValue: entity.type) ?? .expense {
            case .income:
                current.income += entity.amount
            case .expense:
                current.expense += entity.amount
            case .transfer:
                break
            }
            totals[dayKey] = current
        }

        return totals
            .sorted { $0.key < $1.key }
            .map { (date: $0.key, income: $0.value.income, expense: $0.value.expense) }
    }
}

// MARK: - Private Helpers

private extension TransactionRepository {
    /// Fetches all `TransactionEntity` rows that pass the base database predicate
    /// (`deletedAt == nil`) and then applies the remaining filter criteria in-memory.
    ///
    /// The sort is always by date descending (newest first).
    ///
    /// - Parameter filter: The filter to apply.
    /// - Returns: Filtered entities in reverse-chronological order.
    func fetchEntities(matching filter: TransactionFilter) throws -> [TransactionEntity] {
        var descriptor = FetchDescriptor<TransactionEntity>()
        descriptor.predicate = #Predicate<TransactionEntity> { $0.deletedAt == nil }
        descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]

        var entities = try modelContext.fetch(descriptor)

        // Date range
        if let range = filter.dateRange {
            entities = entities.filter { range.contains($0.date) }
        }

        // Account IDs
        if let accountIDs = filter.accountIDs, !accountIDs.isEmpty {
            entities = entities.filter { accountIDs.contains($0.accountID) }
        }

        // Category IDs
        if let categoryIDs = filter.categoryIDs, !categoryIDs.isEmpty {
            entities = entities.filter { categoryIDs.contains($0.categoryID) }
        }

        // Transaction types
        if let types = filter.types, !types.isEmpty {
            let rawValues = types.map { $0.rawValue }
            entities = entities.filter { rawValues.contains($0.type) }
        }

        // Exclude transfers
        if filter.excludeTransfers {
            entities = entities.filter { $0.type != TransactionType.transfer.rawValue }
        }

        // Amount range
        if let amountRange = filter.amountRange {
            entities = entities.filter { amountRange.contains($0.amount) }
        }

        // Tag IDs — the tags field is a JSON-encoded [UUID] string
        if let tagIDs = filter.tagIDs, !tagIDs.isEmpty {
            entities = entities.filter { entity in
                let entityTagStrings = entity.tags
                return tagIDs.contains { tagID in
                    entityTagStrings.contains(tagID.uuidString)
                }
            }
        }

        // Free-text search on note
        if let searchText = filter.searchText, !searchText.isEmpty {
            let lowercased = searchText.lowercased()
            entities = entities.filter { $0.note.lowercased().contains(lowercased) }
        }

        return entities
    }
}
