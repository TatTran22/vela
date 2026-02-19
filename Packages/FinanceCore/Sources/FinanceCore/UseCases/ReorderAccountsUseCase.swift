import Foundation

/// Protocol for reordering financial accounts.
///
/// This use case handles manual reordering of accounts for customized
/// display order in the user interface.
public protocol ReorderAccountsUseCaseProtocol: Sendable {
    /// Updates the sort order of multiple accounts based on their new positions.
    ///
    /// This method is typically called after a drag-and-drop reordering operation
    /// in the UI. The orderedIDs array represents the desired final order of accounts,
    /// where the first ID should have sortOrder 0, the second ID sortOrder 1, etc.
    ///
    /// The operation is atomic - either all sort orders are updated successfully,
    /// or none are changed if an error occurs.
    ///
    /// - Parameter orderedIDs: An array of account IDs in their desired display order.
    ///                        The index in this array determines the new sortOrder.
    /// - Throws: Repository errors if the update operation fails.
    func execute(orderedIDs: [UUID]) async throws
}

/// Implementation of account reordering use case.
///
/// This use case maps array positions to sort order values and
/// delegates the atomic update to the repository.
public struct ReorderAccountsUseCase: ReorderAccountsUseCaseProtocol {
    private let repository: AccountRepositoryProtocol

    /// Creates a new account reordering use case.
    ///
    /// - Parameter repository: The repository for account persistence.
    public init(repository: AccountRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(orderedIDs: [UUID]) async throws {
        // Map orderedIDs to (UUID, Int) pairs where Int is the new sortOrder
        let orders = orderedIDs.enumerated().map { (index, id) in
            (id, index)
        }

        // Delegate to repository for atomic update
        try await repository.updateSortOrders(orders)
    }
}
