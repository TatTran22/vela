# Feature Plan: Transactions (F1.3 + F1.4 + F1.5)

> **Status**: Draft
> **Created**: 2026-02-19
> **Features**: F1.3 Nhập giao dịch thủ công, F1.4 Danh sách & tìm kiếm, F1.5 Chuyển khoản

---

## 1. Feature Description

### User Stories

**F1.3 — Nhập giao dịch thủ công**
> Là người dùng, tôi muốn nhập giao dịch thu/chi nhanh chóng (< 5 giây) để ghi nhận mọi khoản tiền ra/vào.

**F1.4 — Danh sách & tìm kiếm**
> Là người dùng, tôi muốn xem danh sách giao dịch theo ngày, lọc theo nhiều tiêu chí, và tìm kiếm bằng từ khóa để dễ dàng tra cứu lịch sử chi tiêu.

**F1.5 — Chuyển khoản giữa tài khoản**
> Là người dùng, tôi muốn ghi nhận chuyển khoản giữa các tài khoản (kể cả khác đồng tiền) để số dư luôn chính xác.

### Acceptance Criteria

#### F1.3 — Transaction Input
- [ ] Nhập giao dịch income/expense với amount, category, account, date, note
- [ ] Amount luôn > 0, type xác định hướng (income/expense)
- [ ] Quick input: mở app -> nhập -> save < 5 giây
- [ ] Custom numpad với phím `k` (×1.000) và `tr` (×1.000.000)
- [ ] Calculator mode: "150k + 200k" = 350.000
- [ ] Quick category picker: top 6 recent + "Xem tất cả"
- [ ] Optional: note, tags, receipt camera, date picker, location
- [ ] Balance tài khoản tự động cập nhật khi save (atomic)
- [ ] Edit/update giao dịch đã tạo
- [ ] Tags: tạo mới và gán tag vào giao dịch

#### F1.4 — Transaction List & Search
- [ ] Danh sách giao dịch grouped by date (Hôm nay, Hôm qua, dd/MM/yyyy)
- [ ] Daily income/expense totals trong header mỗi nhóm
- [ ] Pull-to-refresh
- [ ] Swipe-to-delete (soft delete), swipe-to-edit
- [ ] Search bar: full-text tìm theo note, category name, tag name
- [ ] Filter sheet: accounts, categories, date range, amount range, tags
- [ ] Pagination cho danh sách lớn (> 100 giao dịch)
- [ ] Search 10K giao dịch < 200ms

#### F1.5 — Transfer
- [ ] Chọn tài khoản nguồn và đích
- [ ] Same-currency: trừ nguồn, cộng đích (cùng amount)
- [ ] Cross-currency: nhập tỷ giá, tính amount đích, lưu rate trong metadata
- [ ] Transfer KHÔNG tính income/expense trong báo cáo
- [ ] Hiển thị phí chuyển khoản (optional)

---

## 2. Impact Analysis

### Modules cần thay đổi

| Module | Scope | Complexity |
|--------|-------|------------|
| **FinanceCore** | Models, protocols, use cases, utilities | High |
| **FinanceData** | Entities, repository implementations | High |
| **FinanceUI** | 5 shared components mới | Medium |
| **FinanceApp-iOS** | 4 screens mới, replace placeholder | High |
| **FinanceApp-macOS** | 3 screens mới, replace placeholder | Medium |

### Dependencies
- **Requires**: Account feature (done), Category feature (cần làm đồng thời hoặc trước)
- **Blocked by**: Không (Category models đã có, chỉ cần repository + seeding)

### Quan trọng: Category dependency
Transaction cần Category để hoạt động. Cần ít nhất:
1. `CategoryRepositoryProtocol` + implementation
2. `CategoryEntity` (SwiftData)
3. Default category seeding (VN expense/income categories)
4. Basic category picker UI

