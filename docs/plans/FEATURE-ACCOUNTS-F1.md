# Feature Accounts (F1.1 + F1.2) — Implementation Plan

## Context

The Accounts feature is the foundation of the FinanceApp — users need to create and manage financial accounts (cash, bank, credit card, e-wallet, savings) with multi-currency support (VND primary). The codebase has scaffolding in place (basic `Account` model, empty `AccountRepository`, placeholder views) but no working implementation. This plan builds the complete Accounts feature across all layers.

### Key Gaps Between Current Code and Spec
- `Account.currency` is `String`, needs to be `CurrencyCode` enum
- `AccountType.bankAccount` should be `.bank` per DATA-MODEL.md; `.loan` missing
- Missing fields: `balance`, `sortOrder`, `isHidden`, `note`, `eWalletProvider`, `deletedAt`
- `AccountRepository` is an empty shell
- No use case implementations exist
- All views are placeholders

---

## Phase 1: Foundation Models & Protocols (shared-core)

### 1.1 Add `CurrencyCode` enum [S]
**New**: `Packages/FinanceCore/Sources/FinanceCore/Models/CurrencyCode.swift`
- Cases: VND, USD, EUR, JPY, KRW, THB, SGD, AUD, GBP, CNY
- Conform to `String, Sendable, CaseIterable, Codable, Hashable`
- Properties: `symbol`, `name`, `decimalPlaces` (VND/JPY/KRW=0, others=2), `flag` (emoji)

### 1.2 Add `EWalletProvider` enum [S]
**New**: `Packages/FinanceCore/Sources/FinanceCore/Models/EWalletProvider.swift`
- Cases: momo, zalopay, vnpay, other
- Properties: `displayName`, `iconName`

### 1.3 Enhance `Account` model [M]
**Modify**: `Packages/FinanceCore/Sources/FinanceCore/Models/Account.swift`
- `currency: String` -> `currency: CurrencyCode`
- Add: `balance: Decimal`, `sortOrder: Int`, `isHidden: Bool`, `note: String?`, `eWalletProvider: EWalletProvider?`, `deletedAt: Date?`
- Rename `AccountType.bankAccount` -> `.bank`, add `.loan`

### 1.4 Add `ExchangeRate` model [S]
**New**: `Packages/FinanceCore/Sources/FinanceCore/Models/ExchangeRate.swift`
- Fields: id, baseCurrency, targetCurrency, rate (Decimal), date, source

### 1.5 Add `AccountRepositoryProtocol` [M]
**New**: `Packages/FinanceCore/Sources/FinanceCore/Protocols/AccountRepositoryProtocol.swift`
- Methods: `fetchAll`, `fetch(by:)`, `save`, `delete(by:)`, `fetchGroupedByType`, `fetchTotalBalance(in:)`, `updateBalance(_:delta:)`, `fetchActiveCount`, `updateSortOrders`

### 1.6 Add `ExchangeRateRepositoryProtocol` [S]
**New**: `Packages/FinanceCore/Sources/FinanceCore/Protocols/ExchangeRateRepositoryProtocol.swift`
- Methods: `fetchRate(from:to:date:)`, `saveRates`, `deleteOldRates(before:)`

### 1.7 Add domain error types [S]
**New**: `Packages/FinanceCore/Sources/FinanceCore/Models/AccountError.swift`
- `AccountError`: nameEmpty, nameAlreadyExists, freeTierLimitReached, cannotChangeCurrencyWithTransactions, cannotDeleteAccountWithTransactions, accountNotFound
- `ExchangeRateError`: rateNotFound, networkUnavailable, cacheExpired

---

## Phase 2: Use Cases & CurrencyFormatter (shared-core)

