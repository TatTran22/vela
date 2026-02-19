import Testing
import Foundation

@testable import FinanceCore

@Suite("GetAccountsUseCase Tests")
struct GetAccountsUseCaseTests {
    // MARK: - Test: Fetch all accounts

    @Test("Fetch all accounts returns non-deleted accounts")
    func fetchAllAccounts() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = GetAccountsUseCase(repository: repository)

        let account1 = Account(name: "Cash", type: .cash)
        let account2 = Account(name: "Bank", type: .bank)
        let account3 = Account(name: "Credit Card", type: .creditCard)

        try await repository.save(account1)
        try await repository.save(account2)
        try await repository.save(account3)

        // Act
        let accounts = try await useCase.execute(filter: .default)

        // Assert
        #expect(accounts.count == 3)
        #expect(accounts.contains { $0.name == "Cash" })
        #expect(accounts.contains { $0.name == "Bank" })
        #expect(accounts.contains { $0.name == "Credit Card" })
    }

    // MARK: - Test: Filter excludes archived accounts

    @Test("Filter excludes archived accounts by default")
    func filterExcludesArchivedAccounts() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = GetAccountsUseCase(repository: repository)

        let activeAccount = Account(name: "Active", type: .cash, isArchived: false)
        let archivedAccount = Account(name: "Archived", type: .bank, isArchived: true)

        try await repository.save(activeAccount)
        try await repository.save(archivedAccount)

        // Act
        let accounts = try await useCase.execute(filter: .default)

        // Assert
        #expect(accounts.count == 1)
        #expect(accounts.first?.name == "Active")
    }

    @Test("Filter includes archived accounts when specified")
    func filterIncludesArchivedAccounts() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = GetAccountsUseCase(repository: repository)

        let activeAccount = Account(name: "Active", type: .cash, isArchived: false)
        let archivedAccount = Account(name: "Archived", type: .bank, isArchived: true)

        try await repository.save(activeAccount)
        try await repository.save(archivedAccount)

        // Act
        let filter = AccountFilter(includeArchived: true)
        let accounts = try await useCase.execute(filter: filter)

        // Assert
        #expect(accounts.count == 2)
        #expect(accounts.contains { $0.name == "Active" })
        #expect(accounts.contains { $0.name == "Archived" })
    }

    // MARK: - Test: Filter excludes hidden accounts

    @Test("Filter excludes hidden accounts by default")
    func filterExcludesHiddenAccounts() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = GetAccountsUseCase(repository: repository)

        let visibleAccount = Account(name: "Visible", type: .cash, isHidden: false)
        let hiddenAccount = Account(name: "Hidden", type: .bank, isHidden: true)

        try await repository.save(visibleAccount)
        try await repository.save(hiddenAccount)

        // Act
        let accounts = try await useCase.execute(filter: .default)

        // Assert
        #expect(accounts.count == 1)
        #expect(accounts.first?.name == "Visible")
    }

    @Test("Filter includes hidden accounts when specified")
    func filterIncludesHiddenAccounts() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = GetAccountsUseCase(repository: repository)

        let visibleAccount = Account(name: "Visible", type: .cash, isHidden: false)
        let hiddenAccount = Account(name: "Hidden", type: .bank, isHidden: true)

        try await repository.save(visibleAccount)
        try await repository.save(hiddenAccount)

        // Act
        let filter = AccountFilter(includeHidden: true)
        let accounts = try await useCase.execute(filter: filter)

        // Assert
        #expect(accounts.count == 2)
        #expect(accounts.contains { $0.name == "Visible" })
        #expect(accounts.contains { $0.name == "Hidden" })
    }

    // MARK: - Test: Filter by account type

    @Test("Filter by specific account types")
    func filterByAccountTypes() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = GetAccountsUseCase(repository: repository)

        try await repository.save(Account(name: "Cash", type: .cash))
        try await repository.save(Account(name: "Bank", type: .bank))
        try await repository.save(Account(name: "Credit Card", type: .creditCard))
        try await repository.save(Account(name: "E-Wallet", type: .eWallet))

        // Act
        let filter = AccountFilter(types: [.cash, .bank])
        let accounts = try await useCase.execute(filter: filter)

        // Assert
        #expect(accounts.count == 2)
        #expect(accounts.contains { $0.type == .cash })
        #expect(accounts.contains { $0.type == .bank })
        #expect(!accounts.contains { $0.type == .creditCard })
        #expect(!accounts.contains { $0.type == .eWallet })
    }

    // MARK: - Test: Soft-deleted accounts excluded

    @Test("Soft-deleted accounts are always excluded")
    func softDeletedAccountsExcluded() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = GetAccountsUseCase(repository: repository)

        let activeAccount = Account(name: "Active", type: .cash)
        var deletedAccount = Account(name: "Deleted", type: .bank)
        deletedAccount.deletedAt = Date()

        try await repository.save(activeAccount)
        try await repository.save(deletedAccount)

        // Act
        let accounts = try await useCase.execute(filter: .default)

        // Assert
        #expect(accounts.count == 1)
        #expect(accounts.first?.name == "Active")
    }

    // MARK: - Test: Accounts sorted by sortOrder

    @Test("Accounts are sorted by sortOrder")
    func accountsSortedBySortOrder() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = GetAccountsUseCase(repository: repository)

        let account1 = Account(name: "Third", type: .cash, sortOrder: 2)
        let account2 = Account(name: "First", type: .bank, sortOrder: 0)
        let account3 = Account(name: "Second", type: .creditCard, sortOrder: 1)

        try await repository.save(account1)
        try await repository.save(account2)
        try await repository.save(account3)

        // Act
        let accounts = try await useCase.execute(filter: .default)

        // Assert
        #expect(accounts.count == 3)
        #expect(accounts[0].name == "First")
        #expect(accounts[1].name == "Second")
        #expect(accounts[2].name == "Third")
    }

    // MARK: - Test: Grouped fetch returns correct grouping

    @Test("Grouped fetch returns accounts grouped by type")
    func groupedFetchReturnsCorrectGrouping() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = GetAccountsUseCase(repository: repository)

        try await repository.save(Account(name: "Cash 1", type: .cash, sortOrder: 0))
        try await repository.save(Account(name: "Cash 2", type: .cash, sortOrder: 1))
        try await repository.save(Account(name: "Bank 1", type: .bank, sortOrder: 2))
        try await repository.save(Account(name: "Credit Card", type: .creditCard, sortOrder: 3))

        // Act
        let grouped = try await useCase.executeGrouped(filter: .default)

        // Assert
        #expect(grouped[.cash]?.count == 2)
        #expect(grouped[.bank]?.count == 1)
        #expect(grouped[.creditCard]?.count == 1)
        #expect(grouped[.eWallet] == nil)
    }

    @Test("Grouped accounts are sorted by sortOrder within each group")
    func groupedAccountsSortedWithinGroups() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = GetAccountsUseCase(repository: repository)

        try await repository.save(Account(name: "Cash B", type: .cash, sortOrder: 3))
        try await repository.save(Account(name: "Cash A", type: .cash, sortOrder: 1))
        try await repository.save(Account(name: "Cash C", type: .cash, sortOrder: 5))

        // Act
        let grouped = try await useCase.executeGrouped(filter: .default)

        // Assert
        let cashAccounts = grouped[.cash]!
        #expect(cashAccounts[0].name == "Cash A")
        #expect(cashAccounts[1].name == "Cash B")
        #expect(cashAccounts[2].name == "Cash C")
    }

    // MARK: - Test: Empty results

    @Test("Empty repository returns empty array")
    func emptyRepositoryReturnsEmptyArray() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = GetAccountsUseCase(repository: repository)

        // Act
        let accounts = try await useCase.execute(filter: .default)

        // Assert
        #expect(accounts.isEmpty)
    }

    @Test("Empty grouped results return empty dictionary")
    func emptyGroupedResultsReturnEmptyDictionary() async throws {
        // Arrange
        let repository = MockAccountRepository()
        let useCase = GetAccountsUseCase(repository: repository)

        // Act
        let grouped = try await useCase.executeGrouped(filter: .default)

        // Assert
        #expect(grouped.isEmpty)
    }

    // MARK: - Test: executeTotalBalance falls back to repository when no exchange rate use case

    @Test("executeTotalBalance falls back to repository when no exchange rate use case")
    func totalBalanceFallsBackToRepository() async throws {
        // Arrange
        let repository = MockAccountRepository()
        // No exchangeRateUseCase — fallback path
        let useCase = GetAccountsUseCase(repository: repository)

        let account = Account(name: "Cash", type: .cash, currency: .VND, balance: 500_000)
        try await repository.save(account)

        // Act
        let total = try await useCase.executeTotalBalance(in: .VND)

        // Assert — MockAccountRepository sums same-currency balances
        #expect(total == 500_000)
    }

    // MARK: - Test: executeTotalBalance aggregates multi-currency accounts

    @Test("executeTotalBalance converts and sums multi-currency accounts")
    func totalBalanceConvertsMultiCurrencyAccounts() async throws {
        // Arrange
        let accountRepo = MockAccountRepository()
        let rateRepo = MockExchangeRateRepository()

        // Seed a USD→VND rate of 25,000
        let rate = ExchangeRate(
            baseCurrency: .USD,
            targetCurrency: .VND,
            rate: 25_000,
            date: Date(),
            source: "test"
        )
        try await rateRepo.saveRates([rate])

        let service = MockExchangeRateService()
        let exchangeRateUseCase = ExchangeRateUseCase(repository: rateRepo, service: service)
        let useCase = GetAccountsUseCase(repository: accountRepo, exchangeRateUseCase: exchangeRateUseCase)

        // 2,000,000 VND account
        let vndAccount = Account(name: "VND Cash", type: .cash, currency: .VND, balance: 2_000_000)
        // 100 USD account — should contribute 100 * 25,000 = 2,500,000 VND
        let usdAccount = Account(name: "USD Bank", type: .bank, currency: .USD, balance: 100)

        try await accountRepo.save(vndAccount)
        try await accountRepo.save(usdAccount)

        // Act
        let total = try await useCase.executeTotalBalance(in: .VND)

        // Assert: 2,000,000 + 2,500,000 = 4,500,000
        #expect(total == 4_500_000)
    }

    @Test("executeTotalBalance skips accounts with unavailable rates")
    func totalBalanceSkipsUnavailableRates() async throws {
        // Arrange — no rates seeded, service will throw for unknown pairs
        let accountRepo = MockAccountRepository()
        let rateRepo = MockExchangeRateRepository()
        let service = MockExchangeRateService()
        // Configure service to throw so there is truly no rate available
        await service.reset()
        let exchangeRateUseCase = ExchangeRateUseCase(repository: rateRepo, service: service)
        let useCase = GetAccountsUseCase(repository: accountRepo, exchangeRateUseCase: exchangeRateUseCase)

        // VND account can be added directly; JPY account has no rate to VND
        let vndAccount = Account(name: "VND Cash", type: .cash, currency: .VND, balance: 1_000_000)
        let jpyAccount = Account(name: "JPY Savings", type: .savings, currency: .JPY, balance: 10_000)

        try await accountRepo.save(vndAccount)
        try await accountRepo.save(jpyAccount)

        // Act — JPY→VND will fail silently (try?), contributing 0
        let total = try await useCase.executeTotalBalance(in: .VND)

        // Assert — only the VND balance is counted
        #expect(total == 1_000_000)
    }

    @Test("executeTotalBalance excludes archived and hidden accounts")
    func totalBalanceExcludesArchivedAndHidden() async throws {
        // Arrange
        let accountRepo = MockAccountRepository()
        let rateRepo = MockExchangeRateRepository()
        let service = MockExchangeRateService()
        let exchangeRateUseCase = ExchangeRateUseCase(repository: rateRepo, service: service)
        let useCase = GetAccountsUseCase(repository: accountRepo, exchangeRateUseCase: exchangeRateUseCase)

        let active = Account(name: "Active", type: .cash, currency: .VND, balance: 500_000)
        let archived = Account(name: "Archived", type: .bank, currency: .VND, balance: 999_999, isArchived: true)
        let hidden = Account(name: "Hidden", type: .cash, currency: .VND, balance: 999_999, isHidden: true)

        try await accountRepo.save(active)
        try await accountRepo.save(archived)
        try await accountRepo.save(hidden)

        // Act
        let total = try await useCase.executeTotalBalance(in: .VND)

        // Assert — only active account balance is included
        #expect(total == 500_000)
    }
}
