---
description: "Triển khai feature Accounts — F1.1 Tạo & quản lý tài khoản + F1.2 Multi-currency cơ bản"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: Accounts

## Feature Spec References
- F1.1: Tạo & quản lý tài khoản
- F1.2: Multi-currency cơ bản

## Đọc Context Trước
1. `CLAUDE.md`
2. `FinanceApp-Feature-Specification.md` → F1.1, F1.2
3. `docs/DATA-MODEL.md`
4. `docs/DESIGN-SYSTEM.md`

## Tasks

### FinanceCore
1. `AccountType` enum: cash, bank, creditCard, eWallet, savings
2. `EWalletProvider` enum: momo, zalopay, vnpay, other
3. `Account` model:
   - id: UUID, name: String, type: AccountType
   - currency: CurrencyCode, balance: Decimal
   - icon: String (SF Symbol), color: String (hex)
   - eWalletProvider: EWalletProvider? (only for eWallet type)
   - note: String?, sortOrder: Int
   - isArchived: Bool, isHidden: Bool
   - createdAt: Date, updatedAt: Date
4. `CurrencyCode` enum:
   - VND (default), USD, EUR, JPY, KRW, THB, SGD, AUD, GBP, CNY
   - Properties: code, symbol, name, decimalPlaces (VND=0, others=2)
5. `ExchangeRate` model:
   - from: CurrencyCode, to: CurrencyCode
   - rate: Decimal, date: Date, source: String
6. `CurrencyFormatter`:
   - VND: "1.000.000 ₫" (no decimals, dot separator)
   - USD: "$1,000.00"
   - Format with/without symbol, compact ("1.5tr", "150k")
   - formatPair(amount, from, to, rate) → "100 USD ≈ 2.450.000 ₫"
7. `CreateAccountUseCase`:
   - Validate: name not empty, unique name
   - Set initial balance, assign sortOrder
   - Free tier: max 5 accounts check
8. `UpdateAccountUseCase`:
   - Cannot change currency if transactions exist
   - Balance recalculation on manual adjust
9. `DeleteAccountUseCase`:
   - Cannot delete if has transactions → prompt archive
   - Soft delete (archive)
10. `GetAccountsUseCase`:
    - Grouped by type
    - Total balance across all accounts (converted to primary currency)
    - Filter: active only, include hidden, include archived
11. `ReorderAccountsUseCase`
12. `ExchangeRateUseCase`:
    - Fetch daily rates (API)
    - Cache locally
    - Convert(amount, from, to) → Decimal
    - Fallback to last cached rate if offline

### FinanceData
13. `AccountEntity` @Model
    - Indexes: (type), (currency), (type, sortOrder)
    - Relationship: transactions (one-to-many)
14. `AccountRepositoryImpl`:
    - fetchGroupedByType() → [AccountType: [Account]]
    - fetchTotalBalance(in currency: CurrencyCode) → Decimal
    - updateBalance(_ id: UUID, delta: Decimal)
15. `ExchangeRateEntity` @Model
16. `ExchangeRateRepositoryImpl`:
    - fetchRate(from:to:date:) → ExchangeRate?
    - saveRates(_ rates: [ExchangeRate])
    - deleteOldRates(before: Date)

### FinanceUI
17. `AccountIcon` — SF Symbol with type-specific default icon + color
18. `AccountCard` — name, balance (formatted), type badge, icon
19. `AccountTypeBadge` — compact label with icon for account type
20. `BalanceText` — formatted amount with currency symbol
21. `CurrencyPicker` — searchable list with flag + code + name

### iOS
22. `AccountListView`:
    - Grouped sections by AccountType
    - Each row: icon + name + balance
    - Section footer: subtotal per type
    - Bottom: Total across all accounts
    - Swipe actions: edit, archive, hide
    - Drag-to-reorder within group
23. `AccountEditView`:
    - Name, type picker, currency picker
    - Initial balance input (with CurrencyFormatter)
    - Icon picker + color picker
    - EWallet provider picker (shown if type == eWallet)
    - Note field
24. `AccountDetailView`:
    - Balance card (large)
    - Income/Expense summary for this account (month)
    - Transaction list filtered by account
    - "Adjust balance" action
25. `BalanceAdjustSheet`:
    - Current balance display
    - New balance input
    - Auto-create adjustment transaction

### macOS
26. Sidebar section: Accounts grouped by type, click to filter transactions
27. Account management in Settings or dedicated window
28. Quick balance view in sidebar (compact)
29. Right-click: Edit, Archive, Hide, View Transactions

### Tests
30. CreateAccount — validation, tier limit (5 free), sortOrder
31. DeleteAccount — block if has transactions, archive fallback
32. CurrencyFormatter — VND format, USD format, compact format, pair format
33. ExchangeRate — convert accuracy, offline fallback, cache expiry
34. AccountBalance — delta updates atomic, total balance calculation
35. MultiCurrency — cross-currency total, display pair
