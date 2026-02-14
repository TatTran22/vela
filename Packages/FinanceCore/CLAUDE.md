# FinanceCore Module Context

## Purpose
Platform-agnostic business logic, domain models, protocols, and use cases. This module has NO dependencies on UIKit, AppKit, SwiftUI, or any platform framework. It MUST compile on all Apple platforms.

## Key Rules
- **Pure Swift only** — no `import SwiftUI`, `import UIKit`, or `import AppKit`
- **All monetary values use `Decimal`** — NEVER `Double` or `Float`
- **Value types preferred** — use `struct` and `enum` over `class`
- **Protocol-first design** — define protocols, then implementations
- **Sendable conformance** — all models must be `Sendable` for strict concurrency

## Domain Models
- `Transaction` — income, expense, transfer with amount, date, category, notes
- `Account` — cash, bank, credit card, investment, loan with balance
- `Category` — hierarchical (parent/child), with icon and color
- `Budget` — per-category or total, with period (weekly/monthly/yearly)
- `RecurringTransaction` — template for auto-generated transactions

## Use Case Pattern
```swift
/// Protocol definition
protocol GetTransactionsUseCaseProtocol: Sendable {
    func execute(filter: TransactionFilter) async throws -> [Transaction]
}

/// Implementation with repository dependency
struct GetTransactionsUseCase: GetTransactionsUseCaseProtocol {
    private let repository: TransactionRepositoryProtocol

    init(repository: TransactionRepositoryProtocol) {
        self.repository = repository
    }

    func execute(filter: TransactionFilter) async throws -> [Transaction] {
        try await repository.fetch(filter: filter)
    }
}
```

## Error Handling
- Define domain errors as enums conforming to `Error` and `Sendable`
- Use `throws` — never return optional to hide errors
- See `error-handling` skill for detailed patterns

## Testing
- All use cases must have unit tests
- Use protocol mocks for repository dependencies
- Test edge cases: zero amounts, negative balances, date boundaries
- Run: `swift test --package-path Packages/FinanceCore`
