import Foundation

/// A parent category together with its direct children.
///
/// Used by `GetCategoriesUseCaseProtocol.executeNested(type:includeArchived:)` to
/// represent a single level of the two-level category hierarchy in a flat,
/// list-friendly structure.
public struct CategoryGroup: Sendable, Identifiable {
    /// The parent category.
    public let parent: Category

    /// The direct children of `parent`, sorted by `sortOrder`.
    public let children: [Category]

    /// The unique identifier of the parent category.
    public var id: UUID { parent.id }

    /// Creates a new category group.
    ///
    /// - Parameters:
    ///   - parent: The parent category.
    ///   - children: The direct children of the parent.
    public init(parent: Category, children: [Category]) {
        self.parent = parent
        self.children = children
    }
}

/// Protocol for retrieving categories.
///
/// This use case provides flexible category querying, including flat lists,
/// type-grouped dictionaries, and nested parent-child structures.
public protocol GetCategoriesUseCaseProtocol: Sendable {
    /// Retrieves categories, optionally filtered by transaction type and archived status.
    ///
    /// Results are sorted by `sortOrder` ascending, then by `name`.
    ///
    /// - Parameters:
    ///   - type: When provided, only categories of that type are returned.
    ///           When nil, categories of all types are returned.
    ///   - includeArchived: Whether to include archived categories. Defaults to `false`.
    /// - Returns: An array of matching categories sorted by `sortOrder`.
    /// - Throws: Repository errors if the fetch operation fails.
    func execute(type: TransactionType?, includeArchived: Bool) async throws -> [Category]

    /// Retrieves all categories grouped by their transaction type.
    ///
    /// Each group is sorted by `sortOrder` within the type.
    ///
    /// - Parameter includeArchived: Whether to include archived categories.
    /// - Returns: A dictionary mapping each `TransactionType` to its sorted categories.
    /// - Throws: Repository errors if the fetch operation fails.
    func executeGrouped(includeArchived: Bool) async throws -> [TransactionType: [Category]]

    /// Retrieves top-level categories of a given type together with their children.
    ///
    /// Each `CategoryGroup` contains a parent and its direct children, both sorted
    /// by `sortOrder`. The groups themselves are sorted by their parent's `sortOrder`.
    ///
    /// - Parameters:
    ///   - type: The transaction type whose nested structure is requested.
    ///   - includeArchived: Whether to include archived categories. Defaults to `false`.
    /// - Returns: An array of `CategoryGroup` values sorted by parent `sortOrder`.
    /// - Throws: Repository errors if the fetch operation fails.
    func executeNested(type: TransactionType, includeArchived: Bool) async throws -> [CategoryGroup]
}

/// Implementation of category retrieval use case.
///
/// Provides flat, grouped, and nested category queries with optional
/// archived-category inclusion and consistent sort-order–based ordering.
public struct GetCategoriesUseCase: GetCategoriesUseCaseProtocol {
    private let repository: CategoryRepositoryProtocol

    /// Creates a new category retrieval use case.
    ///
    /// - Parameter repository: The repository for category persistence.
    public init(repository: CategoryRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(
        type: TransactionType?,
        includeArchived: Bool = false
    ) async throws -> [Category] {
        // Fetch from repository with optional type filter
        let all = try await repository.fetchAll(type: type)

        // Filter archived categories if not requested
        let filtered = includeArchived ? all : all.filter { !$0.isArchived }

        // Sort by sortOrder ascending, then by name for stable tie-breaking
        return filtered.sorted {
            if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
            return $0.name.localizedCompare($1.name) == .orderedAscending
        }
    }

    public func executeGrouped(
        includeArchived: Bool = false
    ) async throws -> [TransactionType: [Category]] {
        // Fetch all categories (no type filter)
        let all = try await execute(type: nil, includeArchived: includeArchived)

        // Group by type; each group is already sorted by the call above
        var grouped: [TransactionType: [Category]] = [:]
        for category in all {
            grouped[category.type, default: []].append(category)
        }

        return grouped
    }

    public func executeNested(
        type: TransactionType,
        includeArchived: Bool = false
    ) async throws -> [CategoryGroup] {
        // Fetch top-level (parentless) categories for the requested type
        var topLevel = try await repository.fetchTopLevel(type: type)
        if !includeArchived {
            topLevel = topLevel.filter { !$0.isArchived }
        }
        topLevel.sort {
            if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
            return $0.name.localizedCompare($1.name) == .orderedAscending
        }

        // For each top-level category, fetch and sort its children
        var groups: [CategoryGroup] = []
        for parent in topLevel {
            var children = try await repository.fetchChildren(of: parent.id)
            if !includeArchived {
                children = children.filter { !$0.isArchived }
            }
            children.sort {
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.name.localizedCompare($1.name) == .orderedAscending
            }
            groups.append(CategoryGroup(parent: parent, children: children))
        }

        return groups
    }
}
