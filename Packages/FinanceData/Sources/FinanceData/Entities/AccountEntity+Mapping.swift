import FinanceCore
import Foundation

extension AccountEntity {
    /// Converts this entity to a domain Account model.
    ///
    /// Maps all entity properties to their corresponding domain model equivalents,
    /// converting string-based enums back to their domain enum types.
    ///
    /// - Returns: A domain Account model representing this entity.
    func toDomain() -> Account {
        Account(
            id: id,
            name: name,
            type: AccountType(rawValue: type) ?? .other,
            currency: CurrencyCode(rawValue: currency) ?? .VND,
            initialBalance: initialBalance,
            balance: balance,
            iconName: iconName,
            colorHex: colorHex,
            sortOrder: sortOrder,
            isHidden: isHidden,
            isArchived: isArchived,
            note: note.isEmpty ? nil : note,
            eWalletProvider: eWalletProvider.isEmpty ? nil : EWalletProvider(rawValue: eWalletProvider),
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }

    /// Updates this entity from a domain Account model.
    ///
    /// Modifies the entity's properties to match the domain model.
    /// The `id` property is intentionally not updated as it should remain immutable.
    ///
    /// - Parameter domain: The domain Account model to update from.
    func update(from domain: Account) {
        name = domain.name
        type = domain.type.rawValue
        currency = domain.currency.rawValue
        initialBalance = domain.initialBalance
        balance = domain.balance
        iconName = domain.iconName
        colorHex = domain.colorHex
        sortOrder = domain.sortOrder
        isHidden = domain.isHidden
        isArchived = domain.isArchived
        note = domain.note ?? ""
        eWalletProvider = domain.eWalletProvider?.rawValue ?? ""
        updatedAt = domain.updatedAt
        deletedAt = domain.deletedAt
    }

    /// Creates a new entity from a domain Account model.
    ///
    /// Constructs a new entity instance with all properties populated from
    /// the domain model, converting domain enums to their string representations.
    ///
    /// - Parameter domain: The domain Account model to create from.
    /// - Returns: A new AccountEntity instance.
    static func from(domain: Account) -> AccountEntity {
        AccountEntity(
            id: domain.id,
            name: domain.name,
            type: domain.type.rawValue,
            currency: domain.currency.rawValue,
            initialBalance: domain.initialBalance,
            balance: domain.balance,
            iconName: domain.iconName,
            colorHex: domain.colorHex,
            sortOrder: domain.sortOrder,
            isHidden: domain.isHidden,
            isArchived: domain.isArchived,
            note: domain.note ?? "",
            eWalletProvider: domain.eWalletProvider?.rawValue ?? "",
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt,
            deletedAt: domain.deletedAt
        )
    }
}