**Recommendation**: Build Category data layer (tasks C1-C4) trước hoặc song song với Transaction core.

---

## 3. Detailed Tasks

### Phase A: Domain Layer (FinanceCore)

#### T1: Update Transaction model + add Tag model
**Agent**: shared-core | **Complexity**: Medium | **Est**: 2-3 hours

Update `Transaction.swift`:
- Add missing fields: `tags: [UUID]`, `latitude: Double?`, `longitude: Double?`, `metadata: [String: String]?`, `deletedAt: Date?`
- Make `categoryID` non-optional (required for income/expense)
- Add `Codable` conformance

Create `Tag.swift`:
- id: UUID, name: String, color: String?, createdAt: Date
- `Sendable`, `Hashable`, `Codable`

Create `TransactionError.swift`:
- `amountMustBePositive`, `accountNotFound`, `categoryRequired`, `categoryTypeMismatch`, `sourceAndDestinationSame`, `destinationAccountRequired`, `transactionNotFound`, `exchangeRateRequired`

**Files**:
- Edit: `Packages/FinanceCore/Sources/FinanceCore/Models/Transaction.swift`
- New: `Packages/FinanceCore/Sources/FinanceCore/Models/Tag.swift`
- New: `Packages/FinanceCore/Sources/FinanceCore/Models/TransactionError.swift`

---

#### T2: TransactionFilter model
**Agent**: shared-core | **Complexity**: Low | **Est**: 1 hour

Create `TransactionFilter.swift`:
- `accountIDs: [UUID]?`
- `categoryIDs: [UUID]?`
- `dateRange: ClosedRange<Date>?`
- `amountRange: ClosedRange<Decimal>?`
- `tagIDs: [UUID]?`
- `searchText: String?`
- `types: [TransactionType]?`
- `excludeTransfers: Bool`
- Convenience: `.today`, `.thisWeek`, `.thisMonth`, `.forAccount(UUID)`

**Files**:
- New: `Packages/FinanceCore/Sources/FinanceCore/Models/TransactionFilter.swift`

---

#### T3: TransactionRepositoryProtocol + TagRepositoryProtocol
**Agent**: shared-core | **Complexity**: Medium | **Est**: 1-2 hours

`TransactionRepositoryProtocol`:
- `fetch(filter: TransactionFilter, offset: Int, limit: Int) async throws -> [Transaction]`
- `fetchGroupedByDate(filter: TransactionFilter) async throws -> [(Date, [Transaction])]`
- `fetch(by id: UUID) async throws -> Transaction?`
- `save(_ transaction: Transaction) async throws`
- `update(_ transaction: Transaction) async throws`
- `delete(by id: UUID) async throws` (soft delete)
- `count(filter: TransactionFilter) async throws -> Int`
- `dailyTotals(filter: TransactionFilter) async throws -> [(date: Date, income: Decimal, expense: Decimal)]`

`TagRepositoryProtocol`:
- `fetchAll() async throws -> [Tag]`
- `save(_ tag: Tag) async throws`
- `delete(by id: UUID) async throws`

`CategoryRepositoryProtocol` (needed):
- `fetchAll(type: TransactionType?) async throws -> [Category]`
- `fetch(by id: UUID) async throws -> Category?`
- `fetchTopLevel(type: TransactionType) async throws -> [Category]`
- `fetchChildren(of parentID: UUID) async throws -> [Category]`
- `save(_ category: Category) async throws`
- `seedDefaults() async throws`

**Files**:
- New: `Packages/FinanceCore/Sources/FinanceCore/Protocols/TransactionRepositoryProtocol.swift`
- New: `Packages/FinanceCore/Sources/FinanceCore/Protocols/TagRepositoryProtocol.swift`
- New: `Packages/FinanceCore/Sources/FinanceCore/Protocols/CategoryRepositoryProtocol.swift`

---

#### T4: CreateTransactionUseCase
**Agent**: shared-core | **Complexity**: High | **Est**: 3-4 hours

