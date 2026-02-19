# FEATURE-ACCOUNTS — F1.1 Account CRUD + F1.2 Multi-currency

## Feature Description

### User Stories
- As a user, I want to create and manage financial accounts (cash, bank, credit card, e-wallet, savings, investment, loan) so I can track where my money is.
- As a user, I want to see my total balance across all accounts, converted to my primary currency.
- As a user with multiple currencies, I want exchange rate conversion so I can see unified balances.

### Acceptance Criteria
- [ ] CRUD operations for accounts with validation (name uniqueness, free tier limit)
- [ ] Grouped display by account type with per-section subtotals
- [ ] Total balance across all accounts with multi-currency conversion
- [ ] Exchange rate fetching, caching, and offline fallback
- [ ] Reorder accounts within type groups (drag-to-reorder)
- [ ] Archive/hide accounts (soft delete, not hard delete)
- [ ] Balance adjustment with auto-created adjustment transaction
- [ ] iOS: full account list, edit, detail, and balance-adjust views
- [ ] macOS: sidebar accounts section, edit sheet, context menu
- [ ] VND formatting, compact notation, multi-currency pair display

---

## Current State & Impact Analysis

### What Already Exists (feature/transactions-f1 branch)

**FinanceCore (fully implemented):**
- `Account` model with all fields (id, name, type, currency, balance, icon, color, sortOrder, isHidden, isArchived, eWalletProvider, note, timestamps, deletedAt)
- `AccountType` enum (cash, bank, creditCard, eWallet, savings, investment, loan, other)
- `EWalletProvider` enum (momo, zalopay, vnpay, other)
- `CurrencyCode` enum with symbol, name, flag, decimalPlaces
- `ExchangeRate` model
- `CurrencyFormatter` (VND, USD, compact format, pair format)
- `AccountError` and `ExchangeRateError` enums
- `AccountRepositoryProtocol`, `ExchangeRateRepositoryProtocol`
- `CreateAccountUseCase`, `UpdateAccountUseCase`, `DeleteAccountUseCase`, `GetAccountsUseCase`, `ReorderAccountsUseCase`, `ExchangeRateUseCase`
- `AccountFilter` model
- Unit tests: 72+ account-related tests passing

**FinanceData (fully implemented):**
- `AccountEntity` with SwiftData @Model, CloudKit-compatible
- `AccountEntity+Mapping` (toDomain, update, from)
- `AccountRepository` (fetch, save, delete, updateBalance, fetchGroupedByType, fetchTotalBalance, updateSortOrders)
- `ExchangeRateEntity` + `ExchangeRateRepository`
- `ModelContainerSetup` with Account + ExchangeRate entities

**FinanceUI (fully implemented):**
- `AccountTypeBadge` — type badge with icon + label
- `BalanceText` — formatted amount with currency
- `CurrencyPicker` — searchable currency list
- `IconPicker` — SF Symbol grid picker
- `ColorPickerGrid` — hex color grid picker

**iOS (fully implemented):**
- `AccountListView` — grouped list with swipe actions, drag-to-reorder
- `AccountListViewModel` — MVVM with all use cases
- `AccountEditView` — create/edit form
- `AccountEditViewModel` — form state management
- `AccountDetailView` — balance card, income/expense summary
- `AccountDetailViewModel` — account detail + balance adjust
- `BalanceAdjustSheet` — balance adjustment UI

**macOS (fully implemented):**
- `MacAccountsView` — sidebar section with grouped accounts
- `MacAccountsSidebarSection` — sidebar display component
- `MacAccountDetailView` — detail pane
- `MacAccountEditView` — edit form in sheet
- `MacAccountContextMenu` — right-click menu

### Bugs Found (Code Review)

