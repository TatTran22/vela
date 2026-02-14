---
description: "Triển khai Data Model — SwiftData entities, repositories, ModelContainer setup cho FinanceData"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: Data Model

## Đọc Context Trước
1. `CLAUDE.md`
2. `docs/DATA-MODEL.md`
3. `docs/ARCHITECTURE.md`

## Tasks

### SwiftData Entities (Packages/FinanceData/Sources/FinanceData/Entities/)
1. `AccountEntity` @Model:
   - id: UUID, name: String, typeRaw: String (→ AccountType)
   - currencyRaw: String (→ CurrencyCode)
   - balance: Decimal, icon: String, color: String
   - eWalletProviderRaw: String?
   - note: String?, sortOrder: Int
   - isArchived: Bool, isHidden: Bool
   - createdAt: Date, updatedAt: Date
   - @Relationship: transactions [TransactionEntity]
   - Indexes: typeRaw, currencyRaw, (typeRaw, sortOrder)

2. `CategoryEntity` @Model:
   - id: UUID, name: String, localizedName: String
   - typeRaw: String (→ CategoryType)
   - icon: String, color: String
   - sortOrder: Int, isDefault: Bool, isArchived: Bool
   - @Relationship: parent CategoryEntity? (inverse: children)
   - @Relationship: children [CategoryEntity]
   - @Relationship: transactions [TransactionEntity]
   - Indexes: typeRaw, (typeRaw, sortOrder)

3. `TransactionEntity` @Model:
   - id: UUID, amount: Decimal, typeRaw: String (→ TransactionType)
   - note: String?, date: Date
   - @Relationship: account AccountEntity
   - @Relationship: toAccount AccountEntity? (transfers)
   - @Relationship: category CategoryEntity
   - @Relationship: tags [TagEntity]
   - receiptImageData: Data?
   - latitude: Double?, longitude: Double?
   - isRecurring: Bool, isDeleted: Bool (soft delete)
   - createdAt: Date, updatedAt: Date
   - Indexes: date, (account, date), (category, date), amount

4. `TagEntity` @Model:
   - id: UUID, name: String, color: String
   - @Relationship: transactions [TransactionEntity]

5. `ExchangeRateEntity` @Model:
   - id: UUID, fromRaw: String, toRaw: String
   - rate: Decimal, date: Date, source: String

### Entity ↔ Model Mappers
6. Extension on each Entity:
   - `toModel() → DomainModel` — convert entity to FinanceCore model
   - `static fromModel(_ model: DomainModel) → Entity` — create entity from model
   - Handle raw string ↔ enum conversion

### Repository Protocols (Packages/FinanceCore/Sources/FinanceCore/Protocols/)
7. `AccountRepository` protocol:
   - fetch() → [Account]
   - fetchGroupedByType() → [AccountType: [Account]]
   - fetchById(_ id: UUID) → Account?
   - save(_ account: Account)
   - delete(_ id: UUID)
   - updateBalance(_ id: UUID, delta: Decimal)

8. `CategoryRepository` protocol:
   - fetch() → [Category]
   - fetchByType(_ type: CategoryType) → [Category]
   - fetchById(_ id: UUID) → Category?
   - save(_ category: Category)
   - delete(_ id: UUID)
   - seedDefaults(locale: Locale)

9. `TransactionRepository` protocol:
   - fetch(filter: TransactionFilter) → [Transaction]
   - fetchGroupedByDate(filter: TransactionFilter) → [(Date, [Transaction])]
   - fetchById(_ id: UUID) → Transaction?
   - save(_ transaction: Transaction)
   - delete(_ id: UUID) (soft delete)
   - batchInsert(_ transactions: [Transaction])

10. `ExchangeRateRepository` protocol:
    - fetchRate(from: CurrencyCode, to: CurrencyCode, date: Date) → ExchangeRate?
    - saveRates(_ rates: [ExchangeRate])

### Repository Implementations (Packages/FinanceData/Sources/FinanceData/Repositories/)
11. Implement all 4 repositories using SwiftData ModelContext
12. Use `@ModelActor` for background operations
13. Efficient queries with `#Predicate` and `FetchDescriptor`
14. Batch operations for imports

### DataStack (Packages/FinanceData/Sources/FinanceData/DataStack/)
15. `DataStack`:
    - ModelContainer configuration
    - Schema versioning setup
    - In-memory container for testing/previews
16. `DataStackConfiguration`:
    - Production: persistent + CloudKit
    - Testing: in-memory
    - Preview: in-memory with sample data
17. `SampleData`:
    - Pre-populated accounts, categories, transactions for SwiftUI previews

### Tests
18. Entity mapping — round trip: Model → Entity → Model
19. Repository CRUD — create, read, update, delete for each
20. Transaction filter — complex queries work correctly
21. Balance update — atomic, concurrent access safe
22. Batch insert — performance with 1000+ transactions
23. In-memory container — tests are isolated, no data leak
