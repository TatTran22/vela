import Testing
import Foundation

@testable import FinanceCore

@Suite("UpdateTransactionUseCase Tests")
struct UpdateTransactionUseCaseTests {

    // MARK: - Helpers

    private func makeUseCase(
        transactionRepo: MockTransactionRepository,
        accountRepo: MockAccountRepository,
        categoryRepo: MockCategoryRepository
    ) -> UpdateTransactionUseCase {
        UpdateTransactionUseCase(
            transactionRepository: transactionRepo,
            accountRepository: accountRepo,
            categoryRepository: categoryRepo
        )
    }

    // MARK: - Happy Path

    @Test("Updating amount reverses old balance and applies new balance")
    func updateAmountAdjustsBalance() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let account = Account(name: "Cash", type: .cash, currency: .VND, balance: 200_000)
        try await accountRepo.save(account)

        let category = Category(name: "Salary", type: .income)
        await categoryRepo.seed(category)

        // Original income of 50_000 — balance should be at 200_000 already reflecting it
        let original = Transaction(
            amount: 50_000,
            type: .income,
            categoryID: category.id,
            accountID: account.id
        )
        try await txRepo.save(original)

        // Update: change amount to 80_000
        var updated = original
        updated.amount = 80_000

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        let result = try await useCase.execute(updated)

        #expect(result.amount == 80_000)