Business logic:
1. Validate amount > 0
2. Validate account exists (via AccountRepository)
3. Validate category exists + matches type (income category for income tx)
4. For transfer: validate toAccount exists, source != destination
5. Save transaction
6. Update account balance atomically:
   - Income: account.balance += amount
   - Expense: account.balance -= amount
   - Transfer: source.balance -= amount, destination.balance += amount
7. Cross-currency transfer: validate exchangeRate in metadata, convert amount

**Files**:
- New: `Packages/FinanceCore/Sources/FinanceCore/UseCases/CreateTransactionUseCase.swift`

---

#### T5: GetTransactionsUseCase
**Agent**: shared-core | **Complexity**: Medium | **Est**: 2 hours

- Fetch with filter, pagination
- Group by date with daily totals (income/expense per day)
- Sort by date descending (newest first)

**Files**:
- New: `Packages/FinanceCore/Sources/FinanceCore/UseCases/GetTransactionsUseCase.swift`

---

#### T6: UpdateTransactionUseCase + DeleteTransactionUseCase
**Agent**: shared-core | **Complexity**: High | **Est**: 3 hours

**Update**:
- If amount/type/account changes, reverse old balance + apply new balance
- If category changes, validate new category matches type
- Update `updatedAt`

**Delete** (soft):
- Reverse balance adjustment
- Set `deletedAt`
- For transfer: reverse both accounts

**Files**:
- New: `Packages/FinanceCore/Sources/FinanceCore/UseCases/UpdateTransactionUseCase.swift`
- New: `Packages/FinanceCore/Sources/FinanceCore/UseCases/DeleteTransactionUseCase.swift`

---

#### T7: QuickAmountParser utility
**Agent**: shared-core | **Complexity**: Medium | **Est**: 2-3 hours

Parse VND shorthand:
- `"150k"` → 150_000
- `"1.5tr"` → 1_500_000
- `"2m"` → 2_000_000
- `"150k + 200k"` → 350_000 (calculator)
- `"1tr - 200k"` → 800_000
- `"50k * 3"` → 150_000
- Handle edge cases: empty, negative result, overflow

**Files**:
- New: `Packages/FinanceCore/Sources/FinanceCore/Utilities/QuickAmountParser.swift`

---

#### T8: TransactionSearchUseCase
**Agent**: shared-core | **Complexity**: Medium | **Est**: 2 hours

Full-text search:
- Search in: note, category name (need lookup), tag names
- Vietnamese diacritics: "an uong" matches "ăn uống"
- Case-insensitive
- Return matched transactions sorted by relevance (exact match first) then by date

**Files**:
- New: `Packages/FinanceCore/Sources/FinanceCore/UseCases/TransactionSearchUseCase.swift`
- New: `Packages/FinanceCore/Sources/FinanceCore/Utilities/VietnameseTextNormalizer.swift`

---

### Phase B: Data Layer (FinanceData)

#### T9: TransactionEntity + TagEntity + CategoryEntity
**Agent**: data-architect | **Complexity**: High | **Est**: 3-4 hours

`TransactionEntity` (@Model):
- All fields from Transaction domain model
- String-based enums for CloudKit compatibility
- Indexes: `date`, `categoryID`, `accountID`
- Compound indexes: `(accountID, date)`, `(categoryID, date)`
- `toDomain()`, `update(from:)`, `from(domain:)` mapping methods

`TagEntity` (@Model):
- id, name, color, createdAt
- Many-to-many with Transaction (via junction or array)

`CategoryEntity` (@Model):
- id, name, iconName, colorHex, typeRawValue, parentID, sortOrder, isDefault, createdAt
- Relationship: parent/children hierarchy

Update `ModelContainerSetup`:
- Register new entities in ModelContainer schema

