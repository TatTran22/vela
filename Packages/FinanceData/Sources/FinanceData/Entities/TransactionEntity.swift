import Foundation
import SwiftData

/// SwiftData entity for persisting Transaction data.
///
/// All properties use default values for CloudKit compatibility.
/// CloudKit does not support unique constraints, so `id` is a regular attribute.
///
/// Complex types that SwiftData/CloudKit cannot natively store are serialised
/// as JSON strings:
/// - `tags` holds a JSON-encoded `[UUID]` array.
/// - `metadata` holds a JSON-encoded `[String: String]` dictionary.
@Model
public final class TransactionEntity {
    public var id: UUID = UUID()
    public var amount: Decimal = 0
    /// Raw value of `TransactionType` (e.g., "income", "expense", "transfer").
    public var type: String = "expense"
    public var categoryID: UUID = UUID()
    public var accountID: UUID = UUID()
    public var toAccountID: UUID?
    public var note: String = ""
    public var date: Date = Date()
    public var isRecurring: Bool = false
    /// JSON-encoded `[UUID]` array stored as a plain string for CloudKit compatibility.
    public var tags: String = ""
    public var latitude: Double?
    public var longitude: Double?
    /// JSON-encoded `[String: String]` dictionary stored as a plain string for CloudKit compatibility.
    public var metadata: String = ""
    public var deletedAt: Date?
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()

    public init(
        id: UUID = UUID(),
        amount: Decimal = 0,
        type: String = "expense",
        categoryID: UUID = UUID(),
        accountID: UUID = UUID(),
        toAccountID: UUID? = nil,
        note: String = "",
        date: Date = Date(),
        isRecurring: Bool = false,
        tags: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        metadata: String = "",
        deletedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.categoryID = categoryID
        self.accountID = accountID
        self.toAccountID = toAccountID
        self.note = note
        self.date = date
        self.isRecurring = isRecurring
        self.tags = tags
        self.latitude = latitude
        self.longitude = longitude
        self.metadata = metadata
        self.deletedAt = deletedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
