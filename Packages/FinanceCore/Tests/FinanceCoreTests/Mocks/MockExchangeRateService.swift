import Foundation

@testable import FinanceCore

/// Mock implementation of ExchangeRateServiceProtocol for testing.
///
/// This mock service can be configured to return specific exchange rates
/// or throw errors for testing different scenarios.
actor MockExchangeRateService: ExchangeRateServiceProtocol {
    var shouldThrowError = false
    var mockRates: [ExchangeRate] = []

    func fetchLatestRates(base: CurrencyCode) async throws -> [ExchangeRate] {
        if shouldThrowError {
            throw ExchangeRateError.networkUnavailable
        }

        // If mock rates are set, return them
        if !mockRates.isEmpty {
            return mockRates.filter { $0.baseCurrency == base }
        }

        // Default behavior: return some common currency pairs
        let now = Date()
        switch base {
        case .USD:
            return [
                ExchangeRate(baseCurrency: .USD, targetCurrency: .VND, rate: 25000, date: now, source: "mock"),
                ExchangeRate(baseCurrency: .USD, targetCurrency: .EUR, rate: 0.92, date: now, source: "mock"),
            ]
        case .VND:
            return [
                ExchangeRate(baseCurrency: .VND, targetCurrency: .USD, rate: 0.00004, date: now, source: "mock"),
            ]
        case .EUR:
            return [
                ExchangeRate(baseCurrency: .EUR, targetCurrency: .USD, rate: 1.09, date: now, source: "mock"),
            ]
        default:
            return []
        }
    }

    // Testing helper methods
    func reset() {
        shouldThrowError = false
        mockRates = []
    }
}
