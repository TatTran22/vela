import Foundation

/// Represents a transaction category (2-level hierarchy).
///
/// Categories support localized names for multi-language display and
/// a parent-child hierarchy for subcategories.
public struct Category: Identifiable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    /// Localized display name for the current locale (e.g., "Ăn uống" / "Food & Dining").
    public var localizedName: String
    public var iconName: String
    public var colorHex: String
    public var type: TransactionType
    public var parentID: UUID?
    public var sortOrder: Int
    public var isDefault: Bool
    /// Whether this category is archived and hidden from the category picker.
    public var isArchived: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        localizedName: String = "",
        iconName: String = "folder",
        colorHex: String = "#007AFF",
        type: TransactionType,
        parentID: UUID? = nil,
        sortOrder: Int = 0,
        isDefault: Bool = false,
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.localizedName = localizedName.isEmpty ? name : localizedName
        self.iconName = iconName
        self.colorHex = colorHex
        self.type = type
        self.parentID = parentID
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.isArchived = isArchived
        self.createdAt = createdAt
    }
}