**Files**:
- New: `Packages/FinanceData/Sources/FinanceData/Entities/TransactionEntity.swift`
- New: `Packages/FinanceData/Sources/FinanceData/Entities/TransactionEntity+Mapping.swift`
- New: `Packages/FinanceData/Sources/FinanceData/Entities/TagEntity.swift`
- New: `Packages/FinanceData/Sources/FinanceData/Entities/TagEntity+Mapping.swift`
- New: `Packages/FinanceData/Sources/FinanceData/Entities/CategoryEntity.swift`
- New: `Packages/FinanceData/Sources/FinanceData/Entities/CategoryEntity+Mapping.swift`
- Edit: `Packages/FinanceData/Sources/FinanceData/DataStack/ModelContainerSetup.swift`

---

#### T10: TransactionRepository + TagRepository + CategoryRepository
**Agent**: data-architect | **Complexity**: High | **Est**: 4-5 hours

`TransactionRepository` (@ModelActor):
- Implement all TransactionRepositoryProtocol methods
- Efficient date-grouped fetch using SortDescriptor + manual grouping
- Pagination with offset/limit
- Full-text search using NSPredicate/`#Predicate`
- Batch insert support (cho future import feature)
- Filter out soft-deleted records

`TagRepository` (@ModelActor):
- Basic CRUD

`CategoryRepository` (@ModelActor):
- CRUD + hierarchy support
- `seedDefaults()`: insert VN default categories if empty
- Fetch with parent-child grouping

**Files**:
- New: `Packages/FinanceData/Sources/FinanceData/Repositories/TransactionRepository.swift`
- New: `Packages/FinanceData/Sources/FinanceData/Repositories/TagRepository.swift`
- New: `Packages/FinanceData/Sources/FinanceData/Repositories/CategoryRepository.swift`
- New: `Packages/FinanceData/Sources/FinanceData/Seed/DefaultCategories.swift`

---

### Phase C: Shared UI Components (FinanceUI)

#### T11: TransactionRow component
**Agent**: ui-designer | **Complexity**: Medium | **Est**: 2 hours

- Category icon (colored circle) + category name
- Note text (secondary)
- Amount with color: green (+) income, red (-) expense, blue (↔) transfer
- Account name (small text)
- Accessibility: VoiceOver labels with full context

**Files**:
- New: `Packages/FinanceUI/Sources/FinanceUI/Components/TransactionRow.swift`

---

#### T12: QuickNumpad component
**Agent**: ui-designer | **Complexity**: High | **Est**: 4-5 hours

Custom numpad replacing system keyboard:
- Digits 0-9, decimal separator
- `k` button (×1.000), `tr` button (×1.000.000)
- Backspace, clear
- `+`, `-`, `×` for calculator mode
- `=` or auto-calculate
- Display current expression + result
- Haptic feedback
- Accessibility support

**Files**:
- New: `Packages/FinanceUI/Sources/FinanceUI/Components/QuickNumpad.swift`

---

#### T13: TransactionFilterSheet component
**Agent**: ui-designer | **Complexity**: Medium | **Est**: 2-3 hours

Filter UI:
- Account multi-select
- Category multi-select (grouped by parent)
- Date range picker (preset: today, this week, this month, custom)
- Amount range (min/max input)
- Tag multi-select
- Type filter (income/expense/transfer)
- Clear all / Apply buttons
- Active filter count badge

**Files**:
- New: `Packages/FinanceUI/Sources/FinanceUI/Components/TransactionFilterSheet.swift`

---

#### T14: DateGroupHeader component
**Agent**: ui-designer | **Complexity**: Low | **Est**: 1 hour

- "Hôm nay" / "Hôm qua" / "Thứ Hai, 10/02/2026"
- Daily totals: income (+) and expense (-) on right side
- Sticky header behavior (managed by parent list)

**Files**:
- New: `Packages/FinanceUI/Sources/FinanceUI/Components/DateGroupHeader.swift`

---

