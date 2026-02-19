import Testing
import Foundation

@testable import FinanceCore

@Suite("DeleteAccountUseCase Tests")
struct DeleteAccountUseCaseTests {
    // MARK: - Test: Delete account without transactions succeeds

    @Test("Delete account without transactions succeeds (soft delete)")
    func deleteAccountWithoutTransactions() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = DeleteAccountUseCase(repository: repository)

        let account = Account(name: "Old Account", type: .cash)
        try await repository.save(account)

        // Act
        try await useCase.execute(accountID: account.id, hasTransactions: false)

        // Assert
        let deletedAccount = try await repository.fetch(by: account.id)
        #expect(deletedAccount != nil)
        #expect(deletedAccount?.deletedAt != nil)
    }

    // MARK: - Test: Delete account with transactions throws error

    @Test("Delete account with transactions throws AccountError.cannotDeleteAccountWithTransactions")
    func deleteAccountWithTransactionsThrowsError() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = DeleteAccountUseCase(repository: repository)

        let account = Account(name: "Active Account", type: .bank)
        try await repository.save(account)

        // Act & Assert
        await #expect(throws: AccountError.cannotDeleteAccountWithTransactions) {
            try await useCase.execute(accountID: account.id, hasTransactions: true)
        }
    }

    // MARK: - Test: Account not found throws error

    @Test("Account not found throws AccountError.accountNotFound")
    func accountNotFoundThrowsError() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = DeleteAccountUseCase(repository: repository)

        let nonExistentID = UUID()

        // Act & Assert
        await #expect(throws: AccountError.accountNotFound(nonExistentID)) {
            try await useCase.execute(accountID: nonExistentID, hasTransactions: false)
        }
    }

    // MARK: - Test: Soft delete preserves account data

    @Test("Soft delete preserves all account data")
    func softDeletePreservesData() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = DeleteAccountUseCase(repository: repository)

        let account = Account(
            name: "My Wallet",
            type: .cash,
            currency: .VND,
            initialBalance: 100_000,
            balance: 150_000,
            iconName: "wallet.pass",
            colorHex: "#FF0000",
            sortOrder: 5,
            note: "My personal wallet"
        )
        try await repository.save(account)

        // Act
        try await useCase.execute(accountID: account.id, hasTransactions: false)

        // Assert
        let deletedAccount = try await repository.fetch(by: account.id)
        #expect(deletedAccount?.name == "My Wallet")
        #expect(deletedAccount?.balance == 150_000)
        #expect(deletedAccount?.initialBalance == 100_000)
        #expect(deletedAccount?.note == "My personal wallet")
        #expect(deletedAccount?.deletedAt != nil)
    }

    // MARK: - Test: Deleted account updates timestamp

    @Test("Deleted account has updated timestamp")
    func deletedAccountUpdatesTimestamp() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = DeleteAccountUseCase(repository: repository)

        let pastDate = Date(timeIntervalSinceNow: -86400) // 1 day ago
        let account = Account(
            name: "Old Account",
            type: .cash,
            createdAt: pastDate,
            updatedAt: pastDate
        )
        try await repository.save(account)

        // Act
        try await useCase.execute(accountID: account.id, hasTransactions: false)

        // Assert
        let deletedAccount = try await repository.fetch(by: account.id)
        #expect(deletedAccount?.updatedAt != nil)
        #expect(deletedAccount!.updatedAt > pastDate)
    }
}
