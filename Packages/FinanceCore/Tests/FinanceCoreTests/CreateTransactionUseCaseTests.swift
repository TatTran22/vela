import Testing
import Foundation

@testable import FinanceCore

@Suite("CreateTransactionUseCase Tests")
struct CreateTransactionUseCaseTests {

    // MARK: - Helpers

    private func makeUseCase(
        transactionRepo: MockTransactionRepository = MockTransactionRepository(),
        accountRepo: MockAccountRepository = MockAccountRepository(),
        categoryRepo: MockCategoryRepository = MockCategoryRepository()
    ) -> CreateTransactionUseCase {
        CreateTransactionUseCase(
            transactionRepository: transactionRepo,
            accountRepository: accountRepo,
            categoryRepository: categoryRepo
        )
    }

    // MARK: - Income

    @Test("Income transaction is saved and balance increases")
    func incomeTransactionSavesAndUpdatesBalance() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let account = Account(name: "Cash", type: .cash, currency: .VND, balance: 100_000)
        try await accountRepo.save(account)

        let category = Category(name: "Salary", type: .income)
        await categoryRepo.seed(category)

        let transaction = Transaction(
            amount: 50_000,
            type: .income,
            categoryID: category.id,
            accountID: account.id
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        let saved = try await useCase.execute(transaction)

        #expect(saved.amount == 50_000)
        #expect(saved.type == .income)

        let updatedAccount = try await accountRepo.fetch(by: account.id)
        #expect(updatedAccount?.balance == 150_000)
    }

    // MARK: - Expense

    @Test("Expense transaction is saved and balance decreases")
    func expenseTransactionSavesAndUpdatesBalance() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let account = Account(name: "Cash", type: .cash, currency: .VND, balance: 200_000)
        try await accountRepo.save(account)

        let category = Category(name: "Food", type: .expense)
        await categoryRepo.seed(category)

        let transaction = Transaction(
            amount: 30_000,
            type: .expense,
            categoryID: category.id,
            accountID: account.id
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        _ = try await useCase.execute(transaction)

        let updatedAccount = try await accountRepo.fetch(by: account.id)
        #expect(updatedAccount?.balance == 170_000)
    }

    // MARK: - Amount Validation

    @Test("Zero amount throws amountMustBePositive")
    func zeroAmountThrows() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let account = Account(name: "Cash", type: .cash)
        try await accountRepo.save(account)

        let category = Category(name: "Food", type: .expense)
        await categoryRepo.seed(category)