### 2.1 Enhance `CurrencyFormatter` [M]
**Modify**: `Packages/FinanceCore/Sources/FinanceCore/Utilities/CurrencyFormatter.swift`
- Accept `CurrencyCode` instead of `String`
- VND: `1.000.000 ₫` (dot separator, 0 decimals)
- USD: `$1,000.00`
- Add: `formatCompact` ("1.5tr", "150k"), `formatPair(amount:from:to:rate:)`, `formatWithoutSymbol`

### 2.2 Implement `CreateAccountUseCase` [M]
**New**: `Packages/FinanceCore/Sources/FinanceCore/UseCases/CreateAccountUseCase.swift`
- Validate: name not empty, unique name, free tier max 5 accounts
- Auto-assign sortOrder, set balance = initialBalance

### 2.3 Implement `UpdateAccountUseCase` [M]
**New**: `Packages/FinanceCore/Sources/FinanceCore/UseCases/UpdateAccountUseCase.swift`
- Validate name, block currency change if transactions exist
- Note: accept `hasTransactions: Bool` parameter until Transactions feature exists

### 2.4 Implement `DeleteAccountUseCase` [M]
**New**: `Packages/FinanceCore/Sources/FinanceCore/UseCases/DeleteAccountUseCase.swift`
- Block delete if has transactions -> suggest archive
- Soft delete via `deletedAt`

### 2.5 Implement `GetAccountsUseCase` [M]
**New**: `Packages/FinanceCore/Sources/FinanceCore/UseCases/GetAccountsUseCase.swift`
- Define `AccountFilter` (includeArchived, includeHidden, types)
- Methods: execute(filter), executeGrouped(filter), executeTotalBalance(in:)

### 2.6 Implement `ReorderAccountsUseCase` [S]
**New**: `Packages/FinanceCore/Sources/FinanceCore/UseCases/ReorderAccountsUseCase.swift`

### 2.7 Implement `ExchangeRateUseCase` [L]
**New**: `Packages/FinanceCore/Sources/FinanceCore/UseCases/ExchangeRateUseCase.swift`
- convert(amount, from, to), fetchLatestRates, 24h cache, offline fallback
- Define `ExchangeRateServiceProtocol` for network fetcher

### 2.8 Clean up `AccountUseCaseProtocol` [S]
**Modify**: `Packages/FinanceCore/Sources/FinanceCore/UseCases/AccountUseCases.swift`
- Remove facade protocol in favor of individual use case protocols

---

## Phase 3: Data Layer (data-architect)

### 3.1 Enhance `AccountEntity` [M]
**Modify**: `Packages/FinanceData/Sources/FinanceData/Entities/AccountEntity.swift`
- Add: balance, sortOrder, isHidden, note, eWalletProvider, deletedAt
- Add indexes: (type), (currency), (type, sortOrder), (deletedAt)

### 3.2 Add domain mapping functions [M]
**New**: `Packages/FinanceData/Sources/FinanceData/Entities/AccountEntity+Mapping.swift`
- `toDomain() -> Account`, `static from(domain:) -> AccountEntity`, `update(from:)`

### 3.3 Add `ExchangeRateEntity` [S]
**New**: `Packages/FinanceData/Sources/FinanceData/Entities/ExchangeRateEntity.swift`
- @Model with mapping functions

### 3.4 Implement `AccountRepositoryImpl` [L]
**Modify**: `Packages/FinanceData/Sources/FinanceData/Repositories/AccountRepository.swift`
- Conform to `AccountRepositoryProtocol`, use `@ModelActor`
- Implement all methods with `#Predicate`, `FetchDescriptor`
- Exclude soft-deleted records in all queries

### 3.5 Implement `ExchangeRateRepositoryImpl` [M]
**New**: `Packages/FinanceData/Sources/FinanceData/Repositories/ExchangeRateRepository.swift`

### 3.6 Update `ModelContainerSetup` [S]
**Modify**: `Packages/FinanceData/Sources/FinanceData/DataStack/ModelContainerSetup.swift`
- Register `ExchangeRateEntity` in schema

