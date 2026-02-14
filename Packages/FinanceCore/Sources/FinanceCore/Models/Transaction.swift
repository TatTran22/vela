import Foundation

/// Represents a financial transaction
public struct Transaction: Identifiable, Sendable, Hashable {
    public let id: UUID
    public var amount: Decimal
    public var type: TransactionType
    public var categoryID: UUID?
    public var accountID: UUID
    public var toAccountID: UUID?
    public var note: String
    public var date: Date
    public var isRecurring: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        amount: Decimal,
        type: TransactionType,
        categoryID: UUID? = nil,
        accountID: UUID,
        toAccountID: UUID? = nil,
        note: String = "",
        date: Date = Date(),
        isRecurring: Bool = false,
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
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Types of financial transactions
public enum TransactionType: String, Sendable, CaseIterable, Codable {
    case income
    case expense
    case transfer
}
