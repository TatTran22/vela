import Foundation

/// Protocol for deleting financial accounts.
///
/// This use case handles account deletion with validation to prevent
/// deletion of accounts that have associated transactions.
public protocol DeleteAccountUseCaseProtocol: Sendable {
    /// Soft-deletes an account after validating business rules.
    ///
    /// This performs a soft delete by setting the `deletedAt` timestamp,
    /// preserving the account data for historical purposes.
    ///
    /// The account cannot be deleted if it has existing transactions.
    /// In such cases, the user should either:
    /// - Delete all transactions first, or
    /// - Archive the account instead using the update use case
    ///
    /// - Parameters:
    ///   - accountID: The unique identifier of the account to delete.
    ///   - hasTransactions: Whether the account has any existing transactions.
    /// - Throws: `AccountError.cannotDeleteAccountWithTransactions` if the account has transactions,
    ///           `AccountError.accountNotFound` if the account doesn't exist,
    ///           or repository errors for persistence failures.
    func execute(accountID: UUID, hasTransactions: Bool) async throws
}

/// Implementation of account deletion use case.
///
/// This use case validates business rules before soft-deleting an account,
/// ensuring transaction data integrity is preserved.
public struct DeleteAccountUseCase: DeleteAccountUseCaseProtocol {
    private let repository: AccountRepositoryProtocol

    /// Creates a new account deletion use case.
    ///
    /// - Parameter repository: The repository for account persistence.
    public init(repository: AccountRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(accountID: UUID, hasTransactions: Bool) async throws {
        // 1. Check if account has transactions
        if hasTransactions {
            throw AccountError.cannotDeleteAccountWithTransactions
        }

        // 2. Fetch the account
        guard var account = try await repository.fetch(by: accountID) else {
            throw AccountError.accountNotFound(accountID)
        }

        // 3. Soft delete: set deletedAt timestamp
        account.deletedAt = Date()
        account.updatedAt = Date()

        // 4. Save the soft-deleted account
        try await repository.save(account)
    }
}
