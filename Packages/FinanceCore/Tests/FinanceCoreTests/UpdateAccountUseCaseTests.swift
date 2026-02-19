import Testing
import Foundation

@testable import FinanceCore

@Suite("UpdateAccountUseCase Tests")
struct UpdateAccountUseCaseTests {
    // MARK: - Test: Valid update succeeds

    @Test("Valid update succeeds")
    func validUpdate() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = UpdateAccountUseCase(repository: repository)

        var account = Account(name: "Old Name", type: .cash)
        try await repository.save(account)

        // Act
        account.name = "New Name"
        account.iconName = "star.fill"
        account.colorHex = "#00FF00"

        let updatedAccount = try await useCase.execute(account, hasTransactions: false)

        // Assert
        #expect(updatedAccount.name == "New Name")
        #expect(updatedAccount.iconName == "star.fill")
        #expect(updatedAccount.colorHex == "#00FF00")
    }

    // MARK: - Test: Empty name throws error

    @Test("Empty name throws AccountError.nameEmpty")
    func emptyNameThrowsError() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = UpdateAccountUseCase(repository: repository)

        var account = Account(name: "Valid Name", type: .cash)
        try await repository.save(account)

        // Act
        account.name = ""

        // Assert
        await #expect(throws: AccountError.nameEmpty) {
            try await useCase.execute(account, hasTransactions: false)
        }
    }

    @Test("Whitespace-only name throws error")
    func whitespaceOnlyNameThrowsError() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = UpdateAccountUseCase(repository: repository)

        var account = Account(name: "Valid Name", type: .cash)
        try await repository.save(account)

        // Act
        account.name = "   "

        // Assert
        await #expect(throws: AccountError.nameEmpty) {
            try await useCase.execute(account, hasTransactions: false)
        }
    }

    // MARK: - Test: Currency change with transactions

    @Test("Currency change with transactions throws AccountError.cannotChangeCurrencyWithTransactions")
    func currencyChangeWithTransactionsThrowsError() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = UpdateAccountUseCase(repository: repository)

        var account = Account(name: "Bank Account", type: .bank, currency: .VND)
        try await repository.save(account)

        // Act
        account.currency = .USD

        // Assert
        await #expect(throws: AccountError.cannotChangeCurrencyWithTransactions) {
            try await useCase.execute(account, hasTransactions: true)
        }
    }

    // MARK: - Test: Currency change without transactions succeeds

    @Test("Currency change without transactions succeeds")
    func currencyChangeWithoutTransactionsSucceeds() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = UpdateAccountUseCase(repository: repository)

        var account = Account(name: "Bank Account", type: .bank, currency: .VND)
        try await repository.save(account)

        // Act
        account.currency = .USD

        let updatedAccount = try await useCase.execute(account, hasTransactions: false)

        // Assert
        #expect(updatedAccount.currency == .USD)
    }

    // MARK: - Test: Duplicate name validation

    @Test("Duplicate name (case-insensitive) throws error")
    func duplicateNameThrowsError() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = UpdateAccountUseCase(repository: repository)

        let existingAccount = Account(name: "Existing Account", type: .cash)
        try await repository.save(existingAccount)

        var accountToUpdate = Account(name: "Account To Update", type: .bank)
        try await repository.save(accountToUpdate)

        // Act
        accountToUpdate.name = "existing account"

        // Assert
        await #expect(throws: AccountError.self) {
            try await useCase.execute(accountToUpdate, hasTransactions: false)
        }
    }

    @Test("Renaming to same name (case-insensitive) succeeds")
    func renamingToSameNameSucceeds() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = UpdateAccountUseCase(repository: repository)

        var account = Account(name: "My Account", type: .cash)
        try await repository.save(account)

        // Act - change case but same name
        account.name = "MY ACCOUNT"

        let updatedAccount = try await useCase.execute(account, hasTransactions: false)

        // Assert
        #expect(updatedAccount.name == "MY ACCOUNT")
    }

    // MARK: - Test: Account not found

    @Test("Account not found throws AccountError.accountNotFound")
    func accountNotFoundThrowsError() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = UpdateAccountUseCase(repository: repository)

        let nonExistentAccount = Account(name: "Non-existent", type: .cash)

        // Act & Assert
        await #expect(throws: AccountError.accountNotFound(nonExistentAccount.id)) {
            try await useCase.execute(nonExistentAccount, hasTransactions: false)
        }
    }

    // MARK: - Test: Updated timestamp

    @Test("Update sets updatedAt timestamp")
    func updateSetsTimestamp() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = UpdateAccountUseCase(repository: repository)

        let pastDate = Date(timeIntervalSinceNow: -86400) // 1 day ago
        var account = Account(
            name: "Old Account",
            type: .cash,
            createdAt: pastDate,
            updatedAt: pastDate
        )
        try await repository.save(account)

        // Act
        account.name = "Updated Account"
        let updatedAccount = try await useCase.execute(account, hasTransactions: false)

        // Assert
        #expect(updatedAccount.updatedAt > pastDate)
    }

    // MARK: - Test: Soft-deleted accounts excluded from name check

    @Test("Soft-deleted accounts excluded from duplicate name check")
    func softDeletedAccountsExcludedFromNameCheck() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = UpdateAccountUseCase(repository: repository)

        // Create and soft-delete an account
        var deletedAccount = Account(name: "Deleted Account", type: .cash)
        deletedAccount.deletedAt = Date()
        try await repository.save(deletedAccount)

        // Create another account and try to rename it to the deleted account's name
        var accountToUpdate = Account(name: "Active Account", type: .bank)
        try await repository.save(accountToUpdate)

        // Act - should succeed because deleted accounts are excluded
        accountToUpdate.name = "Deleted Account"
        let updatedAccount = try await useCase.execute(accountToUpdate, hasTransactions: false)

        // Assert
        #expect(updatedAccount.name == "Deleted Account")
    }
}
