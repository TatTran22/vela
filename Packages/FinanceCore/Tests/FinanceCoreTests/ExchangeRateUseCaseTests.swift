import Testing
import Foundation

@testable import FinanceCore

@Suite("ExchangeRateUseCase Tests")
struct ExchangeRateUseCaseTests {
    // MARK: - Test: Conversion with known rate

    @Test("Conversion with known rate succeeds")
    func conversionWithKnownRate() async throws {
        // Arrange
        let repository = MockExchangeRateRepository()
        let service = MockExchangeRateService()
        let useCase = ExchangeRateUseCase(repository: repository, service: service)

        // Set up a cached rate
        let rate = ExchangeRate(
            baseCurrency: .USD,
            targetCurrency: .VND,
            rate: 25000,
            date: Date(),
            source: "test"
        )
        try await repository.saveRates([rate])

        // Act
        let converted = try await useCase.convert(amount: 100, from: .USD, to: .VND)

        // Assert
        #expect(converted == 2_500_000)
    }

    // MARK: - Test: Same currency returns amount unchanged

    @Test("Same currency returns amount unchanged")
    func sameCurrencyReturnsUnchanged() async throws {
        // Arrange
        let repository = MockExchangeRateRepository()
        let service = MockExchangeRateService()
        let useCase = ExchangeRateUseCase(repository: repository, service: service)

        // Act
        let converted = try await useCase.convert(amount: 1_000_000, from: .VND, to: .VND)

        // Assert
        #expect(converted == 1_000_000)
    }

    // MARK: - Test: Rate not found throws error