#### T15: CategoryPicker component
**Agent**: ui-designer | **Complexity**: Medium | **Est**: 2-3 hours

- Grid layout: top 6 recently used categories
- "Xem tất cả" button → full category list grouped by parent
- Icon + name for each category
- Separate grids for income vs expense categories
- Search within full list

**Files**:
- New: `Packages/FinanceUI/Sources/FinanceUI/Components/CategoryPicker.swift`

---

### Phase D: iOS App

#### T16: TransactionListView + ViewModel
**Agent**: ios-engineer | **Complexity**: High | **Est**: 5-6 hours

`TransactionListViewModel` (@Observable, @MainActor):
- State: groupedTransactions, filter, searchText, isLoading, error, hasMore
- Load transactions paginated (50 per page)
- Apply filters
- Search debounce (300ms)
- Delete transaction (swipe)
- Refresh

`TransactionListView`:
- LazyVStack grouped by date (DateGroupHeader + TransactionRow)
- Search bar (always visible at top)
- Filter button in toolbar → TransactionFilterSheet
- Pull-to-refresh
- Swipe actions: delete (trailing), edit (leading)
- Infinite scroll pagination
- Empty state: "Chưa có giao dịch nào"
- FAB "+" button → QuickInputView

Replace `TransactionsPlaceholderView`.

**Files**:
- New: `FinanceApp-iOS/Sources/Features/Transactions/TransactionListView.swift`
- New: `FinanceApp-iOS/Sources/Features/Transactions/TransactionListViewModel.swift`
- Delete: `FinanceApp-iOS/Sources/Features/Transactions/TransactionsPlaceholderView.swift`
- Edit: `FinanceApp-iOS/Sources/ContentView.swift` (update tab navigation)

---

#### T17: QuickInputView (Transaction Entry) + ViewModel
**Agent**: ios-engineer | **Complexity**: High | **Est**: 6-8 hours

3-step flow:
1. **Amount**: QuickNumpad, expression display, income/expense toggle
2. **Category**: CategoryPicker (top 6 recent + full list)
3. **Review**: Amount + Category + Account + Date, [Save] + [Thêm chi tiết]

"Thêm chi tiết" expands:
- Note text field
- Tag picker (create + select)
- Date picker
- Account selector
- Receipt camera button (UI only, implementation in Phase 3)
- Location toggle

`QuickInputViewModel` (@Observable, @MainActor):
- State: amount expression, selected category, selected account, date, note, tags
- Actions: parseAmount, selectCategory, save, switchType
- Validation before save
- Call CreateTransactionUseCase

**Files**:
- New: `FinanceApp-iOS/Sources/Features/Transactions/QuickInputView.swift`
- New: `FinanceApp-iOS/Sources/Features/Transactions/QuickInputViewModel.swift`

---

#### T18: TransactionDetailView + Edit
**Agent**: ios-engineer | **Complexity**: Medium | **Est**: 3-4 hours

- Full transaction detail display
- Edit mode: modify any field
- Delete button with confirmation
- Call UpdateTransactionUseCase / DeleteTransactionUseCase

**Files**:
- New: `FinanceApp-iOS/Sources/Features/Transactions/TransactionDetailView.swift`
- New: `FinanceApp-iOS/Sources/Features/Transactions/TransactionDetailViewModel.swift`

---

#### T19: TransferView
**Agent**: ios-engineer | **Complexity**: Medium | **Est**: 3-4 hours

- Source account picker
- Destination account picker
- Amount input (QuickNumpad)
- Cross-currency: show exchange rate input, calculated destination amount
- Fee input (optional)
- Date, note
- Save → CreateTransactionUseCase with type = .transfer

**Files**:
- New: `FinanceApp-iOS/Sources/Features/Transactions/TransferView.swift`
- New: `FinanceApp-iOS/Sources/Features/Transactions/TransferViewModel.swift`

---