| # | Severity | Location | Issue |
|---|----------|----------|-------|
| 1 | **CRITICAL** | `AccountRepository.swift:77` | `fetchTotalBalance` ignores non-primary-currency accounts — only sums same-currency accounts instead of converting all |
| 2 | **CRITICAL** | `AccountListViewModel.swift:103`, `AccountDetailViewModel.swift:85`, `MacAccountsView.swift:166` | `hasTransactions: false` hardcoded in all delete calls — bypasses transaction guard |
| 3 | **CRITICAL** | `MacAccountsView.swift:24-28` | Repositories as computed `var` properties — creates new actor per access |
| 4 | **CRITICAL** | `ExchangeRateUseCase.swift:118` | `return 1.0` uses Double literal where Decimal is required |
| 5 | **CRITICAL** | `AccountEditViewModel.swift:149` | Unparseable balance silently becomes 0 with no user feedback |
| 6 | **WARNING** | `AccountListViewModel.swift:169` | Reorder within section overwrites global sortOrders causing cross-section collisions |
| 7 | **WARNING** | `MacAccountEditView.swift:165` | Currency picker not disabled in edit mode on macOS (iOS correctly disables it) |
| 8 | **WARNING** | `ExchangeRateRepository.swift:46` | Upsert keyed on `id` — fresh service rates always insert duplicates |
| 9 | **WARNING** | `CurrencyFormatter.swift:63` | Decimal→Double conversion in `formatCompact` loses precision for large VND amounts |
| 10 | **WARNING** | `AccountListViewModel.swift:86` | `executeTotalBalance` vs `executeGrouped` have inconsistent hidden-account semantics |
| 11 | **WARNING** | `BalanceAdjustSheet.swift:64` | Delta shown as raw `Decimal.description` instead of formatted currency |
| 12 | **WARNING** | `AccountDetailViewModel.swift:73` | `adjustBalance` silently swallows all errors |
| 13 | **WARNING** | `MockAccountRepository.swift:12` | Mock `fetchAll` doesn't filter soft-deleted accounts (diverges from production) |
| 14 | **WARNING** | `AccountListView.swift:191` | Dead code: `makeListViewModel()` factory never called |
| 15 | **WARNING** | `AccountListViewModel.swift:191` | `sectionBalance(for:)` sums mixed currencies without conversion |
| 16 | **SUGGESTION** | `IconPicker.swift:112` | `.searchable` gated to iOS only — macOS users can't search icons |
| 17 | **SUGGESTION** | `AccountTypeBadge.swift:39` | Accessibility label appends " account" unconditionally |
| 18 | **SUGGESTION** | `ExchangeRateUseCaseTests.swift:286` | MockExchangeRateService extension methods not async — Swift 6 strict-concurrency violation |
| 19 | **NOTE** | `CurrencyCode.swift:30,34` | JPY and CNY share `"¥"` symbol — ambiguous in pair formatting |
| 20 | **NOTE** | `AccountError.swift:57` | `ExchangeRateError.cacheExpired` unreachable dead code |

---

## Detailed Tasks

### Phase A: Critical Bug Fixes (shared-core + data-architect)

#### T1: Fix `fetchTotalBalance` to convert across currencies
- **Agent:** shared-core + data-architect
- **Complexity:** Medium
- **Files:**
  - `Packages/FinanceCore/Sources/FinanceCore/UseCases/GetAccountsUseCase.swift` — `executeTotalBalance` should accept `ExchangeRateUseCaseProtocol`, fetch ALL non-deleted non-archived non-hidden accounts, convert each balance to target currency, then sum
  - `Packages/FinanceCore/Sources/FinanceCore/Protocols/AccountRepositoryProtocol.swift` — keep `fetchTotalBalance` but clarify it's same-currency-only, or remove it entirely in favor of use-case-level computation
  - `Packages/FinanceData/Sources/FinanceData/Repositories/AccountRepository.swift` — update to match
  - `Packages/FinanceCore/Tests/` — update tests, fix MockAccountRepository.fetchTotalBalance

#### T2: Fix `sectionBalance(for:)` to handle mixed currencies
- **Agent:** ios-engineer
- **Complexity:** Medium
- **Files:**
  - `FinanceApp-iOS/Sources/Features/Accounts/AccountListViewModel.swift` — inject `ExchangeRateUseCaseProtocol`, convert each account balance to primary currency before summing per section

#### T3: Fix `hasTransactions` hardcoding in delete calls
- **Agent:** ios-engineer + macos-engineer
- **Complexity:** Low
- **Files:**
  - `FinanceApp-iOS/Sources/Features/Accounts/AccountListViewModel.swift:103` — query `TransactionRepositoryProtocol.count(filter:)` for account before delete
  - `FinanceApp-iOS/Sources/Features/Accounts/AccountDetailViewModel.swift:85` — same
  - `FinanceApp-macOS/Sources/Features/Accounts/MacAccountsView.swift:166` — same
