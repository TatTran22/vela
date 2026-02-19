import Foundation

/// Protocol for creating new financial accounts.
///
/// This use case handles account creation with validation of business rules
/// including name uniqueness, free tier limits, and proper initialization.
public protocol CreateAccountUseCaseProtocol: Sendable {
    /// Creates a new account after validating business rules.
    ///
    /// The account will be validated for:
    /// - Non-empty name
    /// - Name uniqueness (case-insensitive)
    /// - Free tier account limit (if applicable)
    ///
    /// The account's balance is automatically set to match initialBalance,
    /// and sortOrder is assigned as max existing sortOrder + 1.
    ///
    /// - Parameter account: The account to create.
    /// - Returns: The created account with assigned sortOrder and balance.
    /// - Throws: `AccountError.nameEmpty` if the name is empty,
    ///           `AccountError.nameAlreadyExists` if the name is already taken,
    ///           `AccountError.freeTierLimitReached` if the account limit is exceeded,
    ///           or repository errors for persistence failures.
    func execute(_ account: Account) async throws -> Account
}

/// Implementation of account creation use case.
///
/// This use case validates business rules before persisting a new account,
/// ensuring data integrity and enforcing free tier limitations.
public struct CreateAccountUseCase: CreateAccountUseCaseProtocol {
    private let repository: AccountRepositoryProtocol
    private let maxFreeAccounts: Int

    /// Creates a new account creation use case.
    ///
    /// - Parameters:
    ///   - repository: The repository for account persistence.
    ///   - maxFreeAccounts: Maximum number of accounts allowed in free tier. Defaults to 5.
    public init(repository: AccountRepositoryProtocol, maxFreeAccounts: Int = 5) {
        self.repository = repository
        self.maxFreeAccounts = maxFreeAccounts
    }

    public func execute(_ account: Account) async throws -> Account {
        // 1. Validate name not empty
        guard !account.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AccountError.nameEmpty
        }

        // 2. Check name uniqueness (case-insensitive)
        let existingAccounts = try await repository.fetchAll()
        let trimmedName = account.name.trimmingCharacters(in: .whitespacesAndNewlines)

        // Filter out soft-deleted accounts for name checking
        let activeAccounts = existingAccounts.filter { $0.deletedAt == nil }

        if let existingAccount = activeAccounts.first(where: {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(trimmedName) == .orderedSame
        }) {
            throw AccountError.nameAlreadyExists(existingAccount.name)
        }

        // 3. Check free tier limit (only count active, non-archived, non-deleted accounts)
        let activeCount = activeAccounts.filter { !$0.isArchived }.count
        if activeCount >= maxFreeAccounts {
            throw AccountError.freeTierLimitReached(maxAccounts: maxFreeAccounts)
        }

        // 4. Auto-assign sortOrder = current max + 1
        let maxSortOrder = existingAccounts.map(\.sortOrder).max() ?? -1
        let newSortOrder = maxSortOrder + 1

        // 5. Set balance = initialBalance and assign sortOrder
        var newAccount = account
        newAccount.balance = account.initialBalance
        newAccount.sortOrder = newSortOrder
        newAccount.updatedAt = Date()

        // 6. Save and return the created account
        try await repository.save(newAccount)
        return newAccount
    }
}
