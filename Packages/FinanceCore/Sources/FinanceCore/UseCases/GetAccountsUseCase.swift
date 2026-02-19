import Foundation

/// Filter criteria for querying accounts.
///
/// This struct defines the various filtering options available when
/// retrieving accounts from the repository.
public struct AccountFilter: Sendable, Hashable {
    /// Whether to include archived accounts in results.
    public var includeArchived: Bool

    /// Whether to include hidden accounts in results.
    public var includeHidden: Bool

    /// If specified, only return accounts of these types. If nil, return all types.
    public var types: Set<AccountType>?

    /// Creates a new account filter.
    ///
    /// - Parameters:
    ///   - includeArchived: Whether to include archived accounts. Defaults to false.
    ///   - includeHidden: Whether to include hidden accounts. Defaults to false.
    ///   - types: Optional set of account types to filter by. If nil, all types are included.
    public init(
        includeArchived: Bool = false,
        includeHidden: Bool = false,
        types: Set<AccountType>? = nil
    ) {
        self.includeArchived = includeArchived
        self.includeHidden = includeHidden
        self.types = types
    }

    /// Default filter showing only active, non-hidden accounts of all types.
    public static let `default` = AccountFilter()
}

/// Protocol for retrieving financial accounts.
///
/// This use case handles account retrieval with flexible filtering options,
/// grouping capabilities, and total balance calculation across currencies.
public protocol GetAccountsUseCaseProtocol: Sendable {
    /// Retrieves accounts matching the specified filter criteria.
    ///
    /// Results are filtered to exclude soft-deleted accounts and sorted by sortOrder.
    ///
    /// - Parameter filter: The filter criteria to apply.
    /// - Returns: An array of accounts matching the filter, sorted by sortOrder.
    /// - Throws: Repository errors if the fetch operation fails.
    func execute(filter: AccountFilter) async throws -> [Account]

    /// Retrieves accounts grouped by their account type.
    ///
    /// Results are filtered according to the specified criteria and then
    /// grouped by AccountType. Soft-deleted accounts are excluded.
    ///
    /// - Parameter filter: The filter criteria to apply.
    /// - Returns: A dictionary mapping account types to arrays of accounts, sorted by sortOrder within each group.
    /// - Throws: Repository errors if the fetch operation fails.
    func executeGrouped(filter: AccountFilter) async throws -> [AccountType: [Account]]

    /// Calculates the total balance across all accounts in a specific currency.
    ///
    /// This method converts all account balances to the specified currency
    /// using current exchange rates and sums them up. Only active (non-archived,
    /// non-hidden, non-deleted) accounts are included in the calculation.
    ///
    /// - Parameter currency: The target currency for the total balance.
    /// - Returns: The total balance in the specified currency.
    /// - Throws: `ExchangeRateError` if conversion rates are unavailable,
    ///           or repository errors for other failures.
    func executeTotalBalance(in currency: CurrencyCode) async throws -> Decimal
}

/// Implementation of account retrieval use case.
///
/// This use case provides flexible account querying with filtering,
/// grouping, and multi-currency balance aggregation.
public struct GetAccountsUseCase: GetAccountsUseCaseProtocol {
    private let repository: AccountRepositoryProtocol

    /// Creates a new account retrieval use case.
    ///
    /// - Parameter repository: The repository for account persistence.
    public init(repository: AccountRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(filter: AccountFilter) async throws -> [Account] {
        // Fetch all accounts from repository
        let allAccounts = try await repository.fetchAll()

        // Apply filters
        let filteredAccounts = allAccounts.filter { account in
            // Exclude soft-deleted accounts
            guard account.deletedAt == nil else { return false }

            // Filter by archived status
            if !filter.includeArchived && account.isArchived { return false }

            // Filter by hidden status
            if !filter.includeHidden && account.isHidden { return false }

            // Filter by account type if specified
            if let types = filter.types, !types.contains(account.type) { return false }

            return true
        }

        // Sort by sortOrder
        return filteredAccounts.sorted { $0.sortOrder < $1.sortOrder }
    }

    public func executeGrouped(filter: AccountFilter) async throws -> [AccountType: [Account]] {
        // Get filtered accounts
        let accounts = try await execute(filter: filter)

        // Group by account type
        var grouped: [AccountType: [Account]] = [:]
        for account in accounts {
            grouped[account.type, default: []].append(account)
        }

        // Ensure each group is sorted by sortOrder
        for type in grouped.keys {
            grouped[type] = grouped[type]?.sorted { $0.sortOrder < $1.sortOrder }
        }

        return grouped
    }

    public func executeTotalBalance(in currency: CurrencyCode) async throws -> Decimal {
        // Delegate to repository which handles currency conversion
        return try await repository.fetchTotalBalance(in: currency)
    }
}
