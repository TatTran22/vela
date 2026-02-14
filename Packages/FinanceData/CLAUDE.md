# FinanceData Module Context

## Purpose
Data persistence layer using SwiftData/CoreData with CloudKit sync. Implements the Repository pattern to abstract data access from business logic.

## Key Rules
- **Repository pattern** — ViewModels and UseCases NEVER access SwiftData/CoreData directly
- **All data access is async** — use `async throws` for all repository methods
- **Thread safety** — use `ModelActor` for background operations
- **CloudKit sync** — all models must be CloudKit-compatible (no unique constraints, optional relationships)

## Repository Pattern
```swift
/// Protocol in FinanceCore (not here)
protocol TransactionRepositoryProtocol: Sendable {
    func fetch(filter: TransactionFilter) async throws -> [Transaction]
    func save(_ transaction: Transaction) async throws
    func delete(_ id: Transaction.ID) async throws
}

/// Implementation in FinanceData
actor TransactionRepository: TransactionRepositoryProtocol {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    // ...
}
```

## SwiftData Model Convention
```swift
@Model
final class TransactionEntity {
    var id: UUID
    var amount: Decimal  // ALWAYS Decimal
    var date: Date
    var note: String
    @Relationship var category: CategoryEntity?
    @Relationship var account: AccountEntity?
    var createdAt: Date
    var updatedAt: Date

    // Map to/from domain model
    func toDomain() -> Transaction { ... }
    static func from(_ domain: Transaction) -> TransactionEntity { ... }
}
```

## CloudKit Sync Rules
- No unique constraints (CloudKit doesn't support them)
- All properties should have default values
- Relationships must be optional
- Use `cloudKitContainerIdentifier` in ModelConfiguration
- Handle merge conflicts with last-write-wins or custom resolution
- Test with `CKContainer.default()` in development

## Migration Strategy
- Use `VersionedSchema` for schema versioning
- Lightweight migrations preferred
- For complex migrations, use `SchemaMigrationPlan`
- Always test migrations with existing data before release
- See `coredata-cloudkit` skill for detailed patterns

## Testing
- Use in-memory `ModelContainer` for unit tests
- Test CRUD operations, filtering, sorting
- Test migration paths between schema versions
- Run: `swift test --package-path Packages/FinanceData`
