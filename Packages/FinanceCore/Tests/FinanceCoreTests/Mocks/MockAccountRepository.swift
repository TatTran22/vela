import Foundation

@testable import FinanceCore

/// Mock implementation of AccountRepositoryProtocol for testing.
///
/// This mock repository stores accounts in memory and supports all
/// standard repository operations for use in unit tests.
actor MockAccountRepository: AccountRepositoryProtocol {
    private var accounts: [UUID: Account] = [:]

    func fetchAll() async throws -> [Account] {
        Array(accounts.values)
    }

    func fetch(by id: UUID) async throws -> Account? {
        accounts[id]
    }

    func save(_ account: Account) async throws {
        accounts[account.id] = account
    }

    func delete(by id: UUID) async throws {
        guard var account = accounts[id] else {
            throw AccountError.accountNotFound(id)
        }

        // Soft delete
        account.deletedAt = Date()
        accounts[id] = account
    }

    func fetchGroupedByType() async throws -> [AccountType: [Account]] {
        let allAccounts = Array(accounts.values)
        var grouped: [AccountType: [Account]] = [:]

        for account in allAccounts where account.deletedAt == nil {
            grouped[account.type, default: []].append(account)
        }

        return grouped
    }

    func fetchTotalBalance(in currency: CurrencyCode) async throws -> Decimal {
        let activeAccounts = accounts.values.filter {
            !$0.isArchived && !$0.isHidden && $0.deletedAt == nil
        }

        // For testing, just sum balances (assuming same currency)
        return activeAccounts.reduce(0) { $0 + $1.balance }
    }

    func updateBalance(_ accountID: UUID, delta: Decimal) async throws {
        guard var account = accounts[accountID] else {
            throw AccountError.accountNotFound(accountID)
        }

        account.balance += delta
        accounts[accountID] = account
    }

    func fetchActiveCount() async throws -> Int {
        accounts.values.filter { !$0.isArchived && $0.deletedAt == nil }.count
    }

    func updateSortOrders(_ orders: [(UUID, Int)]) async throws {
        for (id, sortOrder) in orders {
            if var account = accounts[id] {
                account.sortOrder = sortOrder
                accounts[id] = account
            }
        }
    }

    // Testing helper methods
    func reset() {
        accounts.removeAll()
    }

    func getAccountCount() -> Int {
        accounts.count
    }
}