        let updatedAccount = try await accountRepo.fetch(by: account.id)
        // Reverse old (+50k): 200k - 50k = 150k; apply new (+80k): 150k + 80k = 230k
        #expect(updatedAccount?.balance == 230_000)
    }

    @Test("Changing transaction type from expense to income reverses and reapplies balance")
    func changeTypeFromExpenseToIncome() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let account = Account(name: "Cash", type: .cash, currency: .VND, balance: 150_000)
        try await accountRepo.save(account)

        let expenseCategory = Category(name: "Food", type: .expense)
        let incomeCategory = Category(name: "Salary", type: .income)
        await categoryRepo.seed(expenseCategory)
        await categoryRepo.seed(incomeCategory)

        // Original expense of 50_000 — account balance reflects the deduction
        let original = Transaction(
            amount: 50_000,
            type: .expense,
            categoryID: expenseCategory.id,
            accountID: account.id
        )
        try await txRepo.save(original)

        // Update to income using income category
        var updated = original
        updated.type = .income
        updated.categoryID = incomeCategory.id

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        _ = try await useCase.execute(updated)

        let updatedAccount = try await accountRepo.fetch(by: account.id)
        // Reverse old expense (-50k → add back +50k): 150k + 50k = 200k
        // Apply new income (+50k): 200k + 50k = 250k
        #expect(updatedAccount?.balance == 250_000)
    }

    @Test("Update transfer reverses old transfer and applies new transfer")
    func updateTransferReversesAndReapplies() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let source = Account(name: "Cash", type: .cash, currency: .VND, balance: 400_000)
        let dest = Account(name: "Bank", type: .bank, currency: .VND, balance: 300_000)
        try await accountRepo.save(source)
        try await accountRepo.save(dest)

        let category = Category(name: "Transfer", type: .transfer)
        await categoryRepo.seed(category)

        // Original transfer of 100_000 (already reflected in balances)
        let original = Transaction(
            amount: 100_000,
            type: .transfer,
            categoryID: category.id,
            accountID: source.id,
            toAccountID: dest.id
        )
        try await txRepo.save(original)

        // Update: change amount to 150_000
        var updated = original
        updated.amount = 150_000

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        _ = try await useCase.execute(updated)

        let updatedSource = try await accountRepo.fetch(by: source.id)
        let updatedDest = try await accountRepo.fetch(by: dest.id)

        // Reverse old: source +100k, dest -100k → source=500k, dest=200k
        // Apply new: source -150k, dest +150k → source=350k, dest=350k
        #expect(updatedSource?.balance == 350_000)
        #expect(updatedDest?.balance == 350_000)
    }

    // MARK: - Validation Errors

    @Test("Non-existent transaction throws transactionNotFound")
    func nonExistentTransactionThrows() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let fakeID = UUID()
        let transaction = Transaction(
            id: fakeID,
            amount: 100,
            type: .expense,
            categoryID: UUID(),
            accountID: UUID()
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        await #expect(throws: TransactionError.transactionNotFound(fakeID)) {
            try await useCase.execute(transaction)
        }
    }

    @Test("Zero amount throws amountMustBePositive")
    func zeroAmountThrows() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let account = Account(name: "Cash", type: .cash)
        try await accountRepo.save(account)

        let category = Category(name: "Food", type: .expense)
        await categoryRepo.seed(category)

        let original = Transaction(
            amount: 100,
            type: .expense,
            categoryID: category.id,
            accountID: account.id
        )
        try await txRepo.save(original)

        var updated = original
        updated.amount = 0

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        await #expect(throws: TransactionError.amountMustBePositive) {
            try await useCase.execute(updated)
        }
    }

    @Test("Non-existent source account throws accountNotFound")
    func nonExistentSourceAccountThrows() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let account = Account(name: "Cash", type: .cash)
        try await accountRepo.save(account)

        let category = Category(name: "Food", type: .expense)
        await categoryRepo.seed(category)

        let original = Transaction(
            amount: 100,
            type: .expense,
            categoryID: category.id,
            accountID: account.id
        )
        try await txRepo.save(original)

        let fakeAccountID = UUID()
        var updated = original
        updated.amount = 200
        // Reassign to a non-existent account
        updated = Transaction(
            id: original.id,
            amount: 200,
            type: .expense,
            categoryID: category.id,
            accountID: fakeAccountID
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        await #expect(throws: TransactionError.accountNotFound(fakeAccountID)) {
            try await useCase.execute(updated)
        }
    }

    @Test("Category type mismatch throws categoryTypeMismatch")
    func categoryTypeMismatchThrows() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let account = Account(name: "Cash", type: .cash)
        try await accountRepo.save(account)

        let expenseCategory = Category(name: "Food", type: .expense)
        let incomeCategory = Category(name: "Salary", type: .income)
        await categoryRepo.seed(expenseCategory)
        await categoryRepo.seed(incomeCategory)

        let original = Transaction(
            amount: 100,
            type: .expense,
            categoryID: expenseCategory.id,
            accountID: account.id
        )
        try await txRepo.save(original)

        // Still expense type but now pointing to an income category
        let updated = Transaction(
            id: original.id,
            amount: 100,
            type: .expense,
            categoryID: incomeCategory.id,
            accountID: account.id
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        await #expect(throws: TransactionError.self) {
            try await useCase.execute(updated)
        }
    }

    @Test("Transfer without destination throws destinationAccountRequired")
    func transferWithoutDestinationThrows() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let account = Account(name: "Cash", type: .cash)
        try await accountRepo.save(account)

        let category = Category(name: "Transfer", type: .transfer)
        await categoryRepo.seed(category)

        let original = Transaction(
            amount: 100,
            type: .transfer,
            categoryID: category.id,
            accountID: account.id,
            toAccountID: account.id  // will be changed; save it first
        )
        try await txRepo.save(original)

        let updated = Transaction(
            id: original.id,
            amount: 100,
            type: .transfer,
            categoryID: category.id,
            accountID: account.id,
            toAccountID: nil  // missing destination
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        await #expect(throws: TransactionError.destinationAccountRequired) {
            try await useCase.execute(updated)
        }
    }

    @Test("Transfer to same account throws sourceAndDestinationSame")
    func transferToSameAccountThrows() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let source = Account(name: "Cash", type: .cash)
        let dest = Account(name: "Bank", type: .bank)
        try await accountRepo.save(source)
        try await accountRepo.save(dest)

        let category = Category(name: "Transfer", type: .transfer)
        await categoryRepo.seed(category)

        let original = Transaction(
            amount: 100,
            type: .transfer,
            categoryID: category.id,
            accountID: source.id,
            toAccountID: dest.id
        )
        try await txRepo.save(original)

        let updated = Transaction(
            id: original.id,
            amount: 100,
            type: .transfer,
            categoryID: category.id,
            accountID: source.id,
            toAccountID: source.id  // same as source
        )

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        await #expect(throws: TransactionError.sourceAndDestinationSame) {
            try await useCase.execute(updated)
        }
    }

    // MARK: - updatedAt Timestamp

    @Test("Update sets a new updatedAt timestamp")
    func updateSetsUpdatedAt() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()
        let categoryRepo = MockCategoryRepository()

        let account = Account(name: "Cash", type: .cash)
        try await accountRepo.save(account)

        let category = Category(name: "Food", type: .expense)
        await categoryRepo.seed(category)

        let pastDate = Date(timeIntervalSinceNow: -3600)
        let original = Transaction(
            amount: 100,
            type: .expense,
            categoryID: category.id,
            accountID: account.id,
            updatedAt: pastDate
        )
        try await txRepo.save(original)

        var updated = original
        updated.amount = 200

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo, categoryRepo: categoryRepo)
        let result = try await useCase.execute(updated)

        #expect(result.updatedAt > pastDate)
    }
}
