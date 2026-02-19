import Foundation

@testable import FinanceCore

/// Mock implementation of ExchangeRateRepositoryProtocol for testing.
///
/// This mock repository stores exchange rates in memory and supports
/// fetching and saving rates for use in unit tests.
actor MockExchangeRateRepository: ExchangeRateRepositoryProtocol {
    private var rates: [String: ExchangeRate] = [:]

    func fetchRate(
        from: CurrencyCode,
        to: CurrencyCode,
        date: Date?
    ) async throws -> ExchangeRate? {
        let key = makeKey(from: from, to: to)
        return rates[key]
    }

    func saveRates(_ rates: [ExchangeRate]) async throws {
        for rate in rates {
            let key = makeKey(from: rate.baseCurrency, to: rate.targetCurrency)
            self.rates[key] = rate
        }
    }

    func deleteOldRates(before date: Date) async throws {
        rates = rates.filter { $0.value.date >= date }
    }

    // Testing helper methods
    func reset() {
        rates.removeAll()
    }

    private func makeKey(from: CurrencyCode, to: CurrencyCode) -> String {
        "\(from.rawValue)-\(to.rawValue)"
    }
}