### 3.7 Implement `ExchangeRateServiceImpl` [M]
**New**: `Packages/FinanceData/Sources/FinanceData/Services/ExchangeRateService.swift`
- URLSession + async/await, parse JSON, handle errors

---

## Phase 4: UI Components (ui-designer)

### 4.1 `AccountIcon` [S]
**New**: `Packages/FinanceUI/Sources/FinanceUI/Components/AccountIcon.swift`
- SF Symbol in colored circle, default icons per AccountType
- Sizes: small/medium/large

### 4.2 `AccountTypeBadge` [S]
**New**: `Packages/FinanceUI/Sources/FinanceUI/Components/AccountTypeBadge.swift`
- Compact capsule label with icon + type name

### 4.3 `BalanceText` [S]
**New**: `Packages/FinanceUI/Sources/FinanceUI/Components/BalanceText.swift`
- Enhanced amount display with CurrencyCode, multiple sizes, compact mode

### 4.4 `AccountCard` [M]
**New**: `Packages/FinanceUI/Sources/FinanceUI/Components/AccountCard.swift`
- Combines AccountIcon + name + BalanceText + AccountTypeBadge
- Compact (list row) and expanded (detail header) layouts

### 4.5 `CurrencyPicker` [M]
**New**: `Packages/FinanceUI/Sources/FinanceUI/Components/CurrencyPicker.swift`
- Searchable list: flag + code + name + symbol
- `@Binding var selected: CurrencyCode`

### 4.6 Update `AmountText` [S]
**Modify**: `Packages/FinanceUI/Sources/FinanceUI/Components/AmountText.swift`
- Change `currencyCode: String` to `currencyCode: CurrencyCode`

---

## Phase 5: iOS Views & ViewModels (ios-engineer)

### 5.1 `AccountListViewModel` [L]
**New**: `FinanceApp-iOS/Sources/Features/Accounts/AccountListViewModel.swift`
- @Observable, state: groupedAccounts, totalBalance, isLoading, error, filter
- Actions: loadAccounts, deleteAccount, archiveAccount, toggleHidden, reorder

### 5.2 `AccountListView` [L]
**New**: `FinanceApp-iOS/Sources/Features/Accounts/AccountListView.swift` (replaces placeholder)
- Grouped List by AccountType, section subtotals, total balance
- Swipe actions (edit/archive/delete), drag-to-reorder, empty state

### 5.3 `AccountEditViewModel` [M]
**New**: `FinanceApp-iOS/Sources/Features/Accounts/AccountEditViewModel.swift`

### 5.4 `AccountEditView` [M]
**New**: `FinanceApp-iOS/Sources/Features/Accounts/AccountEditView.swift`
- Form: name, type, currency, initial balance, icon, color, e-wallet provider, notes

### 5.5 `AccountDetailViewModel` [M]
**New**: `FinanceApp-iOS/Sources/Features/Accounts/AccountDetailViewModel.swift`

### 5.6 `AccountDetailView` [M]
**New**: `FinanceApp-iOS/Sources/Features/Accounts/AccountDetailView.swift`
- Balance card, income/expense summary, transaction list placeholder

### 5.7 `BalanceAdjustSheet` [S]
**New**: `FinanceApp-iOS/Sources/Features/Accounts/BalanceAdjustSheet.swift`

### 5.8 Wire up navigation [S]
**Modify**: `FinanceApp-iOS/Sources/App/ContentView.swift`
- Replace placeholder, set up DI composition root
- Delete `AccountsPlaceholderView.swift`

---

## Phase 6: macOS Views (macos-engineer)

### 6.1 `MacAccountsSidebarSection` [M]
**New**: `FinanceApp-macOS/Sources/Features/Accounts/MacAccountsSidebarSection.swift`
- Disclosure groups per AccountType, icon + name + compact balance

