import Foundation

/// Protocol for searching financial transactions using free-text queries.
///
/// This use case augments a standard `TransactionFilter` with a search query,
/// delegating diacritics-insensitive matching to the repository layer so that
/// database-level optimisations (e.g., pre-normalised index columns) can be used.
public protocol TransactionSearchUseCaseProtocol: Sendable {
    /// Searches for transactions matching both the query text and the filter criteria.
    ///
    /// The search is expected to be case-insensitive and diacritics-insensitive,
    /// meaning "pho" will match transactions with notes containing "Phở" or "phổ".
    /// The actual matching strategy is determined by the repository implementation.
    ///
    /// An empty or whitespace-only query returns all transactions matching `filter`
    /// without any text constraint (equivalent to `filter.searchText == nil`).
    ///
    /// - Parameters:
    ///   - query: Free-text search string to match against transaction notes and metadata.
    ///   - filter: Additional filter criteria to apply alongside the text search.
    /// - Returns: An array of matching transactions ordered newest-first.
    /// - Throws: Repository errors if the search operation fails.
    func execute(query: String, filter: TransactionFilter) async throws -> [Transaction]
}

/// Implementation of transaction full-text search use case.
///
/// This use case merges the search query into the `TransactionFilter.searchText`
/// field and delegates to the `TransactionRepositoryProtocol`. Vietnamese
/// diacritics-insensitive matching is handled at the repository level, which can
/// leverage a pre-normalised column or a collation-aware predicate for efficiency.
///
/// The `VietnameseTextNormalizer` is used to pre-normalize the query before
/// forwarding it, so the repository receives a clean, lowercase, diacritic-free
/// string regardless of what the user typed.
public struct TransactionSearchUseCase: TransactionSearchUseCaseProtocol {
    private let repository: TransactionRepositoryProtocol
    private let normalizer: VietnameseTextNormalizer

    /// Creates a new transaction search use case.
    ///
    /// - Parameters:
    ///   - repository: The repository for transaction data access and search.
    ///   - normalizer: The text normalizer used to pre-process the query.
    ///                 Defaults to a standard `VietnameseTextNormalizer`.
    public init(
        repository: TransactionRepositoryProtocol,
        normalizer: VietnameseTextNormalizer = VietnameseTextNormalizer()
    ) {
        self.repository = repository
        self.normalizer = normalizer
    }

    public func execute(query: String, filter: TransactionFilter) async throws -> [Transaction] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // Build a new filter with the normalised search text merged in.
        // An empty query clears searchText so the repository applies no text constraint.
        var searchFilter = filter
        if trimmed.isEmpty {
            searchFilter.searchText = nil
        } else {
            searchFilter.searchText = normalizer.normalize(trimmed)
        }

        return try await repository.fetch(filter: searchFilter, offset: 0, limit: 50)
    }
}
