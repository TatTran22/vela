import FinanceCore
import Foundation

/// Fetches exchange rates from an external API.
///
/// This service integrates with exchangerate-api.com to fetch current
/// exchange rates for currency conversion. Rates are returned for all
/// supported currencies based on a given base currency.
public struct ExchangeRateService: Sendable {
    private let session: URLSession
    private let baseURL: URL

    /// Creates a new exchange rate service.
    ///
    /// - Parameters:
    ///   - session: The URLSession to use for network requests. Defaults to `.shared`.
    ///   - baseURL: The base URL for the exchange rate API. Defaults to exchangerate-api.com.
    public init(
        session: URLSession = .shared,
        baseURL: URL = URL(string: "https://api.exchangerate-api.com/v4/latest/")!
    ) {
        self.session = session
        self.baseURL = baseURL
    }

    /// Fetches the latest exchange rates for a given base currency.
    ///
    /// Makes an API request to fetch current exchange rates from the base currency
    /// to all supported currencies in the application.
    ///
    /// - Parameter base: The base currency to fetch rates for.
    /// - Returns: An array of exchange rates from the base currency to all other supported currencies.
    /// - Throws: `ExchangeRateError.networkUnavailable` if the network request fails.
    public func fetchLatestRates(base: CurrencyCode) async throws -> [ExchangeRate] {
        let url = baseURL.appendingPathComponent(base.rawValue)
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ExchangeRateError.networkUnavailable
        }

        // Parse JSON response
        let decoded = try JSONDecoder().decode(ExchangeRateAPIResponse.self, from: data)

        // Convert to ExchangeRate models for all supported currencies
        return CurrencyCode.allCases.compactMap { targetCurrency in
            guard targetCurrency != base,
                  let rate = decoded.rates[targetCurrency.rawValue] else { return nil }
            return ExchangeRate(
                baseCurrency: base,
                targetCurrency: targetCurrency,
                rate: Decimal(rate),
                date: Date(),
                source: "exchangerate-api.com"
            )
        }
    }
}

// MARK: - Internal API Response Model

/// Internal response model for the exchangerate-api.com API.
///
/// This struct represents the JSON structure returned by the API and is
/// used only within the service for decoding purposes.
struct ExchangeRateAPIResponse: Decodable {
    let base: String
    let rates: [String: Double]
}
