import Foundation

/// Protocol for external exchange rate service.
///
/// This protocol abstracts the source of exchange rate data, allowing
/// different implementations (REST API, mock service, etc.).
public protocol ExchangeRateServiceProtocol: Sendable {
    /// Fetches the latest exchange rates for a given base currency.
    ///
    /// This method calls an external API to retrieve current exchange rates.
    ///
    /// - Parameter base: The base currency to fetch rates for.
    /// - Returns: An array of exchange rates from the base currency to all other supported currencies.
    /// - Throws: `ExchangeRateError.networkUnavailable` if the network request fails,
    ///           or other service-specific errors.
    func fetchLatestRates(base: CurrencyCode) async throws -> [ExchangeRate]
}

/// Protocol for currency conversion and exchange rate operations.
///
/// This use case handles currency conversion with intelligent caching,
/// offline fallback, and automatic rate fetching when needed.
public protocol ExchangeRateUseCaseProtocol: Sendable {
    /// Converts an amount from one currency to another.
    ///
    /// This method attempts to use cached rates (within 24h), fetches fresh rates
    /// if the cache is stale, and falls back to expired cache if offline.
    ///
    /// - Parameters:
    ///   - amount: The amount to convert.
    ///   - from: The source currency.
    ///   - to: The target currency.
    /// - Returns: The converted amount in the target currency.
    /// - Throws: `ExchangeRateError.rateNotFound` if no rate is available (even offline),
    ///           or repository/service errors for other failures.
    func convert(amount: Decimal, from: CurrencyCode, to: CurrencyCode) async throws -> Decimal

    /// Fetches the latest exchange rates for a base currency.
    ///
    /// This method always fetches fresh rates from the external service
    /// and updates the cache.
    ///
    /// - Parameter base: The base currency to fetch rates for.
    /// - Returns: An array of fresh exchange rates.
    /// - Throws: `ExchangeRateError.networkUnavailable` if the network request fails,
    ///           or service errors for other failures.
    func fetchLatestRates(base: CurrencyCode) async throws -> [ExchangeRate]

    /// Gets the exchange rate between two currencies.
    ///
    /// This method retrieves the conversion rate, using cached rates when available
    /// and fetching fresh rates when needed.
    ///
    /// - Parameters:
    ///   - from: The source currency.
    ///   - to: The target currency.
    /// - Returns: The exchange rate multiplier (targetAmount = sourceAmount * rate).
    /// - Throws: `ExchangeRateError.rateNotFound` if no rate is available,
    ///           or repository/service errors for other failures.
    func getRate(from: CurrencyCode, to: CurrencyCode) async throws -> Decimal
}

/// Implementation of exchange rate and currency conversion use case.
///
/// This use case provides intelligent caching with configurable expiry,
/// offline fallback support, and automatic refresh of stale rates.
public struct ExchangeRateUseCase: ExchangeRateUseCaseProtocol {
    private let repository: ExchangeRateRepositoryProtocol
    private let service: ExchangeRateServiceProtocol
    private let cacheExpiryInterval: TimeInterval

    /// Creates a new exchange rate use case.
    ///
    /// - Parameters:
    ///   - repository: The repository for exchange rate persistence and caching.
    ///   - service: The external service for fetching fresh exchange rates.
    ///   - cacheExpiryInterval: How long cached rates are considered fresh. Defaults to 24 hours.
    public init(
        repository: ExchangeRateRepositoryProtocol,
        service: ExchangeRateServiceProtocol,
        cacheExpiryInterval: TimeInterval = 24 * 60 * 60
    ) {
        self.repository = repository
        self.service = service
        self.cacheExpiryInterval = cacheExpiryInterval
    }

    public func convert(
        amount: Decimal,
        from: CurrencyCode,
        to: CurrencyCode
    ) async throws -> Decimal {
        // If same currency, no conversion needed
        if from == to {
            return amount
        }

        // Get the exchange rate
        let rate = try await getRate(from: from, to: to)

        // Convert the amount
        return amount * rate
    }

    public func fetchLatestRates(base: CurrencyCode) async throws -> [ExchangeRate] {
        // Fetch fresh rates from the service
        let rates = try await service.fetchLatestRates(base: base)

        // Save to repository for caching
        try await repository.saveRates(rates)

        return rates
    }

    public func getRate(from: CurrencyCode, to: CurrencyCode) async throws -> Decimal {
        // If same currency, rate is 1
        if from == to {
            return Decimal(1)
        }

        // Try to fetch cached rate
        if let cachedRate = try await repository.fetchRate(from: from, to: to, date: nil) {
            let age = Date().timeIntervalSince(cachedRate.date)

            // If cache is fresh (within expiry interval), use it
            if age <= cacheExpiryInterval {
                return cachedRate.rate
            }

            // Cache is stale, try to fetch fresh rates
            do {
                let freshRates = try await service.fetchLatestRates(base: from)
                try await repository.saveRates(freshRates)

                // Find the rate for the target currency
                if let freshRate = freshRates.first(where: { $0.targetCurrency == to }) {
                    return freshRate.rate
                }

                // Fresh fetch succeeded but doesn't include this currency pair
                // Fall back to stale cache as offline fallback
                return cachedRate.rate
            } catch {
                // Network error - use stale cache as offline fallback
                return cachedRate.rate
            }
        }

        // No cached rate, must fetch from service
        do {
            let rates = try await service.fetchLatestRates(base: from)
            try await repository.saveRates(rates)

            if let rate = rates.first(where: { $0.targetCurrency == to }) {
                return rate.rate
            }

            // Service doesn't provide this currency pair
            throw ExchangeRateError.rateNotFound(from: from, to: to)
        } catch {
            // Network error and no cache available
            if error is ExchangeRateError {
                throw error
            }
            throw ExchangeRateError.networkUnavailable
        }
    }
}
