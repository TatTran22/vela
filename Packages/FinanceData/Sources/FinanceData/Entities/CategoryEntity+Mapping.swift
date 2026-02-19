import FinanceCore
import Foundation

extension CategoryEntity {
    /// Converts this entity to a domain Category model.
    ///
    /// If `typeRawValue` does not match a known `TransactionType`, it defaults
    /// to `.expense` so that a corrupt row does not block the entire fetch.
    ///
    /// - Returns: A domain `FinanceCore.Category` representing this entity.
    func toDomain() -> FinanceCore.Category {
        FinanceCore.Category(
            id: id,
            name: name,
            iconName: iconName,
            colorHex: colorHex,
            type: TransactionType(rawValue: typeRawValue) ?? .expense,
            parentID: parentID,
            sortOrder: sortOrder,
            isDefault: isDefault,
            createdAt: createdAt
        )
    }

    /// Updates this entity's mutable properties from a domain Category model.
    ///
    /// The `id` and `createdAt` properties are intentionally left unchanged
    /// because they are immutable once a record is created.
    ///
    /// - Parameter domain: The domain `FinanceCore.Category` model to update from.
    func update(from domain: FinanceCore.Category) {
        name = domain.name
        iconName = domain.iconName
        colorHex = domain.colorHex
        typeRawValue = domain.type.rawValue
        parentID = domain.parentID
        sortOrder = domain.sortOrder
        isDefault = domain.isDefault
    }

    /// Creates a new entity from a domain Category model.
    ///
    /// - Parameter domain: The domain `FinanceCore.Category` model to create from.
    /// - Returns: A new `CategoryEntity` instance.
    static func from(domain: FinanceCore.Category) -> CategoryEntity {
        CategoryEntity(
            id: domain.id,
            name: domain.name,
            iconName: domain.iconName,
            colorHex: domain.colorHex,
            typeRawValue: domain.type.rawValue,
            parentID: domain.parentID,
            sortOrder: domain.sortOrder,
            isDefault: domain.isDefault,
            createdAt: domain.createdAt
        )
    }
}
