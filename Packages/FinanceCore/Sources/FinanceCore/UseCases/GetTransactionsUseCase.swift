import Foundation

/// Protocol for retrieving and aggregating financial transactions.
///
/// This use case provides three modes of transaction retrieval: paginated flat lists,
/// date-grouped lists for section-based displays, and per-day income/expense totals
/// for chart and summary widgets. All operations delegate directly to the repository.
public protocol GetTransactionsUseCaseProtocol: Sendable {
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
    func execute(filter: TransactionFilter, offset: Int, limit: Int) async throws -> [Transaction]

    /// Fetches transactions matching the given filter grouped by calendar day.
    ///
    /// Each tuple contains a `Date` normalised to midnight (start of day in the
    /// current calendar) paired with the transactions that occurred on that day.
    /// Groups are returned in reverse-chronological order (newest day first).
    ///
    /// - Parameter filter: Criteria used to narrow the result set.
    /// - Returns: An array of `(Date, [Transaction])` pairs ordered newest day first.
    /// - Throws: Repository errors if the fetch operation fails.
    func executeGrouped(filter: TransactionFilter) async throws -> [(Date, [Transaction])]

    /// Calculates per-day income and expense totals for transactions matching the filter.
    ///
    /// Each tuple contains a `Date` normalised to midnight, the total income recorded
    /// that day, and the total expense recorded that day. Days without matching
    /// transactions are omitted. Results are ordered oldest-first (chronological).
    ///
    /// - Parameter filter: Criteria used to narrow the aggregated transactions.
    /// - Returns: An array of `(date:, income:, expense:)` tuples ordered oldest-first.
    /// - Throws: Repository errors if the aggregation fails.
    func dailyTotals(
        filter: TransactionFilter
    ) async throws -> [(date: Date, income: Decimal, expense: Decimal)]
}

// MARK: - Default Parameter Extension

extension GetTransactionsUseCaseProtocol {
    /// Fetches transactions using default pagination values (offset: 0, limit: 50).
    ///
    /// - Parameter filter: Criteria used to narrow the result set.
    /// - Returns: An array of matching transactions ordered newest-first.
    /// - Throws: Repository errors if the fetch operation fails.
    public func execute(filter: TransactionFilter) async throws -> [Transaction] {
        try await execute(filter: filter, offset: 0, limit: 50)
    }
}

/// Implementation of transaction retrieval use case.
///
/// This use case is a pure passthrough to the `TransactionRepositoryProtocol`.
/// All filtering, grouping, and aggregation logic is performed by the repository,
/// which can optimise these operations at the database level.
public struct GetTransactionsUseCase: GetTransactionsUseCaseProtocol {
    private let repository: TransactionRepositoryProtocol

    /// Creates a new transaction retrieval use case.
    ///
    /// - Parameter repository: The repository for transaction data access.
    public init(repository: TransactionRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(filter: TransactionFilter, offset: Int, limit: Int) async throws -> [Transaction] {
        try await repository.fetch(filter: filter, offset: offset, limit: limit)
    }

    public func executeGrouped(filter: TransactionFilter) async throws -> [(Date, [Transaction])] {
        try await repository.fetchGroupedByDate(filter: filter)
    }

    public func dailyTotals(
        filter: TransactionFilter
    ) async throws -> [(date: Date, income: Decimal, expense: Decimal)] {
        try await repository.dailyTotals(filter: filter)
    }
}
