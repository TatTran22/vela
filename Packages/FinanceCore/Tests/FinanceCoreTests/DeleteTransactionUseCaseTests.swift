import Testing
import Foundation

@testable import FinanceCore

@Suite("DeleteTransactionUseCase Tests")
struct DeleteTransactionUseCaseTests {

    // MARK: - Helpers

    private func makeUseCase(
        transactionRepo: MockTransactionRepository,
        accountRepo: MockAccountRepository
    ) -> DeleteTransactionUseCase {
        DeleteTransactionUseCase(
            transactionRepository: transactionRepo,
            accountRepository: accountRepo
        )
    }

    // MARK: - Income Deletion

    @Test("Deleting income transaction reverses balance increase")
    func deleteIncomeReversesBalance() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()

        // Account balance already reflects the income
        let account = Account(name: "Cash", type: .cash, currency: .VND, balance: 150_000)
        try await accountRepo.save(account)

        let transaction = Transaction(
            amount: 50_000,
            type: .income,
            categoryID: UUID(),
            accountID: account.id
        )
        try await txRepo.save(transaction)

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo)
        try await useCase.execute(id: transaction.id)

        let updatedAccount = try await accountRepo.fetch(by: account.id)
        // 150k - 50k = 100k
        #expect(updatedAccount?.balance == 100_000)
    }

    // MARK: - Expense Deletion

    @Test("Deleting expense transaction restores balance")
    func deleteExpenseRestoresBalance() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()

        // Account balance already reflects the expense deduction
        let account = Account(name: "Cash", type: .cash, currency: .VND, balance: 70_000)
        try await accountRepo.save(account)

        let transaction = Transaction(
            amount: 30_000,
            type: .expense,
            categoryID: UUID(),
            accountID: account.id
        )
        try await txRepo.save(transaction)

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo)
        try await useCase.execute(id: transaction.id)

        let updatedAccount = try await accountRepo.fetch(by: account.id)
        // 70k + 30k = 100k
        #expect(updatedAccount?.balance == 100_000)
    }

    // MARK: - Transfer Deletion

    @Test("Deleting transfer reverses both account balance changes")
    func deleteTransferReversesBothBalances() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()

        // Balances already reflect: source paid 100k, dest received 100k
        let source = Account(name: "Cash", type: .cash, currency: .VND, balance: 400_000)
        let dest = Account(name: "Bank", type: .bank, currency: .VND, balance: 300_000)
        try await accountRepo.save(source)
        try await accountRepo.save(dest)

        let transaction = Transaction(
            amount: 100_000,
            type: .transfer,
            categoryID: UUID(),
            accountID: source.id,
            toAccountID: dest.id
        )
        try await txRepo.save(transaction)

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo)
        try await useCase.execute(id: transaction.id)

        let updatedSource = try await accountRepo.fetch(by: source.id)
        let updatedDest = try await accountRepo.fetch(by: dest.id)

        // Reverse: source +100k → 500k, dest -100k → 200k
        #expect(updatedSource?.balance == 500_000)
        #expect(updatedDest?.balance == 200_000)
    }

    @Test("Deleting cross-currency transfer uses exchange rate for reversal")
    func deleteCrossCurrencyTransferUsesRate() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()

        // 10 USD was transferred at rate 25000 → 250000 VND credited
        let source = Account(name: "USD", type: .bank, currency: .USD, balance: 990)
        let dest = Account(name: "VND", type: .bank, currency: .VND, balance: 250_000)
        try await accountRepo.save(source)
        try await accountRepo.save(dest)

        let transaction = Transaction(
            amount: 10,
            type: .transfer,
            categoryID: UUID(),
            accountID: source.id,
            toAccountID: dest.id,
            metadata: ["exchangeRate": "25000"]
        )
        try await txRepo.save(transaction)

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo)
        try await useCase.execute(id: transaction.id)

        let updatedSource = try await accountRepo.fetch(by: source.id)
        let updatedDest = try await accountRepo.fetch(by: dest.id)

        // Reverse: source +10 → 1000, dest -(10*25000) → 0
        #expect(updatedSource?.balance == 1_000)
        #expect(updatedDest?.balance == 0)
    }

    // MARK: - Soft Delete

    @Test("Deleted transaction has deletedAt set")
    func deletedTransactionHasDeletedAt() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()

        let account = Account(name: "Cash", type: .cash)
        try await accountRepo.save(account)

        let transaction = Transaction(
            amount: 10_000,
            type: .expense,
            categoryID: UUID(),
            accountID: account.id
        )
        try await txRepo.save(transaction)

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo)
        try await useCase.execute(id: transaction.id)

        let fetched = try await txRepo.fetch(by: transaction.id)
        #expect(fetched?.deletedAt != nil)
    }

    @Test("Deleted transaction data is preserved (soft delete)")
    func deletedTransactionDataPreserved() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()

        let account = Account(name: "Cash", type: .cash)
        try await accountRepo.save(account)

        let transaction = Transaction(
            amount: 99_000,
            type: .expense,
            categoryID: UUID(),
            accountID: account.id,
            note: "Lunch"
        )
        try await txRepo.save(transaction)

        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo)
        try await useCase.execute(id: transaction.id)

        let fetched = try await txRepo.fetch(by: transaction.id)
        #expect(fetched?.amount == 99_000)
        #expect(fetched?.note == "Lunch")
        #expect(fetched?.type == .expense)
    }

    // MARK: - Error Cases

    @Test("Non-existent transaction throws transactionNotFound")
    func nonExistentTransactionThrows() async throws {
        let txRepo = MockTransactionRepository()
        let accountRepo = MockAccountRepository()

        let fakeID = UUID()
        let useCase = makeUseCase(transactionRepo: txRepo, accountRepo: accountRepo)

        await #expect(throws: TransactionError.transactionNotFound(fakeID)) {
            try await useCase.execute(id: fakeID)
        }
    }
}