### Phase E: macOS App

#### T20: MacTransactionsView (Table)
**Agent**: macos-engineer | **Complexity**: Medium | **Est**: 4-5 hours

- Table view with sortable columns: Date, Category, Note, Amount, Account
- Filter toolbar (similar to iOS filter but inline)
- Search field in toolbar
- Multi-select rows
- Bulk actions: delete, change category, add tag
- Right-click context menu: edit, delete, duplicate
- Double-click → edit sheet

Replace `MacTransactionsPlaceholderView`.

**Files**:
- New: `FinanceApp-macOS/Sources/Features/Transactions/MacTransactionsView.swift`
- New: `FinanceApp-macOS/Sources/Features/Transactions/MacTransactionsViewModel.swift`
- Delete: `FinanceApp-macOS/Sources/Features/Transactions/MacTransactionsPlaceholderView.swift`
- Edit: `FinanceApp-macOS/Sources/MacContentView.swift` (update sidebar navigation)

---

#### T21: Mac Quick Entry + Transfer
**Agent**: macos-engineer | **Complexity**: Medium | **Est**: 3-4 hours

- ⌘N → floating sheet or popover for quick transaction entry
- Form-based layout (not step-by-step like iOS)
- All fields visible: amount, type, category, account, date, note, tags
- Transfer mode: source + destination + rate
- Keyboard-friendly: tab between fields, Enter to save

**Files**:
- New: `FinanceApp-macOS/Sources/Features/Transactions/MacTransactionEntryView.swift`
- New: `FinanceApp-macOS/Sources/Features/Transactions/MacTransactionEntryViewModel.swift`

---

#### T22: Drag & Drop receipt + Bulk actions
**Agent**: macos-engineer | **Complexity**: Low | **Est**: 2 hours

- Drag image from Finder → attach to transaction (store as receiptImageData)
- Bulk delete, bulk category change, bulk tag add from multi-select

**Files**:
- Edit: `FinanceApp-macOS/Sources/Features/Transactions/MacTransactionsView.swift`

---

### Phase F: Tests

#### T23: Transaction Use Case tests
**Agent**: test-engineer | **Complexity**: High | **Est**: 5-6 hours

Create mocks:
- `MockTransactionRepository`
- `MockCategoryRepository`
- `MockTagRepository`

Test cases:
- **CreateTransaction**: valid income, valid expense, amount <= 0, missing category, category type mismatch, balance update (income adds, expense subtracts), transfer both accounts updated, cross-currency rate applied
- **UpdateTransaction**: amount change reverses old + applies new, type change, account change
- **DeleteTransaction**: balance reversal (income, expense, transfer)
- **GetTransactions**: grouped by date, filtered, paginated, empty result

**Files**:
- New: `Packages/FinanceCore/Tests/FinanceCoreTests/CreateTransactionUseCaseTests.swift`
- New: `Packages/FinanceCore/Tests/FinanceCoreTests/UpdateTransactionUseCaseTests.swift`
- New: `Packages/FinanceCore/Tests/FinanceCoreTests/DeleteTransactionUseCaseTests.swift`
- New: `Packages/FinanceCore/Tests/FinanceCoreTests/GetTransactionsUseCaseTests.swift`
- New: `Packages/FinanceCore/Tests/FinanceCoreTests/Mocks/MockTransactionRepository.swift`
- New: `Packages/FinanceCore/Tests/FinanceCoreTests/Mocks/MockCategoryRepository.swift`
- New: `Packages/FinanceCore/Tests/FinanceCoreTests/Mocks/MockTagRepository.swift`

---

#### T24: QuickAmountParser tests
**Agent**: test-engineer | **Complexity**: Medium | **Est**: 2 hours

