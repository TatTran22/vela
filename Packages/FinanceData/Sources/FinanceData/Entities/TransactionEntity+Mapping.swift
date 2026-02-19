import FinanceCore
import Foundation

extension TransactionEntity {
    /// Converts this entity to a domain Transaction model.
    ///
    /// Decodes the JSON-encoded `tags` and `metadata` strings back to their
    /// original Swift types. Invalid JSON produces empty/nil values rather than
    /// a hard failure so that a single corrupt row does not block the entire fetch.
    ///
    /// - Returns: A domain `Transaction` representing this entity.
    func toDomain() -> Transaction {
        Transaction(
            id: id,
            amount: amount,
            type: TransactionType(rawValue: type) ?? .expense,
            categoryID: categoryID,
            accountID: accountID,
            toAccountID: toAccountID,
            note: note,
            date: date,
            isRecurring: isRecurring,
            tags: Self.decodeTags(from: tags),
            latitude: latitude,
            longitude: longitude,
            metadata: Self.decodeMetadata(from: metadata),
            deletedAt: deletedAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Updates this entity's mutable properties from a domain Transaction model.
    ///
    /// The `id` and `createdAt` properties are intentionally left unchanged
    /// because they are immutable once a record is created.
    ///
    /// - Parameter domain: The domain `Transaction` model to update from.
    func update(from domain: Transaction) {
        amount = domain.amount
        type = domain.type.rawValue
        categoryID = domain.categoryID
        accountID = domain.accountID
        toAccountID = domain.toAccountID
        note = domain.note
        date = domain.date
        isRecurring = domain.isRecurring
        tags = Self.encodeTags(domain.tags)
        latitude = domain.latitude
        longitude = domain.longitude
        metadata = Self.encodeMetadata(domain.metadata)
        deletedAt = domain.deletedAt
        updatedAt = domain.updatedAt
    }

    /// Creates a new entity from a domain Transaction model.
    ///
    /// Encodes complex Swift types (`[UUID]` tags, `[String: String]` metadata)
    /// to their JSON string representations for CloudKit-compatible storage.
    ///
    /// - Parameter domain: The domain `Transaction` model to create from.
    /// - Returns: A new `TransactionEntity` instance.
    static func from(domain: Transaction) -> TransactionEntity {
        TransactionEntity(
            id: domain.id,
            amount: domain.amount,
            type: domain.type.rawValue,
            categoryID: domain.categoryID,
            accountID: domain.accountID,
            toAccountID: domain.toAccountID,
            note: domain.note,
            date: domain.date,
            isRecurring: domain.isRecurring,
            tags: encodeTags(domain.tags),
            latitude: domain.latitude,
            longitude: domain.longitude,
            metadata: encodeMetadata(domain.metadata),
            deletedAt: domain.deletedAt,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt
        )
    }
}

// MARK: - JSON Helpers

private extension TransactionEntity {
    /// Encodes a `[UUID]` array to a JSON string.
    ///
    /// - Parameter uuids: The array of tag UUIDs to encode.
    /// - Returns: A JSON string representation, or an empty string on failure.
    static func encodeTags(_ uuids: [UUID]) -> String {
        guard !uuids.isEmpty else { return "" }
        let strings = uuids.map { $0.uuidString }
        guard let data = try? JSONEncoder().encode(strings),
              let json = String(data: data, encoding: .utf8)
        else { return "" }
        return json
    }

    /// Decodes a JSON string back to a `[UUID]` array.
    ///
    /// - Parameter json: The JSON string to decode.
    /// - Returns: An array of UUIDs, or an empty array if decoding fails.
    static func decodeTags(from json: String) -> [UUID] {
        guard !json.isEmpty,
              let data = json.data(using: .utf8),
              let strings = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return strings.compactMap { UUID(uuidString: $0) }
    }

    /// Encodes an optional `[String: String]` dictionary to a JSON string.
    ///
    /// - Parameter dict: The metadata dictionary to encode.
    /// - Returns: A JSON string representation, or an empty string if nil or on failure.
    static func encodeMetadata(_ dict: [String: String]?) -> String {
        guard let dict, !dict.isEmpty else { return "" }
        guard let data = try? JSONEncoder().encode(dict),
              let json = String(data: data, encoding: .utf8)
        else { return "" }
        return json
    }

    /// Decodes a JSON string back to an optional `[String: String]` dictionary.
    ///
    /// - Parameter json: The JSON string to decode.
    /// - Returns: A dictionary if the string is non-empty and valid JSON, nil otherwise.
    static func decodeMetadata(from json: String) -> [String: String]? {
        guard !json.isEmpty,
              let data = json.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return nil }
        return dict.isEmpty ? nil : dict
    }
}
