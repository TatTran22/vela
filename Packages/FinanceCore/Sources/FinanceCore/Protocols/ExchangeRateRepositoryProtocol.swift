import Foundation

/// Protocol for exchange rate data persistence and retrieval operations.
///
/// This protocol defines the contract for exchange rate repository implementations,
/// supporting both cached rates and fetching fresh rates from external sources.
public protocol ExchangeRateRepositoryProtocol: Sendable {
    /// Fetches the exchange rate between two currencies for a specific date.
    ///
    /// If no date is specified, returns the most recent available rate.
    /// Implementations should first check the cache, then fall back to fetching
    /// from an external API if needed.
    ///
    /// - Parameters:
    ///   - from: The base currency code.
    ///   - to: The target currency code.
    ///   - date: Optional date for historical rates. If nil, uses current date.
    /// - Returns: The exchange rate if found, nil otherwise.
    /// - Throws: `ExchangeRateError.rateNotFound` if no rate is available,
    ///           `ExchangeRateError.networkUnavailable` if fetching fails,
    ///           or repository errors for other failures.
    func fetchRate(
        from: CurrencyCode,
        to: CurrencyCode,
        date: Date?
    ) async throws -> ExchangeRate?

    /// Saves multiple exchange rates to the repository.
    ///
    /// This method is used to cache exchange rates fetched from external APIs.
    /// Existing rates with the same currency pair and date will be updated.
    ///
    /// - Parameter rates: An array of exchange rates to save.
    /// - Throws: Repository errors if the save operation fails.
    func saveRates(_ rates: [ExchangeRate]) async throws

    /// Deletes exchange rates older than a specified date.
    ///
    /// This method is used to clean up old cached rates and free up storage.
    /// Typically called periodically to remove rates older than 30-90 days.
    ///
    /// - Parameter date: The cutoff date. Rates older than this will be deleted.
    /// - Throws: Repository errors if the delete operation fails.
    func deleteOldRates(before date: Date) async throws
}