Test cases:
- Plain numbers: "150000" → 150_000
- k suffix: "150k" → 150_000, "1.5k" → 1_500
- tr suffix: "1tr" → 1_000_000, "1.5tr" → 1_500_000
- m suffix: "2m" → 2_000_000
- Expressions: "150k + 200k" → 350_000, "1tr - 200k" → 800_000, "50k * 3" → 150_000
- Edge: empty string → error, "0k" → 0, negative result → error
- Whitespace handling: "150 k" → 150_000

**Files**:
- New: `Packages/FinanceCore/Tests/FinanceCoreTests/QuickAmountParserTests.swift`

---

#### T25: TransactionFilter + Search tests
**Agent**: test-engineer | **Complexity**: Medium | **Est**: 2 hours

- Filter by single criterion, multiple criteria combined
- Date range boundary (inclusive)
- Search: partial match, case-insensitive
- Vietnamese diacritics: "an uong" matches "Ăn uống"
- Empty search returns all

**Files**:
- New: `Packages/FinanceCore/Tests/FinanceCoreTests/TransactionFilterTests.swift`
- New: `Packages/FinanceCore/Tests/FinanceCoreTests/TransactionSearchTests.swift`

---

#### T26: Data layer tests
**Agent**: test-engineer | **Complexity**: Medium | **Est**: 3 hours

- TransactionRepository CRUD
- Date-grouped fetch correctness
- Filter queries
- Soft delete behavior
- CategoryRepository seed defaults
- TagRepository CRUD

**Files**:
- New: `Packages/FinanceData/Tests/FinanceDataTests/TransactionRepositoryTests.swift`
- New: `Packages/FinanceData/Tests/FinanceDataTests/CategoryRepositoryTests.swift`
- New: `Packages/FinanceData/Tests/FinanceDataTests/TagRepositoryTests.swift`

---

## 4. Implementation Order

```
Phase A: Domain (FinanceCore)              Phase B: Data (FinanceData)
──────────────────────────                 ──────────────────────────
T1: Models (Transaction, Tag, Errors) ─┐
T2: TransactionFilter                  ├──► T9: Entities (SwiftData)
T3: Repository Protocols              ─┘       │
     │                                          ▼
     ▼                                     T10: Repository Implementations
T7: QuickAmountParser (parallel)              │
T4: CreateTransactionUseCase ◄────────────────┘
T5: GetTransactionsUseCase
T6: Update/DeleteTransactionUseCase
T8: TransactionSearchUseCase

Phase C: UI Components (FinanceUI)     Phase D: iOS App
──────────────────────────────         ────────────────
T11: TransactionRow       ──┐          T16: TransactionListView ◄──┐
T14: DateGroupHeader      ──┤               │                      │
T15: CategoryPicker       ──┼──────────► T17: QuickInputView    ◄──┤
T12: QuickNumpad          ──┤           T18: TransactionDetailView │
T13: TransactionFilterSheet─┘           T19: TransferView          │
                                                                    │
Phase E: macOS App                     Phase F: Tests               │
──────────────                         ─────────────                │
T20: MacTransactionsView ◄─────────── T23: Use Case tests ─────────┘
T21: Mac Quick Entry                   T24: QuickAmountParser tests
T22: Drag & Drop                       T25: Filter/Search tests
                                       T26: Data layer tests
```

### Recommended Build Sequence

| Order | Tasks | Can Parallel? | Dependencies |
|-------|-------|---------------|--------------|
| 1 | T1, T2, T3 | Yes (all 3) | None |
| 2 | T7 | Yes (with step 1) | None |
| 3 | T9 | No | T1, T2, T3 |
| 4 | T10 | No | T3, T9 |
| 5 | T4, T5, T6, T8 | Yes (all 4) | T3, T10 |
| 6 | T11, T12, T13, T14, T15 | Yes (all 5) | T1 (models only) |
| 7 | T23, T24, T25 | Yes (all 3) | T4-T8 |
| 8 | T16, T17, T18, T19 | Sequential | T4-T8, T11-T15 |
| 9 | T20, T21, T22 | Sequential | T4-T8 |
| 10 | T26 | Yes (with step 8) | T10 |

