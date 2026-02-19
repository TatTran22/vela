import Foundation

@testable import FinanceCore

/// Mock implementation of TransactionRepositoryProtocol for testing.
///
/// This mock repository stores transactions in memory and supports all standard
/// repository operations for use in unit tests. Soft deletes are implemented by
/// setting `deletedAt`; fetches exclude soft-deleted records by default.
actor MockTransactionRepository: TransactionRepositoryProtocol {
    private var transactions: [UUID: Transaction] = [:]

    func fetch(filter: TransactionFilter, offset: Int, limit: Int) async throws -> [Transaction] {
        let active = transactions.values
            .filter { $0.deletedAt == nil }
            .sorted { $0.date > $1.date }
        let sliced = Array(active.dropFirst(offset).prefix(limit))
        return sliced
    }

    func fetchGroupedByDate(filter: TransactionFilter) async throws -> [(Date, [Transaction])] {
        let active = transactions.values
            .filter { $0.deletedAt == nil }
            .sorted { $0.date > $1.date }

        var groups: [(Date, [Transaction])] = []
        var seen: [Date: Int] = [:]

        let calendar = Calendar.current
        for tx in active {
            let day = calendar.startOfDay(for: tx.date)
            if let index = seen[day] {
                groups[index].1.append(tx)
            } else {
                seen[day] = groups.count
                groups.append((day, [tx]))
            }
        }
        return groups
    }

    func fetch(by id: UUID) async throws -> Transaction? {
        transactions[id]
    }

    func save(_ transaction: Transaction) async throws {
        transactions[transaction.id] = transaction
    }

    func update(_ transaction: Transaction) async throws {
        guard transactions[transaction.id] != nil else {
            throw TransactionError.transactionNotFound(transaction.id)
        }
        transactions[transaction.id] = transaction
    }

    func delete(by id: UUID) async throws {
        guard var transaction = transactions[id] else {
            throw TransactionError.transactionNotFound(id)
        }
        transaction.deletedAt = Date()
        transactions[id] = transaction
    }

    func count(filter: TransactionFilter) async throws -> Int {
        transactions.values.filter { $0.deletedAt == nil }.count
    }

    func dailyTotals(
        filter: TransactionFilter
    ) async throws -> [(date: Date, income: Decimal, expense: Decimal)] {
        let active = transactions.values.filter { $0.deletedAt == nil }
        let calendar = Calendar.current
        var totals: [Date: (income: Decimal, expense: Decimal)] = [:]

        for tx in active {
            let day = calendar.startOfDay(for: tx.date)
            var (income, expense) = totals[day] ?? (0, 0)
            switch tx.type {
            case .income: income += tx.amount
            case .expense: expense += tx.amount
            case .transfer: break
            }
            totals[day] = (income, expense)
        }

        return totals
            .map { (date: $0.key, income: $0.value.income, expense: $0.value.expense) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Testing helpers

    /// Resets the repository to an empty state.
    func reset() {
        transactions.removeAll()
    }

    /// Returns the raw count of all stored transactions (including soft-deleted).
    func rawCount() -> Int {
        transactions.count
    }

    /// Returns all stored transactions (including soft-deleted) for assertion purposes.
    func all() -> [Transaction] {
        Array(transactions.values)
    }
}
