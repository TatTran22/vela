import FinanceCore
import Foundation
import SwiftData

/// SwiftData-backed repository for ExchangeRate entities.
///
/// This actor provides thread-safe access to exchange rate data using SwiftData's
/// `@ModelActor` macro. Exchange rates are cached locally for offline access and
/// to reduce API calls to external rate providers.
@ModelActor
public actor ExchangeRateRepository: ExchangeRateRepositoryProtocol {
    // The @ModelActor macro automatically provides:
    // - modelContainer: ModelContainer
    // - modelExecutor: ModelExecutor
    // - init(modelContainer: ModelContainer)

    public func fetchRate(
        from: CurrencyCode,
        to: CurrencyCode,
        date: Date?
    ) async throws -> ExchangeRate? {
        let targetDate = date ?? Date()

        var descriptor = FetchDescriptor<ExchangeRateEntity>()
        descriptor.predicate = #Predicate<ExchangeRateEntity> { entity in
            entity.baseCurrency == from.rawValue &&
            entity.targetCurrency == to.rawValue
        }
        descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]

        let entities = try modelContext.fetch(descriptor)

        // Find the rate with the date closest to (but not after) the target date
        if let exactMatch = entities.first(where: { Calendar.current.isDate($0.date, inSameDayAs: targetDate) }) {
            return exactMatch.toDomain()
        }

        // Fall back to the most recent rate available
        return entities.first?.toDomain()
    }

    public func saveRates(_ rates: [ExchangeRate]) async throws {
        for rate in rates {
            // Try to find existing rate for the same currency pair on the same day
            let baseCurrency = rate.baseCurrency.rawValue
            let targetCurrency = rate.targetCurrency.rawValue
            var descriptor = FetchDescriptor<ExchangeRateEntity>()
            descriptor.predicate = #Predicate<ExchangeRateEntity> { entity in
                entity.baseCurrency == baseCurrency &&
                entity.targetCurrency == targetCurrency
            }

            let existingEntities = try modelContext.fetch(descriptor)
            let sameDayEntity = existingEntities.first { entity in
                Calendar.current.isDate(entity.date, inSameDayAs: rate.date)
            }

            if let existing = sameDayEntity {
                existing.update(from: rate)
            } else {
                let entity = ExchangeRateEntity.from(domain: rate)
                modelContext.insert(entity)
            }
        }

        try modelContext.save()
    }

    public func deleteOldRates(before date: Date) async throws {
        var descriptor = FetchDescriptor<ExchangeRateEntity>()
        descriptor.predicate = #Predicate<ExchangeRateEntity> { entity in
            entity.date < date
        }

        let oldEntities = try modelContext.fetch(descriptor)

        for entity in oldEntities {
            modelContext.delete(entity)
        }

        try modelContext.save()
    }
}
