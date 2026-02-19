import FinanceCore
import Foundation
import SwiftData

/// SwiftData-backed repository for Account entities.
///
/// This actor provides thread-safe access to account data using SwiftData's
/// `@ModelActor` macro. All operations filter out soft-deleted accounts
/// (those with a non-nil `deletedAt` timestamp).
@ModelActor
public actor AccountRepository: AccountRepositoryProtocol {
    // The @ModelActor macro automatically provides:
    // - modelContainer: ModelContainer
    // - modelExecutor: ModelExecutor
    // - init(modelContainer: ModelContainer)

    public func fetchAll() async throws -> [Account] {
        var descriptor = FetchDescriptor<AccountEntity>()
        descriptor.predicate = #Predicate<AccountEntity> { $0.deletedAt == nil }
        descriptor.sortBy = [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]

        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomain() }
    }

    public func fetch(by id: UUID) async throws -> Account? {
        var descriptor = FetchDescriptor<AccountEntity>()
        descriptor.predicate = #Predicate<AccountEntity> { entity in
            entity.id == id && entity.deletedAt == nil
        }
        descriptor.fetchLimit = 1

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    public func save(_ account: Account) async throws {
        // Try to find existing entity
        var descriptor = FetchDescriptor<AccountEntity>()
        descriptor.predicate = #Predicate<AccountEntity> { $0.id == account.id }
        descriptor.fetchLimit = 1

        if let existing = try modelContext.fetch(descriptor).first {
            existing.update(from: account)
        } else {
            let entity = AccountEntity.from(domain: account)
            modelContext.insert(entity)
        }

        try modelContext.save()
    }

    public func delete(by id: UUID) async throws {
        // Soft delete: set deletedAt timestamp
        var descriptor = FetchDescriptor<AccountEntity>()
        descriptor.predicate = #Predicate<AccountEntity> { $0.id == id }
        descriptor.fetchLimit = 1

        guard let entity = try modelContext.fetch(descriptor).first else {
            throw AccountError.accountNotFound(id)
        }

        entity.deletedAt = Date()
        try modelContext.save()
    }

    public func fetchGroupedByType() async throws -> [AccountType: [Account]] {
        let accounts = try await fetchAll()

        var grouped: [AccountType: [Account]] = [:]
        for account in accounts {
            grouped[account.type, default: []].append(account)
        }

        return grouped
    }

    public func fetchTotalBalance(in currency: CurrencyCode) async throws -> Decimal {
        var descriptor = FetchDescriptor<AccountEntity>()
        descriptor.predicate = #Predicate<AccountEntity> { entity in
            entity.deletedAt == nil && entity.currency == currency.rawValue
        }

        let entities = try modelContext.fetch(descriptor)
        return entities.reduce(Decimal(0)) { $0 + $1.balance }
    }

    public func updateBalance(_ accountID: UUID, delta: Decimal) async throws {
        var descriptor = FetchDescriptor<AccountEntity>()
        descriptor.predicate = #Predicate<AccountEntity> { $0.id == accountID }
        descriptor.fetchLimit = 1

        guard let entity = try modelContext.fetch(descriptor).first else {
            throw AccountError.accountNotFound(accountID)
        }

        entity.balance += delta
        entity.updatedAt = Date()
        try modelContext.save()
    }

    public func fetchActiveCount() async throws -> Int {
        var descriptor = FetchDescriptor<AccountEntity>()
        descriptor.predicate = #Predicate<AccountEntity> { entity in
            entity.deletedAt == nil && entity.isArchived == false
        }

        let entities = try modelContext.fetch(descriptor)
        return entities.count
    }

    public func updateSortOrders(_ orders: [(UUID, Int)]) async throws {
        for (accountID, sortOrder) in orders {
            var descriptor = FetchDescriptor<AccountEntity>()
            descriptor.predicate = #Predicate<AccountEntity> { $0.id == accountID }
            descriptor.fetchLimit = 1

            if let entity = try modelContext.fetch(descriptor).first {
                entity.sortOrder = sortOrder
                entity.updatedAt = Date()
            }
        }

        try modelContext.save()
    }
}
