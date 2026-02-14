import Foundation

/// Represents a transaction category (2-level hierarchy)
public struct Category: Identifiable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var iconName: String
    public var colorHex: String
    public var type: TransactionType
    public var parentID: UUID?
    public var sortOrder: Int
    public var isDefault: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "folder",
        colorHex: String = "#007AFF",
        type: TransactionType,
        parentID: UUID? = nil,
        sortOrder: Int = 0,
        isDefault: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.type = type
        self.parentID = parentID
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.createdAt = createdAt
    }
}
