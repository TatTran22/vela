import Foundation

/// Represents a user-defined label that can be applied to transactions for
/// cross-category grouping and filtering.
///
/// Tags complement categories by providing a flexible, many-to-many tagging
/// system. For example, a user can tag multiple transactions from different
/// categories with "business trip" and filter them together.
public struct Tag: Identifiable, Sendable, Hashable, Codable {
    /// Unique identifier for the tag.
    public let id: UUID

    /// The display name of the tag (e.g., "Business Trip", "Groceries").
    public var name: String

    /// Optional hex color code for visual differentiation in the UI (e.g., "#FF3B30").
    ///
    /// When nil, the UI should fall back to a default system color.
    public var color: String?

    /// Date when the tag was created.
    public var createdAt: Date

    /// Creates a new tag.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - name: Display name for the tag.
    ///   - color: Optional hex color code. Defaults to nil.
    ///   - createdAt: Record creation date. Defaults to now.
    public init(
        id: UUID = UUID(),
        name: String,
        color: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = createdAt
    }
}
