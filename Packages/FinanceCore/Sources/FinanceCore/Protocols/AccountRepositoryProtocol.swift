import Foundation

/// Protocol for account data persistence and retrieval operations.
///
/// This protocol defines the contract for account repository implementations,
/// abstracting the underlying data storage mechanism (CoreData, SwiftData, etc.).
/// All methods are async to support both local and remote data sources.
public protocol AccountRepositoryProtocol: Sendable {
    /// Fetches all accounts from the repository.
    ///
    /// - Returns: An array of all accounts, including archived but excluding soft-deleted ones.
    /// - Throws: Repository errors if the fetch operation fails.
    func fetchAll() async throws -> [Account]

    /// Fetches a single account by its unique identifier.
    ///
    /// - Parameter id: The unique identifier of the account.
    /// - Returns: The account if found, nil otherwise.
    /// - Throws: Repository errors if the fetch operation fails.
    func fetch(by id: UUID) async throws -> Account?

    /// Saves or updates an account in the repository.
    ///
    /// If an account with the same ID exists, it will be updated.
    /// Otherwise, a new account will be created.
    ///
    /// - Parameter account: The account to save or update.
    /// - Throws: `AccountError` for validation failures or repository errors for persistence failures.
    func save(_ account: Account) async throws

    /// Deletes an account from the repository.
    ///
    /// This performs a soft delete by setting the `deletedAt` timestamp.
    ///
    /// - Parameter id: The unique identifier of the account to delete.
    /// - Throws: `AccountError.accountNotFound` if the account doesn't exist,
    ///           `AccountError.cannotDeleteAccountWithTransactions` if the account has transactions,
    ///           or repository errors for other failures.
    func delete(by id: UUID) async throws

    /// Fetches all accounts grouped by their type.
    ///
    /// - Returns: A dictionary mapping account types to arrays of accounts of that type.
    /// - Throws: Repository errors if the fetch operation fails.
    func fetchGroupedByType() async throws -> [AccountType: [Account]]

    /// Calculates the total balance across all accounts in a specific currency.
    ///
    /// This method converts all account balances to the specified currency using
    /// current exchange rates and sums them up.
    ///
    /// - Parameter currency: The target currency for the total balance.
    /// - Returns: The total balance in the specified currency.
    /// - Throws: `ExchangeRateError` if conversion rates are unavailable,
    ///           or repository errors for other failures.
    func fetchTotalBalance(in currency: CurrencyCode) async throws -> Decimal

    /// Updates an account's balance by a delta amount.
    ///
    /// This method applies a delta (positive or negative) to an account's current balance.
    /// Typically used when processing transactions.
    ///
    /// - Parameters:
    ///   - accountID: The unique identifier of the account.
    ///   - delta: The amount to add (positive) or subtract (negative) from the balance.
    /// - Throws: `AccountError.accountNotFound` if the account doesn't exist,
    ///           or repository errors for other failures.
    func updateBalance(_ accountID: UUID, delta: Decimal) async throws

    /// Fetches the count of active (non-archived, non-deleted) accounts.
    ///
    /// Used to enforce free tier limits on the number of accounts.
    ///
    /// - Returns: The number of active accounts.
    /// - Throws: Repository errors if the fetch operation fails.
    func fetchActiveCount() async throws -> Int

    /// Updates the sort order for multiple accounts atomically.
    ///
    /// This method is used to implement drag-and-drop reordering of accounts.
    ///
    /// - Parameter orders: An array of tuples containing account ID and new sort order.
    /// - Throws: Repository errors if the update operation fails.
    func updateSortOrders(_ orders: [(UUID, Int)]) async throws
}
