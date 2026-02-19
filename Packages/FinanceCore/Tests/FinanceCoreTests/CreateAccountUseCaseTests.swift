import Testing
import Foundation

@testable import FinanceCore

@Suite("CreateAccountUseCase Tests")
struct CreateAccountUseCaseTests {
    // MARK: - Test: Valid account creation succeeds

    @Test("Valid account creation succeeds")
    func validAccountCreation() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = CreateAccountUseCase(repository: repository)

        let account = Account(
            name: "Cash Wallet",
            type: .cash,
            currency: .VND,
            initialBalance: 100_000
        )

        // Act
        let createdAccount = try await useCase.execute(account)

        // Assert
        #expect(createdAccount.name == "Cash Wallet")
        #expect(createdAccount.type == .cash)
        #expect(createdAccount.balance == 100_000)
        #expect(createdAccount.initialBalance == 100_000)
        #expect(createdAccount.sortOrder == 0)
    }

    // MARK: - Test: Empty name throws error

    @Test("Empty name throws AccountError.nameEmpty")
    func emptyNameThrowsError() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = CreateAccountUseCase(repository: repository)

        let account = Account(name: "", type: .cash)

        // Act & Assert
        await #expect(throws: AccountError.nameEmpty) {
            try await useCase.execute(account)
        }
    }

    @Test("Whitespace-only name throws AccountError.nameEmpty")
    func whitespaceOnlyNameThrowsError() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = CreateAccountUseCase(repository: repository)

        let account = Account(name: "   ", type: .cash)

        // Act & Assert
        await #expect(throws: AccountError.nameEmpty) {
            try await useCase.execute(account)
        }
    }

    // MARK: - Test: Duplicate name throws error

    @Test("Duplicate name (case-insensitive) throws AccountError.nameAlreadyExists")
    func duplicateNameThrowsError() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = CreateAccountUseCase(repository: repository)

        let firstAccount = Account(name: "Cash Wallet", type: .cash)
        _ = try await useCase.execute(firstAccount)

        let duplicateAccount = Account(name: "cash wallet", type: .bank)

        // Act & Assert
        await #expect(throws: AccountError.self) {
            try await useCase.execute(duplicateAccount)
        }
    }

    @Test("Duplicate name with extra whitespace throws error")
    func duplicateNameWithWhitespaceThrowsError() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = CreateAccountUseCase(repository: repository)

        let firstAccount = Account(name: "Cash Wallet", type: .cash)
        _ = try await useCase.execute(firstAccount)

        let duplicateAccount = Account(name: "  Cash Wallet  ", type: .bank)

        // Act & Assert
        await #expect(throws: AccountError.self) {
            try await useCase.execute(duplicateAccount)
        }
    }

    // MARK: - Test: Free tier limit

    @Test("Free tier limit (5 accounts) throws AccountError.freeTierLimitReached")
    func freeTierLimitReached() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = CreateAccountUseCase(repository: repository, maxFreeAccounts: 5)

        // Create 5 accounts
        for i in 1...5 {
            let account = Account(name: "Account \(i)", type: .cash)
            _ = try await useCase.execute(account)
        }

        // Try to create the 6th account
        let sixthAccount = Account(name: "Account 6", type: .cash)

        // Act & Assert
        await #expect(throws: AccountError.freeTierLimitReached(maxAccounts: 5)) {
            try await useCase.execute(sixthAccount)
        }
    }

    @Test("Archived accounts don't count toward free tier limit")
    func archivedAccountsExcludedFromLimit() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = CreateAccountUseCase(repository: repository, maxFreeAccounts: 5)

        // Create 4 active accounts
        for i in 1...4 {
            let account = Account(name: "Account \(i)", type: .cash)
            _ = try await useCase.execute(account)
        }

        // Create 1 archived account (shouldn't count toward limit)
        let archivedAccount = Account(
            name: "Archived",
            type: .cash,
            isArchived: true
        )
        try await repository.save(archivedAccount)

        // Should be able to create one more active account
        let fifthAccount = Account(name: "Account 5", type: .cash)
        let created = try await useCase.execute(fifthAccount)

        // This should succeed - verify the account was created
        #expect(created.name == "Account 5")
    }

    // MARK: - Test: Auto-assign sortOrder

    @Test("Auto-assigns sortOrder based on existing account count")
    func autoAssignSortOrder() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = CreateAccountUseCase(repository: repository)

        // Act
        let first = try await useCase.execute(Account(name: "First", type: .cash))
        let second = try await useCase.execute(Account(name: "Second", type: .bank))
        let third = try await useCase.execute(Account(name: "Third", type: .creditCard))

        // Assert
        #expect(first.sortOrder == 0)
        #expect(second.sortOrder == 1)
        #expect(third.sortOrder == 2)
    }

    // MARK: - Test: Balance equals initialBalance

    @Test("Balance equals initialBalance on creation")
    func balanceEqualsInitialBalance() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = CreateAccountUseCase(repository: repository)

        let account = Account(
            name: "Savings",
            type: .savings,
            initialBalance: 5_000_000
        )

        // Act
        let createdAccount = try await useCase.execute(account)

        // Assert
        #expect(createdAccount.balance == createdAccount.initialBalance)
        #expect(createdAccount.balance == 5_000_000)
    }

    @Test("Zero initial balance is valid")
    func zeroInitialBalanceIsValid() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = CreateAccountUseCase(repository: repository)

        let account = Account(
            name: "Empty Wallet",
            type: .cash,
            initialBalance: 0
        )

        // Act
        let createdAccount = try await useCase.execute(account)

        // Assert
        #expect(createdAccount.balance == 0)
        #expect(createdAccount.initialBalance == 0)
    }

    @Test("Negative initial balance is valid (for loans)")
    func negativeInitialBalanceIsValid() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = CreateAccountUseCase(repository: repository)

        let account = Account(
            name: "Personal Loan",
            type: .loan,
            initialBalance: -10_000_000
        )

        // Act
        let createdAccount = try await useCase.execute(account)

        // Assert
        #expect(createdAccount.balance == -10_000_000)
        #expect(createdAccount.initialBalance == -10_000_000)
    }
}