- **Dependency:** Transaction repository must exist (already implemented in transactions-f1)

#### T4: Fix MacAccountsView computed-property repository creation
- **Agent:** macos-engineer
- **Complexity:** Medium
- **Files:**
  - `FinanceApp-macOS/Sources/Features/Accounts/MacAccountsView.swift` — extract to a proper ViewModel (`MacAccountsViewModel`) with stable repository references injected via init

#### T5: Fix ExchangeRateUseCase Double literal
- **Agent:** shared-core
- **Complexity:** Trivial
- **Files:**
  - `Packages/FinanceCore/Sources/FinanceCore/UseCases/ExchangeRateUseCase.swift:118` — change `return 1.0` to `return Decimal(1)`

#### T6: Fix ExchangeRateRepository upsert predicate
- **Agent:** data-architect
- **Complexity:** Low
- **Files:**
  - `Packages/FinanceData/Sources/FinanceData/Repositories/ExchangeRateRepository.swift:44-61` — remove `entity.id == rate.id` from predicate, match on `(baseCurrency, targetCurrency)` only, add date-same-day logic

### Phase B: Warning-Level Fixes (mixed agents)

#### T7: Fix CurrencyFormatter.formatCompact Decimal→Double conversion
- **Agent:** shared-core
- **Complexity:** Medium
- **Files:**
  - `Packages/FinanceCore/Sources/FinanceCore/Utilities/CurrencyFormatter.swift:63-85` — rewrite compact format to stay in Decimal arithmetic

#### T8: Fix AccountEditViewModel unparseable balance (silent 0)
- **Agent:** ios-engineer
- **Complexity:** Low
- **Files:**
  - `FinanceApp-iOS/Sources/Features/Accounts/AccountEditViewModel.swift` — add validation error when `Decimal(string:)` returns nil, surface in UI

#### T9: Fix reorder sortOrder collision across sections
- **Agent:** shared-core
- **Complexity:** Medium
- **Files:**
  - `Packages/FinanceCore/Sources/FinanceCore/UseCases/ReorderAccountsUseCase.swift` — accept `(type: AccountType, orderedIDs: [UUID])` and offset sortOrder by type to avoid collision, or use per-type sort namespace
  - `FinanceApp-iOS/Sources/Features/Accounts/AccountListViewModel.swift:169` — update call site

#### T10: Fix MacAccountEditView currency picker not disabled in edit mode
- **Agent:** macos-engineer
- **Complexity:** Trivial
- **Files:**
  - `FinanceApp-macOS/Sources/Features/Accounts/MacAccountEditView.swift:165-172` — add `.disabled(isEditing)` guard + explanatory text

#### T11: Fix BalanceAdjustSheet unformatted delta display
- **Agent:** ios-engineer
- **Complexity:** Trivial
- **Files:**
  - `FinanceApp-iOS/Sources/Features/Accounts/BalanceAdjustSheet.swift:64` — use `CurrencyFormatter`

#### T12: Fix AccountDetailViewModel silent error swallowing
- **Agent:** ios-engineer
- **Complexity:** Low
- **Files:**
  - `FinanceApp-iOS/Sources/Features/Accounts/AccountDetailViewModel.swift:73` — add `@Published var errorMessage: String?`, surface errors

#### T13: Fix MockAccountRepository.fetchAll to filter deleted accounts
- **Agent:** test-engineer
- **Complexity:** Trivial
- **Files:**
  - `Packages/FinanceCore/Tests/FinanceCoreTests/Mocks/MockAccountRepository.swift:12-14` — add `.filter { $0.deletedAt == nil }`

#### T14: Remove dead code `makeListViewModel()`
- **Agent:** ios-engineer
- **Complexity:** Trivial
- **Files:**
  - `FinanceApp-iOS/Sources/Features/Accounts/AccountListView.swift:191-205` — delete method

#### T15: Fix IconPicker .searchable gated to iOS only
- **Agent:** ui-designer
- **Complexity:** Trivial
- **Files:**
  - `Packages/FinanceUI/Sources/FinanceUI/Components/IconPicker.swift:110-113` — move `.searchable` outside `#if os(iOS)`

