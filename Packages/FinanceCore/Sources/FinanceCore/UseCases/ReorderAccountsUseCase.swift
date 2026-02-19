import Foundation

/// Protocol for reordering financial accounts.
///
/// This use case handles manual reordering of accounts for customized
/// display order in the user interface.
public protocol ReorderAccountsUseCaseProtocol: Sendable {
    /// Updates the sort order of multiple accounts based on their new positions.
    ///
    /// This method is typically called after a drag-and-drop reordering operation
    /// in the UI. The orderedIDs array represents the desired final order of accounts.
    /// Each account receives `sortOrder = offset + index`, where `index` is its
    /// position in the `orderedIDs` array. This allows callers to assign non-overlapping
    /// sort order ranges across different sections (e.g., by type).
    ///
    /// The operation is atomic - either all sort orders are updated successfully,
    /// or none are changed if an error occurs.
    ///
    /// - Parameters:
    ///   - orderedIDs: An array of account IDs in their desired display order.
    ///   - offset: The starting sort order value. Defaults to 0. The caller is
    ///             responsible for supplying the correct offset (e.g., the total
    ///             number of accounts in all preceding sections) to avoid collisions
    ///             when reordering within a single type section.
    /// - Throws: Repository errors if the update operation fails.
    func execute(orderedIDs: [UUID], startingAt offset: Int) async throws
}

/// Implementation of account reordering use case.
///
/// This use case maps array positions to sort order values (starting at the
/// provided offset) and delegates the atomic update to the repository.
public struct ReorderAccountsUseCase: ReorderAccountsUseCaseProtocol {
    private let repository: AccountRepositoryProtocol

    /// Creates a new account reordering use case.
    ///
    /// - Parameter repository: The repository for account persistence.
    public init(repository: AccountRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(orderedIDs: [UUID], startingAt offset: Int = 0) async throws {
        // Map orderedIDs to (UUID, Int) pairs where Int is (offset + index)
        let orders = orderedIDs.enumerated().map { (index, id) in
            (id, offset + index)
        }

        // Delegate to repository for atomic update
        try await repository.updateSortOrders(orders)
    }
}