---

## 5. Agent Assignment Summary

| Agent | Tasks | Total Est. Hours |
|-------|-------|-----------------|
| **shared-core** | T1, T2, T3, T4, T5, T6, T7, T8 | 16-20h |
| **data-architect** | T9, T10 | 7-9h |
| **ui-designer** | T11, T12, T13, T14, T15 | 11-14h |
| **ios-engineer** | T16, T17, T18, T19 | 17-22h |
| **macos-engineer** | T20, T21, T22 | 9-11h |
| **test-engineer** | T23, T24, T25, T26 | 12-13h |
| **Total** | **26 tasks** | **~72-89h** |

---

## 6. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Balance atomicity**: race condition khi update balance song song | High | Use `@ModelActor` serial access; wrap save+balance in single transaction |
| **Category dependency**: Transaction cần Category data sẵn có | High | Build Category repository + seed defaults trước (T3, T9, T10) |
| **QuickNumpad complexity**: custom keyboard trên iOS khó test | Medium | Tách parser logic (T7) khỏi UI (T12); unit test parser kỹ |
| **Cross-currency rounding**: Decimal precision khi convert | Medium | Define rounding rules per currency (VND: 0 decimals, USD: 2); test edge cases |
| **Search performance 10K+ records**: SwiftData predicate limitations | Medium | Index compound `(note, date)`; consider FTS if needed; benchmark early |
| **Vietnamese diacritics search**: `#Predicate` không support diacritics-insensitive | Medium | Normalize text on save (stripped diacritics column) hoặc search in-memory |
| **SwiftData compound indexes**: limited support in current SwiftData | Low | Fallback to manual SortDescriptor + Predicate combination |
| **Soft delete consistency**: Ensure deleted transactions excluded everywhere | Low | Central filter in repository, never fetch without deletedAt == nil check |

---

## 7. Test Plan

### Unit Tests (FinanceCore)

| Test Suite | Key Cases | Priority |
|------------|-----------|----------|
| CreateTransactionUseCase | Valid income/expense, amount validation, balance update, transfer dual-account, cross-currency | P0 |
| UpdateTransactionUseCase | Amount change + balance reversal, type change, account change | P0 |
| DeleteTransactionUseCase | Balance reversal for income/expense/transfer | P0 |
| GetTransactionsUseCase | Pagination, date grouping, daily totals | P0 |
| QuickAmountParser | k/tr/m suffix, expressions, edge cases | P0 |
| TransactionFilter | Individual filters, combined filters, date boundaries | P1 |
| TransactionSearch | Partial match, Vietnamese diacritics, empty query | P1 |

### Integration Tests (FinanceData)

| Test Suite | Key Cases | Priority |
|------------|-----------|----------|
| TransactionRepository | CRUD, filter queries, grouped fetch, soft delete | P0 |
| CategoryRepository | Seed defaults, hierarchy fetch | P1 |
| TagRepository | CRUD, transaction association | P1 |

### UI Tests (Future)

| Screen | Key Scenarios | Priority |
|--------|---------------|----------|
| QuickInput | 3-step flow completion, k/tr input, category selection | P1 |
| TransactionList | Scroll, search, filter apply, swipe delete | P1 |
| Transfer | Same-currency, cross-currency rate input | P2 |

---

## 8. Notes

- **Performance target**: Transaction input → save < 100ms (per ARCHITECTURE.md)
- **Search target**: 10K transactions < 200ms
- **VND formatting**: Use CurrencyFormatter (already exists) — no decimal places for VND
- **Localization**: UI strings should use String Catalogs; initial support for VI + EN
- **Accessibility**: All new components must support VoiceOver, Dynamic Type, color contrast >= 4.5:1
- **No force unwraps**: Use `guard let` / `if let` everywhere per code rules