        let transaction = Transaction(
            amount: 0,
            type: .expense,
            categoryID: category.id,
            accountID: account.id
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        await #expect(throws: TransactionError.amountMustBePositive) {
            try await useCase.execute(transaction)
        }
    }

    @Test("Negative amount throws amountMustBePositive")
    func negativeAmountThrows() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let account = Account(name: "Cash", type: .cash)
        try await accountRepo.save(account)

        let category = Category(name: "Food", type: .expense)
        await categoryRepo.seed(category)

        let transaction = Transaction(
            amount: -100,
            type: .expense,
            categoryID: category.id,
            accountID: account.id
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        await #expect(throws: TransactionError.amountMustBePositive) {
            try await useCase.execute(transaction)
        }
    }

    // MARK: - Account Validation

    @Test("Non-existent source account throws accountNotFound")
    func nonExistentAccountThrows() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let fakeAccountID = UUID()
        let category = Category(name: "Salary", type: .income)
        await categoryRepo.seed(category)

        let transaction = Transaction(
            amount: 100,
            type: .income,
            categoryID: category.id,
            accountID: fakeAccountID
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        await #expect(throws: TransactionError.accountNotFound(fakeAccountID)) {
            try await useCase.execute(transaction)
        }
    }

    // MARK: - Category Validation

    @Test("Non-existent category throws categoryRequired")
    func nonExistentCategoryThrows() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let account = Account(name: "Cash", type: .cash)
        try await accountRepo.save(account)

        let transaction = Transaction(
            amount: 100,
            type: .income,
            categoryID: UUID(),
            accountID: account.id
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        await #expect(throws: TransactionError.categoryRequired) {
            try await useCase.execute(transaction)
        }
    }

    @Test("Expense category on income transaction throws categoryTypeMismatch")
    func categoryTypeMismatchThrows() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let account = Account(name: "Cash", type: .cash)
        try await accountRepo.save(account)

        let category = Category(name: "Food", type: .expense) // wrong type for income
        await categoryRepo.seed(category)

        let transaction = Transaction(
            amount: 100,
            type: .income,
            categoryID: category.id,
            accountID: account.id
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        await #expect(throws: TransactionError.self) {
            try await useCase.execute(transaction)
        }
    }

    @Test("Income category on expense transaction throws categoryTypeMismatch")
    func incomeCategoryOnExpenseThrows() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let account = Account(name: "Cash", type: .cash)
        try await accountRepo.save(account)

        let category = Category(name: "Salary", type: .income) // wrong type for expense
        await categoryRepo.seed(category)

        let transaction = Transaction(
            amount: 100,
            type: .expense,
            categoryID: category.id,
            accountID: account.id
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        await #expect(throws: TransactionError.self) {
            try await useCase.execute(transaction)
        }
    }

    // MARK: - Transfer

    @Test("Transfer updates both account balances")
    func transferUpdatesBothBalances() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let source = Account(name: "Cash", type: .cash, currency: .VND, balance: 500_000)
        let destination = Account(name: "Bank", type: .bank, currency: .VND, balance: 200_000)
        try await accountRepo.save(source)
        try await accountRepo.save(destination)

        let category = Category(name: "Transfer", type: .transfer)
        await categoryRepo.seed(category)

        let transaction = Transaction(
            amount: 100_000,
            type: .transfer,
            categoryID: category.id,
            accountID: source.id,
            toAccountID: destination.id
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        _ = try await useCase.execute(transaction)

        let updatedSource = try await accountRepo.fetch(by: source.id)
        let updatedDest = try await accountRepo.fetch(by: destination.id)

        #expect(updatedSource?.balance == 400_000)
        #expect(updatedDest?.balance == 300_000)
    }

    @Test("Transfer without destination account throws destinationAccountRequired")
    func transferWithoutDestinationThrows() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let account = Account(name: "Cash", type: .cash)
        try await accountRepo.save(account)

        let category = Category(name: "Transfer", type: .transfer)
        await categoryRepo.seed(category)

        let transaction = Transaction(
            amount: 100,
            type: .transfer,
            categoryID: category.id,
            accountID: account.id,
            toAccountID: nil
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        await #expect(throws: TransactionError.destinationAccountRequired) {
            try await useCase.execute(transaction)
        }
    }

    @Test("Transfer to same account throws sourceAndDestinationSame")
    func transferToSameAccountThrows() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let account = Account(name: "Cash", type: .cash)
        try await accountRepo.save(account)

        let category = Category(name: "Transfer", type: .transfer)
        await categoryRepo.seed(category)

        let transaction = Transaction(
            amount: 100,
            type: .transfer,
            categoryID: category.id,
            accountID: account.id,
            toAccountID: account.id
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        await #expect(throws: TransactionError.sourceAndDestinationSame) {
            try await useCase.execute(transaction)
        }
    }

    @Test("Transfer to non-existent destination throws accountNotFound")
    func transferToNonExistentDestinationThrows() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let source = Account(name: "Cash", type: .cash)
        try await accountRepo.save(source)

        let fakeDestID = UUID()
        let category = Category(name: "Transfer", type: .transfer)
        await categoryRepo.seed(category)

        let transaction = Transaction(
            amount: 100,
            type: .transfer,
            categoryID: category.id,
            accountID: source.id,
            toAccountID: fakeDestID
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        await #expect(throws: TransactionError.accountNotFound(fakeDestID)) {
            try await useCase.execute(transaction)
        }
    }

    // MARK: - Cross-Currency Transfer

    @Test("Cross-currency transfer with exchange rate applies correct amounts")
    func crossCurrencyTransferWithRate() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let source = Account(name: "USD Account", type: .bank, currency: .USD, balance: 1_000)
        let destination = Account(name: "VND Account", type: .bank, currency: .VND, balance: 0)
        try await accountRepo.save(source)
        try await accountRepo.save(destination)

        let category = Category(name: "Transfer", type: .transfer)
        await categoryRepo.seed(category)

        // 1 USD = 25000 VND
        let transaction = Transaction(
            amount: 10,        // 10 USD
            type: .transfer,
            categoryID: category.id,
            accountID: source.id,
            toAccountID: destination.id,
            metadata: ["exchangeRate": "25000"]
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        _ = try await useCase.execute(transaction)

        let updatedSource = try await accountRepo.fetch(by: source.id)
        let updatedDest = try await accountRepo.fetch(by: destination.id)

        #expect(updatedSource?.balance == 990)       // 1000 - 10
        #expect(updatedDest?.balance == 250_000)     // 0 + (10 * 25000)
    }

    @Test("Cross-currency transfer without exchange rate throws exchangeRateRequired")
    func crossCurrencyTransferWithoutRateThrows() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let source = Account(name: "USD Account", type: .bank, currency: .USD, balance: 1_000)
        let destination = Account(name: "VND Account", type: .bank, currency: .VND, balance: 0)
        try await accountRepo.save(source)
        try await accountRepo.save(destination)

        let category = Category(name: "Transfer", type: .transfer)
        await categoryRepo.seed(category)

        let transaction = Transaction(
            amount: 10,
            type: .transfer,
            categoryID: category.id,
            accountID: source.id,
            toAccountID: destination.id
            // No metadata / no exchange rate
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        await #expect(throws: TransactionError.exchangeRateRequired) {
            try await useCase.execute(transaction)
        }
    }

    // MARK: - Category type check skipped for transfer

    @Test("Transfer can use any category type without mismatch error")
    func transferSkipsCategoryTypeCheck() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let source = Account(name: "Cash", type: .cash, currency: .VND, balance: 500_000)
        let dest = Account(name: "Bank", type: .bank, currency: .VND, balance: 0)
        try await accountRepo.save(source)
        try await accountRepo.save(dest)

        // Using an income-typed category for a transfer — should be allowed
        let category = Category(name: "Salary", type: .income)
        await categoryRepo.seed(category)

        let transaction = Transaction(
            amount: 100_000,
            type: .transfer,
            categoryID: category.id,
            accountID: source.id,
            toAccountID: dest.id
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        let saved = try await useCase.execute(transaction)

        #expect(saved.type == .transfer)
    }
}
