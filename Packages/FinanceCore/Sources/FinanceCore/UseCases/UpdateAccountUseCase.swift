import Foundation

/// Protocol for updating existing financial accounts.
///
/// This use case handles account updates with validation of business rules
/// including name uniqueness and currency change restrictions.
public protocol UpdateAccountUseCaseProtocol: Sendable {
    /// Updates an existing account after validating business rules.
    ///
    /// The account will be validated for:
    /// - Non-empty name
    /// - Name uniqueness (case-insensitive, excluding the account being updated)
    /// - Currency change restrictions (cannot change if account has transactions)
    ///
    /// - Parameters:
    ///   - account: The account to update with new values.
    ///   - hasTransactions: Whether the account has any existing transactions.
    /// - Returns: The updated account.
    /// - Throws: `AccountError.nameEmpty` if the name is empty,
    ///           `AccountError.nameAlreadyExists` if the name is already taken by another account,
    ///           `AccountError.cannotChangeCurrencyWithTransactions` if currency changed and account has transactions,
    ///           `AccountError.accountNotFound` if the account doesn't exist,
    ///           or repository errors for persistence failures.
    func execute(_ account: Account, hasTransactions: Bool) async throws -> Account
}

/// Implementation of account update use case.
///
/// This use case validates business rules before persisting account changes,
/// ensuring data integrity and preventing invalid currency changes.
public struct UpdateAccountUseCase: UpdateAccountUseCaseProtocol {
    private let repository: AccountRepositoryProtocol

    /// Creates a new account update use case.
    ///
    /// - Parameter repository: The repository for account persistence.
    public init(repository: AccountRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ account: Account, hasTransactions: Bool) async throws -> Account {
        // 1. Validate name not empty
        guard !account.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AccountError.nameEmpty
        }

        // 2. Fetch the original account to check for currency changes
        guard let originalAccount = try await repository.fetch(by: account.id) else {
            throw AccountError.accountNotFound(account.id)
        }

        // 3. Check if currency changed with existing transactions
        if hasTransactions && originalAccount.currency != account.currency {
            throw AccountError.cannotChangeCurrencyWithTransactions
        }

        // 4. Check name uniqueness (case-insensitive, excluding this account)
        let existingAccounts = try await repository.fetchAll()
        let trimmedName = account.name.trimmingCharacters(in: .whitespacesAndNewlines)

        // Filter out soft-deleted accounts and the current account being updated
        let otherAccounts = existingAccounts.filter {
            $0.deletedAt == nil && $0.id != account.id
        }

        if let existingAccount = otherAccounts.first(where: {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(trimmedName) == .orderedSame
        }) {
            throw AccountError.nameAlreadyExists(existingAccount.name)
        }

        // 5. Update the updatedAt timestamp
        var updatedAccount = account
        updatedAccount.updatedAt = Date()

        // 6. Save and return
        try await repository.save(updatedAccount)
        return updatedAccount
    }
}
