---
description: "Triển khai toàn bộ Phase 1 MVP — Accounts, Transactions, Categories, Dashboard, iCloud Sync, Widget, Onboarding. Đây là command tổng, sẽ spawn subagents cho từng phần."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Phase 1 — MVP Implementation

Triển khai toàn bộ Phase 1 MVP theo thứ tự dependency.

## Đọc Context Trước
1. `CLAUDE.md`
2. `FinanceApp-Feature-Specification.md` → Phần "Phase 1 — MVP"
3. `docs/ARCHITECTURE.md`
4. `docs/DATA-MODEL.md`

## Thứ Tự Triển Khai (Dependency Order)

### Sprint 1: Foundation (Tuần 1-2)
Spawn **shared-core** agent:
1. **F1.6 Categories** — Hệ thống danh mục với defaults VN
   - CategoryType enum (income, expense)
   - Default categories tiếng Việt (Ăn uống, Nhà ở, Di chuyển, etc.)
   - Category model: id, name, localizedName, type, parent, icon, color, sortOrder

2. **F1.1 Accounts** — Tạo & quản lý tài khoản
   - AccountType enum (cash, bank, credit, ewallet, savings)
   - Account model: id, name, type, currency, balance, icon, color
   - EWallet subtype cho MoMo, ZaloPay, VNPay

3. **F1.2 Multi-currency cơ bản**
   - CurrencyCode enum (VND default + USD, EUR, etc.)
   - ExchangeRate model
   - VND formatter (không decimal, dấu chấm ngăn hàng nghìn)
   - CurrencyFormatter utility

Spawn **data-architect** agent song song:
4. **SwiftData Entities** — Map tất cả models sang @Model entities
5. **Repository protocols** — AccountRepository, CategoryRepository
6. **ModelContainer setup** — SwiftData container configuration

### Sprint 2: Transactions Core (Tuần 3-4)
Spawn **shared-core** agent:
7. **F1.3 Transactions** — Transaction model & use cases
   - TransactionType enum (income, expense, transfer)
   - Transaction model với tất cả fields
   - CreateTransactionUseCase, UpdateTransactionUseCase, DeleteTransactionUseCase
   - GetTransactionsUseCase (with filtering, sorting, grouping by date)
   - Calculator utility cho quick input (150k → 150.000)

8. **F1.5 Transfer** — Transfer logic
   - TransferUseCase (debit source + credit destination)
   - Cross-currency transfer with exchange rate

Spawn **data-architect** agent:
9. **TransactionEntity** + TransactionRepository implementation
10. **Fetch + Sort + Filter** optimized queries

### Sprint 3: iOS UI (Tuần 5-7)
Spawn **ui-designer** agent:
11. **Design System** — Colors, Typography, Spacing tokens
    - FinanceColors, FinanceTypography, FinanceSpacing
    - AmountText component (color-coded income/expense)
    - AccountIcon component
    - CategoryIcon component

Spawn **ios-engineer** agent:
12. **F1.7 Dashboard (Home)** — iOS Home Screen
    - Total balance card
    - Income/Expense summary tháng này
    - Mini spending chart (7 ngày)
    - Recent transactions list (3-5 items)
    - Quick "+" FAB button

13. **F1.3 Quick Input** — Transaction entry
    - Custom numpad với k/tr shortcuts
    - AI-ready category picker (grid top 6 + see all)
    - Quick review → Save (target < 5 giây)
    - More options: note, tags, receipt, date, location

14. **F1.4 Transaction List** — Browse & search
    - Grouped by date, daily totals
    - Full-text search
    - Filter panel (account, category, date range, amount range)
    - Swipe actions (delete, edit)

15. **F1.1 Account Management UI** — Account screens
    - Account list grouped by type
    - Create/Edit account form
    - Account detail with transactions

16. **F1.6 Category Management UI** — Category screens
    - Category grid view
    - Create/Edit with icon picker (SF Symbols) + color picker

### Sprint 4: macOS + Sync + Polish (Tuần 8-10)
Spawn **macos-engineer** agent:
17. **macOS App** — NavigationSplitView layout
    - Sidebar: Accounts, Categories, Settings
    - Content: Transaction list (Table view)
    - Detail: Transaction detail / Edit
    - Menu bar quick-entry (⌘N)
    - Keyboard shortcuts cho common actions

Spawn **data-architect** agent:
18. **F1.9 iCloud Sync** — CloudKit setup
    - NSPersistentCloudKitContainer configuration
    - Sync status monitoring
    - Conflict resolution (last-write-wins)
    - Offline-first verification

Spawn **ios-engineer** agent:
19. **F1.10 iOS Widget** — WidgetKit
    - Small: Tổng số dư hoặc chi tiêu hôm nay
    - Medium: Chi tiêu tuần + mini chart
    - Large: Top categories + recent transactions

20. **F1.11 Onboarding** — First-run experience
    - Chọn đồng tiền (detect locale → VND)
    - Tạo tài khoản đầu tiên
    - Nhập số dư
    - Quick input demo
    - Feature highlights

21. **F1.12 Settings** — App settings
    - Dark/Light/System theme
    - Currency & format
    - Language (vi/en)
    - Face ID/Touch ID lock
    - Export data (CSV/JSON)
    - Custom month start date
    - F1.8 Basic Reports trong tab riêng

### Sprint 5: Testing & QA (Tuần 11-12)
Spawn **test-engineer** agent:
22. Unit tests cho tất cả FinanceCore use cases
23. Unit tests cho FinanceData repositories
24. UI tests cho critical flows (add transaction, view dashboard)
25. Edge cases: empty state, max values, currency boundaries

Spawn **code-reviewer** agent:
26. Security audit (no hardcoded secrets, Keychain usage)
27. Architecture compliance review
28. Performance review (large transaction lists)
29. Accessibility audit (VoiceOver, Dynamic Type)

## Definition of Done — Phase 1
- [ ] Tất cả features F1.1-F1.12 hoạt động trên iOS và macOS
- [ ] iCloud sync hoạt động giữa devices
- [ ] Widget hiển thị đúng data
- [ ] Onboarding flow smooth < 2 phút
- [ ] 80%+ test coverage cho FinanceCore
- [ ] 0 swiftlint errors
- [ ] App size < 30MB
- [ ] Launch time < 1 second
- [ ] VoiceOver navigable
