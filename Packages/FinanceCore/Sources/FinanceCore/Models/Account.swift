import Foundation

/// Represents a financial account (bank, cash, credit card, etc.)
public struct Account: Identifiable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var type: AccountType
    public var currency: String
    public var initialBalance: Decimal
    public var iconName: String
    public var colorHex: String
    public var isArchived: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        type: AccountType,
        currency: String = "VND",
        initialBalance: Decimal = 0,
        iconName: String = "banknote",
        colorHex: String = "#007AFF",
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.currency = currency
        self.initialBalance = initialBalance
        self.iconName = iconName
        self.colorHex = colorHex
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Types of financial accounts
public enum AccountType: String, Sendable, CaseIterable, Codable {
    case cash
    case bankAccount
    case creditCard
    case eWallet
    case savings
    case investment
    case other
}