### 6.2 `MacAccountDetailView` [M]
**New**: `FinanceApp-macOS/Sources/Features/Accounts/MacAccountDetailView.swift`
- Dense desktop layout, balance card, summary, transaction table placeholder

### 6.3 `MacAccountEditView` [M]
**New**: `FinanceApp-macOS/Sources/Features/Accounts/MacAccountEditView.swift`
- macOS form layout, reuse AccountEditViewModel

### 6.4 Context menu & shortcuts [S]
**New**: `FinanceApp-macOS/Sources/Features/Accounts/MacAccountContextMenu.swift`
- Right-click: Edit, Archive, Hide, View Transactions
- Keyboard: Cmd+N, Delete, Cmd+E

### 6.5 Wire up macOS navigation [S]
**Modify**: `FinanceApp-macOS/Sources/App/MacContentView.swift`
- Replace placeholder, integrate sidebar section

---

## Phase 7: Tests (test-engineer)

### 7.1 `CreateAccountUseCaseTests` [M]
- Valid creation, empty name, duplicate name, free tier limit (5), sortOrder
- Create `MockAccountRepository`

### 7.2 `DeleteAccountUseCaseTests` [M]
- Delete empty account, block with transactions, archive fallback

### 7.3 Enhance `CurrencyFormatterTests` [M]
- VND format, USD format, compact ("1.5tr", "150k"), formatPair, edge cases

### 7.4 `ExchangeRateUseCaseTests` [M]
- Conversion accuracy, offline fallback, cache expiry

### 7.5 `AccountBalanceTests` [M]
- Delta updates, total balance sum, mixed currency totals

### 7.6 `AccountRepositoryImplTests` [M]
- In-memory ModelContainer, CRUD, grouped fetch, soft delete exclusion

### 7.7 Update existing `AccountTests` [S]
- Update for CurrencyCode, new fields, EWalletProvider

---

## Execution Schedule

```
         shared-core    data-architect    ui-designer    ios-engineer    macos-engineer    test-engineer
Week 1   Phase 1 + 2.1  3.1, 3.2, 3.3    4.1-4.3,       -               -                 -
                                          4.5, 4.6
Week 2   2.2-2.8        3.4-3.7           4.4            -               -                 7.3, 7.7
Week 3   -              -                 -              5.1-5.8         6.1-6.5           7.1, 7.2, 7.4-7.6
```

**Parallel tracks**: Phases 1-4 have independent agents working simultaneously. Phases 5+6 run in parallel (iOS/macOS). Tests run as implementations land.

---

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| SwiftData `Decimal` precision loss for large VND | Data corruption | Test with 1B+ VND early; fallback to `Int64` storage |
| `@ModelActor` strict concurrency complexity | Build errors | Follow SwiftData actor isolation patterns carefully |
| Transaction dependency (several use cases need it) | Blocked logic | Define minimal `hasTransactions(forAccountID:)` protocol; return `false` initially |
| Exchange rate API reliability | Feature degradation | Robust caching, offline fallback, bundled static fallback rates |
| AccountType rename (`bankAccount` -> `bank`) | Data migration | Pre-launch = clean break OK; add mapping in entity layer |
| Free tier limit race condition (multi-device) | Over-limit accounts | Soft warning on sync reconciliation rather than hard block |

---

## Verification

1. **Unit tests**: `swift test --package-path Packages/FinanceCore && swift test --package-path Packages/FinanceData`
2. **Build**: `xcodebuild -scheme FinanceApp-iOS -destination 'platform=iOS Simulator,name=iPhone 16'` and macOS equivalent
3. **Manual testing**:
   - Create accounts of each type (cash, bank, credit card, e-wallet, savings)
   - Verify VND formatting (1.000.000 ₫)
   - Test free tier limit (create 6th account -> error)
   - Test archive flow (account with transactions can't delete)
   - Test multi-currency total balance
   - Verify macOS sidebar, context menus, keyboard shortcuts
4. **Lint**: `swiftlint lint --strict`
