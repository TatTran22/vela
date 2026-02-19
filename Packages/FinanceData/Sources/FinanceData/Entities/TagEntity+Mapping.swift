import FinanceCore
import Foundation

extension TagEntity {
    /// Converts this entity to a domain Tag model.
    ///
    /// - Returns: A domain `Tag` representing this entity.
    func toDomain() -> Tag {
        Tag(
            id: id,
            name: name,
            color: color,
            createdAt: createdAt
        )
    }

    /// Updates this entity's mutable properties from a domain Tag model.
    ///
    /// The `id` property is intentionally left unchanged because it is immutable
    /// once a record is created.
    ///
    /// - Parameter domain: The domain `Tag` model to update from.
    func update(from domain: Tag) {
        name = domain.name
        color = domain.color
    }

    /// Creates a new entity from a domain Tag model.
    ///
    /// - Parameter domain: The domain `Tag` model to create from.
    /// - Returns: A new `TagEntity` instance.
    static func from(domain: Tag) -> TagEntity {
        TagEntity(
            id: domain.id,
            name: domain.name,
            color: domain.color,
            createdAt: domain.createdAt
        )
    }
}
