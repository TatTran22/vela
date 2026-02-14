---
description: "Triển khai feature Transactions — F1.3 CRUD + F1.4 List/Search + F1.5 Transfer"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: Transactions

## Feature Spec References
- F1.3: Nhập giao dịch thủ công
- F1.4: Danh sách & tìm kiếm giao dịch
- F1.5: Chuyển khoản giữa tài khoản

## Tasks

### FinanceCore
1. `TransactionType` enum: income, expense, transfer
2. `Transaction` model:
   - id: UUID, amount: Decimal (always positive), type: TransactionType
   - note: String?, date: Date, account: Account, toAccount: Account? (transfers)
   - category: Category, tags: [Tag], receiptImageData: Data?
   - location: (lat: Double, lon: Double)?, isRecurring: Bool
   - metadata: [String: String]?
3. `Tag` model: id, name, color
4. `TransactionFilter`:
   - accounts: [UUID]?, categories: [UUID]?, dateRange: ClosedRange<Date>?
   - amountRange: ClosedRange<Decimal>?, tags: [UUID]?, searchText: String?
5. `CreateTransactionUseCase`:
   - Validate: amount > 0, account exists, category matches type
   - Update account balance (atomic)
   - For transfers: debit source + credit destination
6. `GetTransactionsUseCase`:
   - Grouped by date, daily income/expense totals
   - Filtered + sorted + paginated
7. `DeleteTransactionUseCase`:
   - Reverse account balance adjustment
   - Soft delete
8. `TransactionSearchUseCase`:
   - Full-text search on note, category name, tags
9. `QuickAmountParser`:
   - "150k" → 150_000, "1.5tr" → 1_500_000, "2m" → 2_000_000
   - "150k + 200k" → 350_000 (calculator)
   - "1tr - 200k" → 800_000

### FinanceData
10. `TransactionEntity` @Model
    - Indexes: (date), (category), (account), (amount)
    - Compound: (account, date), (category, date)
11. `TransactionRepositoryImpl`
    - Batch insert (for imports)
    - Efficient date-grouped fetch
12. `TagEntity`

### FinanceUI
13. `TransactionRow` — icon + category + note + amount (color-coded)
14. `AmountText` — green (+) for income, red (-) for expense, blue for transfer
15. `QuickNumpad` — custom numpad with k/tr buttons + calculator
16. `TransactionFilterSheet`
17. `DateGroupHeader` — "Hôm nay", "Hôm qua", "Thứ Hai, 10/02"

### iOS
18. `TransactionListView`:
    - LazyVStack grouped by date
    - Pull-to-refresh
    - Swipe-to-delete, swipe-to-edit
    - Search bar (always visible)
    - Filter button → sheet
19. `QuickInputView` (Transaction Entry):
    - Step 1: Amount (custom numpad, k/tr shortcuts)
    - Step 2: Category picker (grid top 6 recent + "Xem tất cả")
    - Step 3: Quick review (amount + category + account + date)
    - [Save] — target < 5 seconds total
    - [Thêm chi tiết] → note, tags, receipt camera, date picker, location
20. `TransactionDetailView` — full details + edit
21. `TransferView` — source account → destination account, cross-currency rate input

### macOS
22. Table view: Date | Category | Note | Amount | Account — sortable columns
23. Keyboard shortcut ⌘N → floating quick entry window
24. Multi-select + bulk actions (delete, change category, add tag)
25. Drag from Finder (receipt image) → attach to transaction

### Tests
26. CreateTransaction — amount validation, balance update, transfer logic
27. QuickAmountParser — "150k", "1.5tr", "150k+200k", edge cases
28. TransactionFilter — combinations of filters
29. Search — partial match, Vietnamese diacritics
30. Delete — balance reversal correct
31. Cross-currency transfer — rate application, rounding
