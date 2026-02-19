import Foundation
import SwiftData

/// SwiftData entity for persisting Category data.
///
/// Categories support a two-level hierarchy (parent → children) and are
/// associated with a specific transaction type. All properties use default
/// values for CloudKit compatibility.
/// CloudKit does not support unique constraints, so `id` is a regular attribute.
@Model
public final class CategoryEntity {
    public var id: UUID = UUID()
    public var name: String = ""
    public var iconName: String = "folder"
    public var colorHex: String = "#007AFF"
    /// Raw value of `TransactionType` (e.g., "income", "expense", "transfer").
    public var typeRawValue: String = "expense"
    /// UUID of the parent category; nil for top-level categories.
    public var parentID: UUID?
    public var sortOrder: Int = 0
    public var isDefault: Bool = false
    public var createdAt: Date = Date()

    public init(
        id: UUID = UUID(),
        name: String = "",
        iconName: String = "folder",
        colorHex: String = "#007AFF",
        typeRawValue: String = "expense",
        parentID: UUID? = nil,
        sortOrder: Int = 0,
        isDefault: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.typeRawValue = typeRawValue
        self.parentID = parentID
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.createdAt = createdAt
    }
}
