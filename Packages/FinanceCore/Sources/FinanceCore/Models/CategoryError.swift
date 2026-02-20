import Foundation

/// Errors that can occur during category operations.
///
/// These errors represent domain-level validation and business rule violations
/// related to category management.
public enum CategoryError: Error, Sendable, Equatable {
    /// The category name cannot be empty.
    case nameEmpty

    /// A category with the given name already exists within the same type and parent scope.
    case nameAlreadyExists(String)

    /// Cannot change the type of a category that has existing transactions.
    case cannotChangeTypeWithTransactions

    /// Cannot delete a category that has existing transactions.
    ///
    /// The associated value is an optional category ID to reassign transactions to
    /// before deletion. When nil, the caller must handle reassignment separately.
    case cannotDeleteCategoryWithTransactions(reassignTo: UUID?)

    /// System (default) categories cannot be permanently deleted.
    case cannotDeleteSystemCategory

    /// The category with the specified ID was not found.
    case categoryNotFound(UUID)

    /// The proposed parent assignment would create a circular reference in the hierarchy.
    case circularParentReference

    /// The parent category with the specified ID was not found.
    case parentCategoryNotFound(UUID)
}

extension CategoryError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .nameEmpty:
            return "Category name cannot be empty."
        case .nameAlreadyExists(let name):
            return "A category named \"\(name)\" already exists."
        case .cannotChangeTypeWithTransactions:
            return "Cannot change category type when transactions exist."
        case .cannotDeleteCategoryWithTransactions:
            return "Cannot delete a category with existing transactions. Reassign transactions first."
        case .cannotDeleteSystemCategory:
            return "System categories cannot be deleted."
        case .categoryNotFound(let id):
            return "Category with ID \(id) was not found."
        case .circularParentReference:
            return "A category cannot be its own ancestor."
        case .parentCategoryNotFound(let id):
            return "Parent category with ID \(id) was not found."
        }
    }
}
