import Testing
import Foundation

@testable import FinanceCore

@Suite("GetTransactionsUseCase Tests")
struct GetTransactionsUseCaseTests {

    // MARK: - Helpers

    private func makeTransaction(
        amount: Decimal = 10_000,
        type: TransactionType = .expense,
        accountID: UUID = UUID(),
        categoryID: UUID = UUID(),
        date: Date = Date()
    ) -> Transaction {
        Transaction(
            amount: amount,
            type: type,
            categoryID: categoryID,
            accountID: accountID,
            date: date
        )
    }

    // MARK: - execute(filter:offset:limit:)

    @Test("Fetches transactions matching filter with default pagination")
    func fetchesTransactionsWithDefaultPagination() async throws {
        let txRepo = MockTransactionRepository()
        let useCase = GetTransactionsUseCase(repository: txRepo)

        let tx1 = makeTransaction(amount: 10_000)
        let tx2 = makeTransaction(amount: 20_000)
        try await txRepo.save(tx1)
        try await txRepo.save(tx2)

        let results = try await useCase.execute(filter: TransactionFilter(), offset: 0, limit: 50)
        #expect(results.count == 2)
    }

    @Test("Default execute(filter:) overload uses offset 0 and limit 50")
    func defaultOverloadUsesCorrectDefaults() async throws {
        let txRepo = MockTransactionRepository()
        let useCase = GetTransactionsUseCase(repository: txRepo)

        // Seed 60 transactions
        for i in 0..<60 {
            let tx = Transaction(
                amount: Decimal(i + 1) * 1_000,
                type: .expense,
                categoryID: UUID(),
                accountID: UUID()
            )
            try await txRepo.save(tx)
        }

        let results = try await useCase.execute(filter: TransactionFilter())
        // Default limit is 50
        #expect(results.count == 50)
    }

    @Test("Pagination offset skips records")
    func paginationOffsetSkipsRecords() async throws {
        let txRepo = MockTransactionRepository()
        let useCase = GetTransactionsUseCase(repository: txRepo)

        for i in 0..<10 {
            let tx = Transaction(
                amount: Decimal(i + 1) * 1_000,
                type: .expense,
                categoryID: UUID(),
                accountID: UUID()
            )
            try await txRepo.save(tx)
        }

        let page1 = try await useCase.execute(filter: TransactionFilter(), offset: 0, limit: 5)
        let page2 = try await useCase.execute(filter: TransactionFilter(), offset: 5, limit: 5)

        #expect(page1.count == 5)
        #expect(page2.count == 5)

        // Pages should not overlap
        let page1IDs = Set(page1.map(\.id))
        let page2IDs = Set(page2.map(\.id))
        #expect(page1IDs.isDisjoint(with: page2IDs))
    }

    @Test("Empty repository returns empty array")
    func emptyRepositoryReturnsEmptyArray() async throws {
        let txRepo = MockTransactionRepository()
        let useCase = GetTransactionsUseCase(repository: txRepo)

        let results = try await useCase.execute(filter: TransactionFilter(), offset: 0, limit: 50)
        #expect(results.isEmpty)
    }

    @Test("Soft-deleted transactions are excluded from results")
    func softDeletedTransactionsExcluded() async throws {
        let txRepo = MockTransactionRepository()
        let useCase = GetTransactionsUseCase(repository: txRepo)

        let active = makeTransaction(amount: 10_000)
        var deleted = makeTransaction(amount: 20_000)
        deleted.deletedAt = Date()

        try await txRepo.save(active)
        try await txRepo.save(deleted)

        let results = try await useCase.execute(filter: TransactionFilter(), offset: 0, limit: 50)
        #expect(results.count == 1)
        #expect(results.first?.id == active.id)
    }

    // MARK: - executeGrouped(filter:)

    @Test("executeGrouped returns transactions grouped by calendar day")
    func executeGroupedReturnsByDay() async throws {
        let txRepo = MockTransactionRepository()
        let useCase = GetTransactionsUseCase(repository: txRepo)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // swiftlint:disable:next force_unwrapping
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let tx1 = makeTransaction(date: today.addingTimeInterval(3600))
        let tx2 = makeTransaction(date: today.addingTimeInterval(7200))
        let tx3 = makeTransaction(date: yesterday.addingTimeInterval(3600))

        try await txRepo.save(tx1)
        try await txRepo.save(tx2)
        try await txRepo.save(tx3)

        let grouped = try await useCase.executeGrouped(filter: TransactionFilter())

        #expect(grouped.count == 2)

        // First group should be today (newest first)
        let todayGroup = grouped.first(where: { calendar.isDate($0.0, inSameDayAs: today) })
        let yesterdayGroup = grouped.first(where: { calendar.isDate($0.0, inSameDayAs: yesterday) })

        #expect(todayGroup?.1.count == 2)
        #expect(yesterdayGroup?.1.count == 1)
    }

    // MARK: - dailyTotals(filter:)

    @Test("dailyTotals returns correct income and expense sums per day")
    func dailyTotalsReturnCorrectSums() async throws {
        let txRepo = MockTransactionRepository()
        let useCase = GetTransactionsUseCase(repository: txRepo)

        let accountID = UUID()
        let categoryID = UUID()
        let today = Calendar.current.startOfDay(for: Date())

        let income1 = Transaction(
            amount: 100_000,
            type: .income,
            categoryID: categoryID,
            accountID: accountID,
            date: today.addingTimeInterval(3600)
        )
        let income2 = Transaction(
            amount: 50_000,
            type: .income,
            categoryID: categoryID,
            accountID: accountID,
            date: today.addingTimeInterval(7200)
        )
        let expense1 = Transaction(
            amount: 30_000,
            type: .expense,
            categoryID: categoryID,
            accountID: accountID,
            date: today.addingTimeInterval(10800)
        )

        try await txRepo.save(income1)
        try await txRepo.save(income2)
        try await txRepo.save(expense1)

        let totals = try await useCase.dailyTotals(filter: TransactionFilter())

        #expect(totals.count == 1)
        #expect(totals[0].income == 150_000)
        #expect(totals[0].expense == 30_000)
    }

    @Test("dailyTotals returns empty array for no transactions")
    func dailyTotalsEmptyForNoTransactions() async throws {
        let txRepo = MockTransactionRepository()
        let useCase = GetTransactionsUseCase(repository: txRepo)

        let totals = try await useCase.dailyTotals(filter: TransactionFilter())
        #expect(totals.isEmpty)
    }
}