    @Test("Rate not found throws ExchangeRateError.rateNotFound")
    func rateNotFoundThrowsError() async throws {
        // Arrange
        let repository = MockExchangeRateRepository()
        let service = MockExchangeRateService()
        await service.reset()
        await service.setShouldThrowError(true)

        let useCase = ExchangeRateUseCase(repository: repository, service: service)

        // Act & Assert
        await #expect(throws: ExchangeRateError.self) {
            try await useCase.convert(amount: 100, from: .USD, to: .VND)
        }
    }

    // MARK: - Test: Fetch latest rates

    @Test("Fetch latest rates from service and cache them")
    func fetchLatestRatesFromService() async throws {
        // Arrange
        let repository = MockExchangeRateRepository()
        let service = MockExchangeRateService()
        let useCase = ExchangeRateUseCase(repository: repository, service: service)

        // Act
        let rates = try await useCase.fetchLatestRates(base: .USD)

        // Assert
        #expect(!rates.isEmpty)
        #expect(rates.allSatisfy { $0.baseCurrency == .USD })

        // Verify rates are cached
        let cachedRate = try await repository.fetchRate(from: .USD, to: .VND, date: nil)
        #expect(cachedRate != nil)
    }

    // MARK: - Test: Get rate for same currency

    @Test("Get rate for same currency returns 1.0")
    func getRateForSameCurrencyReturnsOne() async throws {
        // Arrange
        let repository = MockExchangeRateRepository()
        let service = MockExchangeRateService()
        let useCase = ExchangeRateUseCase(repository: repository, service: service)

        // Act
        let rate = try await useCase.getRate(from: .USD, to: .USD)

        // Assert
        #expect(rate == 1.0)
    }

    // MARK: - Test: Fresh cache is used

    @Test("Fresh cache (within expiry) is used without fetching")
    func freshCacheIsUsed() async throws {
        // Arrange
        let repository = MockExchangeRateRepository()
        let service = MockExchangeRateService()
        let useCase = ExchangeRateUseCase(
            repository: repository,
            service: service,
            cacheExpiryInterval: 3600 // 1 hour
        )

        // Set up a fresh cached rate (1 minute old)
        let freshDate = Date(timeIntervalSinceNow: -60)
        let cachedRate = ExchangeRate(
            baseCurrency: .USD,
            targetCurrency: .VND,
            rate: 25000,
            date: freshDate,
            source: "cache"
        )
        try await repository.saveRates([cachedRate])

        // Configure service to throw error (should not be called)
        await service.setShouldThrowError(true)

        // Act
        let rate = try await useCase.getRate(from: .USD, to: .VND)

        // Assert - should succeed using cache
        #expect(rate == 25000)
    }

    // MARK: - Test: Stale cache triggers refresh

    @Test("Stale cache triggers refresh and uses new rate")
    func staleCacheTriggersRefresh() async throws {
        // Arrange
        let repository = MockExchangeRateRepository()
        let service = MockExchangeRateService()
        let useCase = ExchangeRateUseCase(
            repository: repository,
            service: service,
            cacheExpiryInterval: 3600 // 1 hour
        )

        // Set up a stale cached rate (2 hours old)
        let staleDate = Date(timeIntervalSinceNow: -7200)
        let staleRate = ExchangeRate(
            baseCurrency: .USD,
            targetCurrency: .VND,
            rate: 24000, // Old rate
            date: staleDate,
            source: "stale-cache"
        )
        try await repository.saveRates([staleRate])

        // Service will return fresh rate
        let freshRate = ExchangeRate(
            baseCurrency: .USD,
            targetCurrency: .VND,
            rate: 25000, // New rate
            date: Date(),
            source: "fresh"
        )
        await service.setMockRates([freshRate])

        // Act
        let rate = try await useCase.getRate(from: .USD, to: .VND)

        // Assert - should use fresh rate
        #expect(rate == 25000)
    }

    // MARK: - Test: Offline fallback to stale cache

    @Test("Network error falls back to stale cache")
    func networkErrorFallsBackToStaleCache() async throws {
        // Arrange
        let repository = MockExchangeRateRepository()
        let service = MockExchangeRateService()
        let useCase = ExchangeRateUseCase(
            repository: repository,
            service: service,
            cacheExpiryInterval: 3600 // 1 hour
        )

        // Set up a stale cached rate
        let staleDate = Date(timeIntervalSinceNow: -7200)
        let staleRate = ExchangeRate(
            baseCurrency: .USD,
            targetCurrency: .VND,
            rate: 24000,
            date: staleDate,
            source: "stale-cache"
        )
        try await repository.saveRates([staleRate])

        // Service will throw network error
        await service.setShouldThrowError(true)

        // Act
        let rate = try await useCase.getRate(from: .USD, to: .VND)

        // Assert - should fall back to stale cache
        #expect(rate == 24000)
    }

    // MARK: - Test: No cache and network error

    @Test("No cache and network error throws ExchangeRateError.networkUnavailable")
    func noCacheAndNetworkErrorThrows() async throws {
        // Arrange
        let repository = MockExchangeRateRepository()
        let service = MockExchangeRateService()
        await service.setShouldThrowError(true)

        let useCase = ExchangeRateUseCase(repository: repository, service: service)

        // Act & Assert
        await #expect(throws: ExchangeRateError.networkUnavailable) {
            try await useCase.getRate(from: .USD, to: .VND)
        }
    }

    // MARK: - Test: Decimal precision

    @Test("Conversion maintains decimal precision")
    func conversionMaintainsPrecision() async throws {
        // Arrange
        let repository = MockExchangeRateRepository()
        let service = MockExchangeRateService()
        let useCase = ExchangeRateUseCase(repository: repository, service: service)

        // Set up a rate with decimal precision
        let rate = ExchangeRate(
            baseCurrency: .USD,
            targetCurrency: .EUR,
            rate: Decimal(string: "0.92")!,
            date: Date(),
            source: "test"
        )
        try await repository.saveRates([rate])

        // Act
        let converted = try await useCase.convert(amount: Decimal(string: "100.50")!, from: .USD, to: .EUR)

        // Assert
        let expected = Decimal(string: "92.46")!
        #expect(converted == expected) // 100.50 * 0.92
    }

    // MARK: - Test: Large amounts

    @Test("Conversion handles large amounts correctly")
    func conversionHandlesLargeAmounts() async throws {
        // Arrange
        let repository = MockExchangeRateRepository()
        let service = MockExchangeRateService()
        let useCase = ExchangeRateUseCase(repository: repository, service: service)

        let rate = ExchangeRate(
            baseCurrency: .USD,
            targetCurrency: .VND,
            rate: 25000,
            date: Date(),
            source: "test"
        )
        try await repository.saveRates([rate])

        // Act
        let converted = try await useCase.convert(amount: 1_000_000, from: .USD, to: .VND)

        // Assert
        #expect(converted == 25_000_000_000) // 1M USD * 25,000
    }
}

// MARK: - Helper Extensions for MockExchangeRateService

extension MockExchangeRateService {
    func setShouldThrowError(_ value: Bool) async {
        shouldThrowError = value
    }

    func setMockRates(_ rates: [ExchangeRate]) async {
        mockRates = rates
    }
}
