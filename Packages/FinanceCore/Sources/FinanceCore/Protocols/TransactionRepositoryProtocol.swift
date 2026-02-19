import Foundation

/// Protocol for transaction data persistence and retrieval operations.
///
/// This protocol defines the contract for transaction repository implementations,
/// abstracting the underlying data storage mechanism (CoreData, SwiftData, etc.).
/// All methods are async to support both local and remote data sources.
/// Deletions are always soft deletes: the `deletedAt` timestamp is set rather
/// than the record being physically removed.
public protocol TransactionRepositoryProtocol: Sendable {
    /// Fetches a paginated list of transactions matching the given filter.
    ///
    /// Results are returned in reverse-chronological order (newest first).
    /// Only non-deleted transactions are returned.
    ///
    /// - Parameters:
    ///   - filter: Criteria used to narrow the result set.
    ///   - offset: Number of matching records to skip (for pagination). Defaults to 0.
    ///   - limit: Maximum number of records to return. Defaults to 50.
    /// - Returns: An array of matching transactions.
    /// - Throws: Repository errors if the fetch operation fails.
    func fetch(filter: TransactionFilter, offset: Int, limit: Int) async throws -> [Transaction]

    /// Fetches transactions matching the given filter and groups them by calendar day.
    ///
    /// Each tuple contains a `Date` normalised to midnight (start of day in the
    /// current calendar) and the transactions that occurred on that day.
    /// Groups are returned in reverse-chronological order.
    ///
    /// - Parameter filter: Criteria used to narrow the result set.
    /// - Returns: An array of `(Date, [Transaction])` pairs ordered newest-first.
    /// - Throws: Repository errors if the fetch operation fails.
    func fetchGroupedByDate(filter: TransactionFilter) async throws -> [(Date, [Transaction])]

    /// Fetches a single transaction by its unique identifier.
    ///
    /// - Parameter id: The unique identifier of the transaction.
    /// - Returns: The transaction if found and not deleted, nil otherwise.
    /// - Throws: Repository errors if the fetch operation fails.
    func fetch(by id: UUID) async throws -> Transaction?

    /// Saves a new transaction to the repository.
    ///
    /// - Parameter transaction: The transaction to persist.
    /// - Throws: `TransactionError` for validation failures, or repository errors
    ///           for persistence failures.
    func save(_ transaction: Transaction) async throws

    /// Updates an existing transaction in the repository.
    ///
    /// - Parameter transaction: The transaction with updated values. The `id` field
    ///   is used to locate the existing record.
    /// - Throws: `TransactionError.transactionNotFound` if no record matches the ID,
    ///           `TransactionError` for other validation failures, or repository errors
    ///           for persistence failures.
    func update(_ transaction: Transaction) async throws

    /// Soft-deletes a transaction by setting its `deletedAt` timestamp.
    ///
    /// Soft-deleted transactions are excluded from all `fetch` calls but remain
    /// in the database for audit and CloudKit sync purposes.
    ///
    /// - Parameter id: The unique identifier of the transaction to delete.
    /// - Throws: `TransactionError.transactionNotFound` if no record matches the ID,
    ///           or repository errors for other failures.
    func delete(by id: UUID) async throws

    /// Returns the total number of non-deleted transactions matching the given filter.
    ///
    /// This is more efficient than fetching all records when only the count is needed,
    /// for example to determine whether to show a placeholder state.
    ///
    /// - Parameter filter: Criteria used to narrow the counted records.
    /// - Returns: The count of matching non-deleted transactions.
    /// - Throws: Repository errors if the count operation fails.
    func count(filter: TransactionFilter) async throws -> Int

    /// Calculates per-day income and expense totals for transactions matching the filter.
    ///
    /// Each tuple contains a `Date` normalised to midnight, the total income amount
    /// recorded that day, and the total expense amount recorded that day. Days with
    /// no matching transactions are omitted. Results are returned in chronological order.
    ///
    /// - Parameter filter: Criteria used to narrow the aggregated transactions.
    /// - Returns: An array of `(date:, income:, expense:)` tuples ordered oldest-first.
    /// - Throws: Repository errors if the aggregation fails.
    func dailyTotals(
        filter: TransactionFilter
    ) async throws -> [(date: Date, income: Decimal, expense: Decimal)]
}
