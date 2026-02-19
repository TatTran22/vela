import Foundation
import SwiftData
import Testing

@testable import FinanceCore
@testable import FinanceData

@Suite("ExchangeRateRepository Tests")
struct ExchangeRateRepositoryTests {
    private func createTestContainer() throws -> ModelContainer {
        try ModelContainerSetup.createContainer(inMemory: true)
    }

    @Test("Fetch rate returns nil when no rates exist")
    func fetchRateEmpty() async throws {
        let container = try createTestContainer()
        let repository = ExchangeRateRepository(modelContainer: container)

        let rate = try await repository.fetchRate(from: .USD, to: .VND, date: nil)
        #expect(rate == nil)
    }

    @Test("Save and fetch rate")
    func saveAndFetchRate() async throws {
        let container = try createTestContainer()
        let repository = ExchangeRateRepository(modelContainer: container)

        let rate = ExchangeRate(
            baseCurrency: .USD,
            targetCurrency: .VND,
            rate: 23000,
            date: Date(),
            source: "test"
        )

        try await repository.saveRates([rate])
        let fetched = try await repository.fetchRate(from: .USD, to: .VND, date: nil)

        #expect(fetched != nil)
        #expect(fetched?.baseCurrency == .USD)
        #expect(fetched?.targetCurrency == .VND)
        #expect(fetched?.rate == 23000)
        #expect(fetched?.source == "test")
    }

    @Test("Save multiple rates")
    func saveMultipleRates() async throws {
        let container = try createTestContainer()
        let repository = ExchangeRateRepository(modelContainer: container)

        let rates = [
            ExchangeRate(baseCurrency: .USD, targetCurrency: .VND, rate: 23000, date: Date()),
            ExchangeRate(baseCurrency: .USD, targetCurrency: .EUR, rate: 0.85, date: Date()),
            ExchangeRate(baseCurrency: .USD, targetCurrency: .JPY, rate: 110, date: Date()),
        ]

        try await repository.saveRates(rates)

        let usdToVnd = try await repository.fetchRate(from: .USD, to: .VND, date: nil)
        let usdToEur = try await repository.fetchRate(from: .USD, to: .EUR, date: nil)
        let usdToJpy = try await repository.fetchRate(from: .USD, to: .JPY, date: nil)

        #expect(usdToVnd?.rate == 23000)
        #expect(usdToEur?.rate == 0.85)
        #expect(usdToJpy?.rate == 110)
    }

    @Test("Update existing rate")
    func updateExistingRate() async throws {
        let container = try createTestContainer()
        let repository = ExchangeRateRepository(modelContainer: container)

        var rate = ExchangeRate(
            baseCurrency: .USD,
            targetCurrency: .VND,
            rate: 23000,
            date: Date(),
            source: "test"
        )

        try await repository.saveRates([rate])

        rate.rate = 24000
        rate.source = "updated"

        try await repository.saveRates([rate])
        let fetched = try await repository.fetchRate(from: .USD, to: .VND, date: nil)

        #expect(fetched?.rate == 24000)
        #expect(fetched?.source == "updated")
    }

    @Test("Fetch rate for specific date")
    func fetchRateForDate() async throws {
        let container = try createTestContainer()
        let repository = ExchangeRateRepository(modelContainer: container)

        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let todayRate = ExchangeRate(
            baseCurrency: .USD,
            targetCurrency: .VND,
            rate: 24000,
            date: today
        )

        let yesterdayRate = ExchangeRate(
            baseCurrency: .USD,
            targetCurrency: .VND,
            rate: 23000,
            date: yesterday
        )

        try await repository.saveRates([todayRate, yesterdayRate])

        let fetchedToday = try await repository.fetchRate(from: .USD, to: .VND, date: today)
        let fetchedYesterday = try await repository.fetchRate(from: .USD, to: .VND, date: yesterday)

        #expect(fetchedToday?.rate == 24000)
        #expect(fetchedYesterday?.rate == 23000)
    }

    @Test("Fetch rate falls back to most recent when exact date not found")
    func fetchRateFallbackToMostRecent() async throws {
        let container = try createTestContainer()
        let repository = ExchangeRateRepository(modelContainer: container)

        let calendar = Calendar.current
        let today = Date()
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let oldRate = ExchangeRate(
            baseCurrency: .USD,
            targetCurrency: .VND,
            rate: 23000,
            date: threeDaysAgo
        )

        try await repository.saveRates([oldRate])

        // Request for tomorrow (future date) should return the most recent available
        let fetched = try await repository.fetchRate(from: .USD, to: .VND, date: tomorrow)

        #expect(fetched != nil)
        #expect(fetched?.rate == 23000)
    }

    @Test("Delete old rates")
    func deleteOldRates() async throws {
        let container = try createTestContainer()
        let repository = ExchangeRateRepository(modelContainer: container)

        let calendar = Calendar.current
        let today = Date()
        let old = calendar.date(byAdding: .day, value: -100, to: today)!
        let recent = calendar.date(byAdding: .day, value: -10, to: today)!

        let oldRate = ExchangeRate(
            baseCurrency: .USD,
            targetCurrency: .VND,
            rate: 22000,
            date: old
        )

        let recentRate = ExchangeRate(
            baseCurrency: .USD,
            targetCurrency: .EUR,
            rate: 0.85,
            date: recent
        )

        try await repository.saveRates([oldRate, recentRate])

        // Delete rates older than 30 days
        let cutoffDate = calendar.date(byAdding: .day, value: -30, to: today)!
        try await repository.deleteOldRates(before: cutoffDate)

        let fetchedOld = try await repository.fetchRate(from: .USD, to: .VND, date: old)
        let fetchedRecent = try await repository.fetchRate(from: .USD, to: .EUR, date: recent)

        #expect(fetchedOld == nil)
        #expect(fetchedRecent != nil)
    }

    @Test("Different currency pairs are independent")
    func differentCurrencyPairs() async throws {
        let container = try createTestContainer()
        let repository = ExchangeRateRepository(modelContainer: container)

        let usdToVnd = ExchangeRate(
            baseCurrency: .USD,
            targetCurrency: .VND,
            rate: 23000,
            date: Date()
        )

        let vndToUsd = ExchangeRate(
            baseCurrency: .VND,
            targetCurrency: .USD,
            rate: Decimal(string: "0.000043")!,
            date: Date()
        )

        try await repository.saveRates([usdToVnd, vndToUsd])

        let fetched1 = try await repository.fetchRate(from: .USD, to: .VND, date: nil)
        let fetched2 = try await repository.fetchRate(from: .VND, to: .USD, date: nil)

        #expect(fetched1?.rate == 23000)
        #expect(fetched2?.rate == Decimal(string: "0.000043")!)
    }
}
