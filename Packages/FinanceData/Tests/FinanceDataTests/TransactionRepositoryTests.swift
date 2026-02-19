import Testing
import Foundation
import SwiftData

@testable import FinanceCore
@testable import FinanceData

// MARK: - T26: TransactionRepository Tests

@Suite("TransactionRepository Tests")
struct TransactionRepositoryTests {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        try ModelContainerSetup.createContainer(inMemory: true)
    }

    /// Returns a deterministic date offset by the given number of days from a fixed
    /// reference point so that tests with multiple transactions produce stable orderings.
    private func date(daysAgo days: Int) -> Date {
        // Use a fixed reference point to avoid any race conditions with Date()
        let reference = Date(timeIntervalSinceReferenceDate: 800_000_000) // ~2025-05-08
        return reference.addingTimeInterval(TimeInterval(-days) * 86_400)
    }

    private func makeTransaction(
        amount: Decimal = 10_000,
        type: TransactionType = .expense,
        accountID: UUID = UUID(),
        categoryID: UUID = UUID(),
        date: Date? = nil,
        note: String = "",
        tags: [UUID] = []
    ) -> Transaction {
        Transaction(
            amount: amount,
            type: type,
            categoryID: categoryID,
            accountID: accountID,
            note: note,
            date: date ?? Date(),
            tags: tags
        )
    }

    // MARK: - CRUD: Save and Fetch

    @Test("Empty repository returns empty fetch result")
    func fetchEmptyRepository() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let results = try await repo.fetch(filter: TransactionFilter(), offset: 0, limit: 50)
        #expect(results.isEmpty)
    }

    @Test("Save and fetch by ID returns correct transaction")
    func testSaveAndFetch() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let accountID = UUID()
        let categoryID = UUID()
        let tx = makeTransaction(
            amount: 50_000,
            type: .income,
            accountID: accountID,
            categoryID: categoryID,
            note: "Salary"
        )

        try await repo.save(tx)
        let fetched = try await repo.fetch(by: tx.id)

        #expect(fetched != nil)
        #expect(fetched?.id == tx.id)
        #expect(fetched?.amount == 50_000)
        #expect(fetched?.type == .income)
        #expect(fetched?.accountID == accountID)
        #expect(fetched?.categoryID == categoryID)
        #expect(fetched?.note == "Salary")
    }

    @Test("Save multiple transactions and fetch all")
    func testSaveMultipleAndFetchAll() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let tx1 = makeTransaction(amount: 10_000, date: date(daysAgo: 2))
        let tx2 = makeTransaction(amount: 20_000, date: date(daysAgo: 1))
        let tx3 = makeTransaction(amount: 30_000, date: date(daysAgo: 0))

        try await repo.save(tx1)
        try await repo.save(tx2)
        try await repo.save(tx3)

        let results = try await repo.fetch(filter: TransactionFilter(), offset: 0, limit: 50)
        #expect(results.count == 3)
    }

    // MARK: - CRUD: Update

    @Test("Update modifies existing transaction")
    func testUpdate() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        var tx = makeTransaction(amount: 10_000, type: .expense, note: "Original")
        try await repo.save(tx)

        tx.amount = 25_000
        tx.note = "Updated"
        try await repo.update(tx)

        let fetched = try await repo.fetch(by: tx.id)
        #expect(fetched?.amount == 25_000)
        #expect(fetched?.note == "Updated")
    }

    @Test("Update non-existent transaction throws transactionNotFound")
    func testUpdateNonExistentThrows() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let nonExistentID = UUID()
        let tx = makeTransaction()
        // Use the Transaction init with explicit id to create an ID we know doesn't exist
        let fakeTx = Transaction(
            id: nonExistentID,
            amount: 100,
            type: .expense,
            categoryID: UUID(),
            accountID: UUID()
        )

        await #expect(throws: TransactionError.transactionNotFound(nonExistentID)) {
            try await repo.update(fakeTx)
        }

        _ = tx // suppress unused variable warning
    }

    @Test("Save existing ID upserts (does not duplicate)")
    func testSaveUpserts() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        var tx = makeTransaction(amount: 10_000)
        try await repo.save(tx)

        tx.amount = 20_000
        try await repo.save(tx)  // upsert

        let results = try await repo.fetch(filter: TransactionFilter(), offset: 0, limit: 50)
        #expect(results.count == 1)
        #expect(results.first?.amount == 20_000)
    }

    // MARK: - Soft Delete

    @Test("Soft delete sets deletedAt on transaction")
    func testSoftDelete() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let tx = makeTransaction()
        try await repo.save(tx)

        let beforeDelete = try await repo.fetch(by: tx.id)
        #expect(beforeDelete != nil)

        try await repo.delete(by: tx.id)

        // fetch(by:) excludes soft-deleted records
        let afterDelete = try await repo.fetch(by: tx.id)
        #expect(afterDelete == nil)
    }

    @Test("Soft-deleted transactions are excluded from list fetch")
    func testDeletedNotFetched() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let active = makeTransaction(amount: 10_000, date: date(daysAgo: 1))
        var deleted = makeTransaction(amount: 20_000, date: date(daysAgo: 0))
        deleted.deletedAt = Date()

        try await repo.save(active)
        try await repo.save(deleted)

        let results = try await repo.fetch(filter: TransactionFilter(), offset: 0, limit: 50)
        #expect(results.count == 1)
        #expect(results.first?.id == active.id)
    }

    @Test("Delete non-existent transaction throws transactionNotFound")
    func testDeleteNonExistentThrows() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let fakeID = UUID()
        await #expect(throws: TransactionError.transactionNotFound(fakeID)) {
            try await repo.delete(by: fakeID)
        }
    }

    // MARK: - Filter: Account

    @Test("Filter by account ID returns only matching transactions")
    func testFilterByAccount() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let targetAccountID = UUID()
        let otherAccountID = UUID()

        let tx1 = makeTransaction(accountID: targetAccountID, date: date(daysAgo: 2))
        let tx2 = makeTransaction(accountID: targetAccountID, date: date(daysAgo: 1))
        let tx3 = makeTransaction(accountID: otherAccountID, date: date(daysAgo: 0))

        try await repo.save(tx1)
        try await repo.save(tx2)
        try await repo.save(tx3)

        let filter = TransactionFilter(accountIDs: [targetAccountID])
        let results = try await repo.fetch(filter: filter, offset: 0, limit: 50)

        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.accountID == targetAccountID })
    }

    // MARK: - Filter: Type

    @Test("Filter by transaction type returns only matching types")
    func testFilterByType() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let income = makeTransaction(type: .income, date: date(daysAgo: 2))
        let expense = makeTransaction(type: .expense, date: date(daysAgo: 1))
        let transfer = makeTransaction(type: .transfer, date: date(daysAgo: 0))

        try await repo.save(income)
        try await repo.save(expense)
        try await repo.save(transfer)

        let filter = TransactionFilter(types: [.income])
        let results = try await repo.fetch(filter: filter, offset: 0, limit: 50)

        #expect(results.count == 1)
        #expect(results.first?.type == .income)
    }

    @Test("excludeTransfers filter removes transfer transactions")
    func testExcludeTransfers() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let income = makeTransaction(type: .income, date: date(daysAgo: 2))
        let expense = makeTransaction(type: .expense, date: date(daysAgo: 1))
        let transfer = makeTransaction(type: .transfer, date: date(daysAgo: 0))

        try await repo.save(income)
        try await repo.save(expense)
        try await repo.save(transfer)

        let filter = TransactionFilter(excludeTransfers: true)
        let results = try await repo.fetch(filter: filter, offset: 0, limit: 50)

        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.type != .transfer })
    }

    // MARK: - Filter: Date Range

    @Test("Filter by date range returns only transactions within the range")
    func testFilterByDateRange() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let ref = date(daysAgo: 0)
        let threeDaysAgo = date(daysAgo: 3)
        let twoDaysAgo = date(daysAgo: 2)
        let yesterday = date(daysAgo: 1)

        let tx1 = makeTransaction(amount: 1_000, date: threeDaysAgo)
        let tx2 = makeTransaction(amount: 2_000, date: twoDaysAgo)
        let tx3 = makeTransaction(amount: 3_000, date: yesterday)
        let tx4 = makeTransaction(amount: 4_000, date: ref)

        try await repo.save(tx1)
        try await repo.save(tx2)
        try await repo.save(tx3)
        try await repo.save(tx4)

        // Range covers only twoDaysAgo through yesterday
        let filter = TransactionFilter(dateRange: twoDaysAgo...yesterday)
        let results = try await repo.fetch(filter: filter, offset: 0, limit: 50)

        #expect(results.count == 2)
        #expect(results.allSatisfy { filter.dateRange!.contains($0.date) })
    }

    // MARK: - Filter: Amount Range

    @Test("Filter by amount range returns only transactions within range")
    func testFilterByAmountRange() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let tx1 = makeTransaction(amount: 5_000, date: date(daysAgo: 3))
        let tx2 = makeTransaction(amount: 50_000, date: date(daysAgo: 2))
        let tx3 = makeTransaction(amount: 500_000, date: date(daysAgo: 1))

        try await repo.save(tx1)
        try await repo.save(tx2)
        try await repo.save(tx3)

        let filter = TransactionFilter(amountRange: Decimal(10_000)...Decimal(100_000))
        let results = try await repo.fetch(filter: filter, offset: 0, limit: 50)

        #expect(results.count == 1)
        #expect(results.first?.amount == 50_000)
    }

    // MARK: - Grouped Fetch

    @Test("fetchGroupedByDate groups transactions by calendar day")
    func testFetchGroupedByDate() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // swiftlint:disable:next force_unwrapping
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let tx1 = makeTransaction(date: today.addingTimeInterval(3_600))
        let tx2 = makeTransaction(date: today.addingTimeInterval(7_200))
        let tx3 = makeTransaction(date: yesterday.addingTimeInterval(3_600))

        try await repo.save(tx1)
        try await repo.save(tx2)
        try await repo.save(tx3)

        let grouped = try await repo.fetchGroupedByDate(filter: TransactionFilter())

        #expect(grouped.count == 2)

        let todayGroup = grouped.first(where: { calendar.isDate($0.0, inSameDayAs: today) })
        let yesterdayGroup = grouped.first(where: { calendar.isDate($0.0, inSameDayAs: yesterday) })

        #expect(todayGroup?.1.count == 2)
        #expect(yesterdayGroup?.1.count == 1)
    }

    @Test("fetchGroupedByDate returns empty array for empty repository")
    func testFetchGroupedByDateEmpty() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let grouped = try await repo.fetchGroupedByDate(filter: TransactionFilter())
        #expect(grouped.isEmpty)
    }

    @Test("fetchGroupedByDate results are ordered newest-first")
    func testFetchGroupedByDateOrder() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // swiftlint:disable:next force_unwrapping
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        // swiftlint:disable:next force_unwrapping
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        try await repo.save(makeTransaction(date: yesterday))
        try await repo.save(makeTransaction(date: twoDaysAgo))
        try await repo.save(makeTransaction(date: today.addingTimeInterval(3_600)))

        let grouped = try await repo.fetchGroupedByDate(filter: TransactionFilter())

        #expect(grouped.count == 3)
        // First group should be today (newest)
        #expect(calendar.isDate(grouped[0].0, inSameDayAs: today))
    }

    // MARK: - Pagination

    @Test("Pagination offset skips correct number of records")
    func testPagination() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        // Seed 10 transactions with distinct dates so ordering is deterministic
        for i in 0..<10 {
            let tx = makeTransaction(
                amount: Decimal(i + 1) * 1_000,
                date: date(daysAgo: 9 - i) // oldest first, newest last
            )
            try await repo.save(tx)
        }

        let page1 = try await repo.fetch(filter: TransactionFilter(), offset: 0, limit: 5)
        let page2 = try await repo.fetch(filter: TransactionFilter(), offset: 5, limit: 5)

        #expect(page1.count == 5)
        #expect(page2.count == 5)

        let page1IDs = Set(page1.map(\.id))
        let page2IDs = Set(page2.map(\.id))
        #expect(page1IDs.isDisjoint(with: page2IDs))
    }

    @Test("Pagination with limit larger than total returns all records")
    func testPaginationLimitExceedsTotal() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let tx1 = makeTransaction(date: date(daysAgo: 1))
        let tx2 = makeTransaction(date: date(daysAgo: 0))
        try await repo.save(tx1)
        try await repo.save(tx2)

        let results = try await repo.fetch(filter: TransactionFilter(), offset: 0, limit: 100)
        #expect(results.count == 2)
    }

    @Test("Pagination offset beyond total returns empty array")
    func testPaginationOffsetBeyondTotal() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let tx = makeTransaction()
        try await repo.save(tx)

        let results = try await repo.fetch(filter: TransactionFilter(), offset: 10, limit: 10)
        #expect(results.isEmpty)
    }

    // MARK: - Count

    @Test("count returns number of non-deleted transactions")
    func testCount() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let tx1 = makeTransaction(date: date(daysAgo: 2))
        let tx2 = makeTransaction(date: date(daysAgo: 1))
        var tx3 = makeTransaction(date: date(daysAgo: 0))
        tx3.deletedAt = Date()

        try await repo.save(tx1)
        try await repo.save(tx2)
        try await repo.save(tx3)

        let count = try await repo.count(filter: TransactionFilter())
        #expect(count == 2)
    }

    // MARK: - Daily Totals

    @Test("dailyTotals returns correct income and expense sums per day")
    func testDailyTotals() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let today = Calendar.current.startOfDay(for: Date())

        let income1 = makeTransaction(amount: 100_000, type: .income, date: today.addingTimeInterval(3_600))
        let income2 = makeTransaction(amount: 50_000, type: .income, date: today.addingTimeInterval(7_200))
        let expense1 = makeTransaction(amount: 30_000, type: .expense, date: today.addingTimeInterval(10_800))
        let transfer = makeTransaction(amount: 20_000, type: .transfer, date: today.addingTimeInterval(14_400))

        try await repo.save(income1)
        try await repo.save(income2)
        try await repo.save(expense1)
        try await repo.save(transfer)

        let totals = try await repo.dailyTotals(filter: TransactionFilter())

        #expect(totals.count == 1)
        #expect(totals[0].income == 150_000)  // 100k + 50k
        #expect(totals[0].expense == 30_000)  // transfers excluded from totals
    }

    @Test("dailyTotals returns empty array for empty repository")
    func testDailyTotalsEmpty() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let totals = try await repo.dailyTotals(filter: TransactionFilter())
        #expect(totals.isEmpty)
    }

    @Test("dailyTotals spans multiple days correctly")
    func testDailyTotalsMultipleDays() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // swiftlint:disable:next force_unwrapping
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let todayExpense = makeTransaction(amount: 50_000, type: .expense, date: today.addingTimeInterval(3_600))
        let yesterdayExpense = makeTransaction(
            amount: 80_000,
            type: .expense,
            date: yesterday.addingTimeInterval(3_600)
        )

        try await repo.save(todayExpense)
        try await repo.save(yesterdayExpense)

        let totals = try await repo.dailyTotals(filter: TransactionFilter())

        #expect(totals.count == 2)
        // Ordered oldest-first
        #expect(totals[0].expense == 80_000)  // yesterday
        #expect(totals[1].expense == 50_000)  // today
    }

    // MARK: - Results Ordering

    @Test("Fetch results are ordered newest-first")
    func testFetchOrderedNewestFirst() async throws {
        let container = try makeContainer()
        let repo = TransactionRepository(modelContainer: container)

        let oldTx = makeTransaction(amount: 1_000, date: date(daysAgo: 5))
        let newTx = makeTransaction(amount: 2_000, date: date(daysAgo: 0))
        let midTx = makeTransaction(amount: 3_000, date: date(daysAgo: 2))

        try await repo.save(oldTx)
        try await repo.save(newTx)
        try await repo.save(midTx)

        let results = try await repo.fetch(filter: TransactionFilter(), offset: 0, limit: 50)

        // Newest first: newTx → midTx → oldTx
        #expect(results[0].id == newTx.id)
        #expect(results[1].id == midTx.id)
        #expect(results[2].id == oldTx.id)
    }
}
