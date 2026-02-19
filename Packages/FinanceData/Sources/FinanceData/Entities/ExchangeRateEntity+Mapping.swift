import FinanceCore
import Foundation

extension ExchangeRateEntity {
    /// Converts this entity to a domain ExchangeRate model.
    ///
    /// Maps all entity properties to their corresponding domain model equivalents,
    /// converting string-based currency codes back to domain enum types.
    ///
    /// - Returns: A domain ExchangeRate model representing this entity.
    func toDomain() -> ExchangeRate {
        ExchangeRate(
            id: id,
            baseCurrency: CurrencyCode(rawValue: baseCurrency) ?? .VND,
            targetCurrency: CurrencyCode(rawValue: targetCurrency) ?? .USD,
            rate: rate,
            date: date,
            source: source
        )
    }

    /// Updates this entity from a domain ExchangeRate model.
    ///
    /// Modifies the entity's properties to match the domain model.
    /// The `id` property is intentionally not updated as it should remain immutable.
    ///
    /// - Parameter domain: The domain ExchangeRate model to update from.
    func update(from domain: ExchangeRate) {
        baseCurrency = domain.baseCurrency.rawValue
        targetCurrency = domain.targetCurrency.rawValue
        rate = domain.rate
        date = domain.date
        source = domain.source
    }

    /// Creates a new entity from a domain ExchangeRate model.
    ///
    /// Constructs a new entity instance with all properties populated from
    /// the domain model, converting domain enums to their string representations.
    ///
    /// - Parameter domain: The domain ExchangeRate model to create from.
    /// - Returns: A new ExchangeRateEntity instance.
    static func from(domain: ExchangeRate) -> ExchangeRateEntity {
        ExchangeRateEntity(
            id: domain.id,
            baseCurrency: domain.baseCurrency.rawValue,
            targetCurrency: domain.targetCurrency.rawValue,
            rate: domain.rate,
            date: domain.date,
            source: domain.source
        )
    }
}
