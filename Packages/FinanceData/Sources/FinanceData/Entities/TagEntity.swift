import Foundation
import SwiftData

/// SwiftData entity for persisting Tag data.
///
/// Tags are lightweight user-defined labels applied to transactions for
/// cross-category grouping and filtering.
/// All properties use default values for CloudKit compatibility.
@Model
public final class TagEntity {
    public var id: UUID = UUID()
    public var name: String = ""
    /// Optional hex color code (e.g., "#FF3B30") for UI differentiation.
    public var color: String?
    public var createdAt: Date = Date()

    public init(
        id: UUID = UUID(),
        name: String = "",
        color: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = createdAt
    }
}
