import Foundation
import SwiftData

/// SwiftData entity for persisting Account data
///
/// All properties use default values for CloudKit compatibility.
/// CloudKit does not support unique constraints, so `id` is a regular attribute.
@Model
public final class AccountEntity {
    public var id: UUID = UUID()
    public var name: String = ""
    public var type: String = "cash"
    public var currency: String = "VND"
    public var initialBalance: Decimal = 0
    public var balance: Decimal = 0
    public var iconName: String = "banknote"
    public var colorHex: String = "#007AFF"
    public var sortOrder: Int = 0
    public var isHidden: Bool = false
    public var isArchived: Bool = false
    public var note: String = ""
    public var eWalletProvider: String = ""
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()
    public var deletedAt: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        type: String,
        currency: String = "VND",
        initialBalance: Decimal = 0,
        balance: Decimal = 0,
        iconName: String = "banknote",
        colorHex: String = "#007AFF",
        sortOrder: Int = 0,
        isHidden: Bool = false,
        isArchived: Bool = false,
        note: String = "",
        eWalletProvider: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.currency = currency
        self.initialBalance = initialBalance
        self.balance = balance
        self.iconName = iconName
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isHidden = isHidden
        self.isArchived = isArchived
        self.note = note
        self.eWalletProvider = eWalletProvider
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