#### T16: Fix ExchangeRateUseCaseTests strict-concurrency violation
- **Agent:** test-engineer
- **Complexity:** Low
- **Files:**
  - `Packages/FinanceCore/Tests/FinanceCoreTests/ExchangeRateUseCaseTests.swift:286-294` — make extension methods `async` or move into actor body

### Phase C: Test Updates (test-engineer)

#### T17: Update tests to match all fixes
- **Agent:** test-engineer
- **Complexity:** Medium
- **Files:**
  - Update `GetAccountsUseCaseTests` — test multi-currency total balance
  - Update `ReorderAccountsUseCaseTests` — test per-type offset
  - Update `CurrencyFormatterTests` — test large VND amounts in compact format
  - Add `ExchangeRateRepositoryTests` — test upsert deduplication
  - Verify all 72+ existing tests still pass after fixes
- **Dependency:** All Phase A + B fixes complete

### Phase D: Run Full Test Suite + Final Verification

#### T18: Build verification and test run
- **Agent:** test-engineer
- **Complexity:** Low
- **Steps:**
  1. `swift test --package-path Packages/FinanceCore`
  2. `swift test --package-path Packages/FinanceData`
  3. `xcodebuild build` for iOS and macOS targets
  4. Verify all 289+ tests pass (FinanceCore + FinanceData)

---

## Implementation Order & Dependencies

```
Phase A (Critical Fixes):
  T5 (trivial)  ────────────────────────┐
  T6 (ExchangeRate upsert) ─────────────┤
  T1 (fetchTotalBalance) ← depends T5,T6│──► Phase C: T17
  T2 (sectionBalance) ← depends T1      │
  T3 (hasTransactions) ─────────────────┤
  T4 (MacAccountsView ViewModel) ───────┘

Phase B (Warning Fixes) — can run parallel to Phase A:
  T7 (formatCompact) ──────────┐
  T8 (balance validation) ─────┤
  T9 (reorder collision) ──────┤
  T10 (macOS currency guard) ──┤──► Phase C: T17
  T11 (delta display) ─────────┤
  T12 (error swallowing) ──────┤
  T13 (mock fetchAll) ─────────┤
  T14 (dead code) ─────────────┤
  T15 (searchable macOS) ──────┤
  T16 (test concurrency) ──────┘

Phase C (Tests): T17 ← depends on all A+B

Phase D (Verification): T18 ← depends on T17
```

## Agent Assignment Summary

| Agent | Tasks |
|-------|-------|
| **shared-core** | T1, T5, T7, T9 |
| **data-architect** | T1, T6 |
| **ios-engineer** | T2, T3, T8, T11, T12, T14 |
| **macos-engineer** | T3, T4, T10 |
| **ui-designer** | T15 |
| **test-engineer** | T13, T16, T17, T18 |

## Risks

1. **T1 (multi-currency total balance)** is the most complex fix — needs exchange rate integration into the use case layer. If exchange rates are unavailable (no API configured yet), must handle gracefully with fallback.
2. **T3 (hasTransactions check)** depends on `TransactionRepositoryProtocol` being available in the iOS/macOS targets. Since transactions feature was just implemented, this should work but needs verification.
3. **T4 (MacAccountsView → ViewModel)** is a significant refactor of the macOS accounts view architecture. Must preserve all existing functionality.
4. **T9 (reorder collision)** changes the `ReorderAccountsUseCase` protocol signature, which affects iOS ViewModel and tests.

## Test Plan

| Test Area | Cases |
|-----------|-------|
| Multi-currency total balance | VND-only sum, mixed VND+USD sum with conversion, no exchange rate fallback |
| Section balance | Same-currency section, mixed-currency section |
| Delete with transactions | Account with transactions → error, account without → success |
| Reorder within type | Reorder cash accounts doesn't affect bank accounts' sortOrder |
| ExchangeRate upsert | Save same pair twice → updates not duplicates |
| CurrencyFormatter compact | Large VND (999 billion) stays accurate |
| Balance validation | Empty string → error, "abc" → error, "0" → valid |
| MockAccountRepository | fetchAll excludes soft-deleted accounts |
