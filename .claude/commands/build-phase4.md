---
description: "Triển khai Phase 4 — Shared Wallets, Split Bills, Smart Rules, Bank Import, Auto-savings, Freelancer Tools, Platform Expansion."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Phase 4 — Ecosystem & Scale Implementation

Triển khai Phase 4 theo FinanceApp-Feature-Specification.md.

## Đọc Context
1. `CLAUDE.md`
2. `FinanceApp-Feature-Specification.md` → Phần "Phase 4 — Ecosystem & Scale"
3. Scan existing CloudKit setup từ Phase 1

## Thứ Tự Triển Khai

### Sprint 14: Shared Finance (Tuần 37-40)
Spawn **shared-core** agent:
1. **F4.1 Shared Wallet Model**
   - SharedWallet model: id, name, members[], accounts[], budgets[], inviteCode
   - Member model: userId, role (owner/member/viewer), joinedAt
   - MemberPermission: full_access, add_transactions, view_only
   - Privacy: personal accounts ALWAYS private, chỉ shared wallet visible cho members
   - InviteMemberUseCase (via Apple ID / invite link)
   - SharedBudgetUseCase (budget chung cho gia đình)
   - SharedTransactionUseCase (tag "ai chi")

2. **F4.2 Split Bills**
   - SplitBill model: totalAmount, participants[], splits[], isSettled
   - SplitType: equal, custom_amount, percentage, by_items
   - SplitParticipant: name, amount_owed, isPaid
   - CalculateSplitUseCase
   - SettleUpUseCase → track who owes whom
   - Net settlement: tối giản số giao dịch cần thiết

Spawn **data-architect** agent:
3. CloudKit shared database setup cho shared wallets
4. SharedWalletEntity + sync logic giữa members
5. Invitation system via CloudKit sharing

Spawn **ios-engineer** agent:
6. **Shared Wallet UI** — Member management, shared dashboard
7. **Shared Budget View** — Budget chung + ai chi bao nhiêu
8. **Split Bill Flow** — Nhập bill → chọn người → chia → track settlement
9. **Settlement Tracking** — Ai nợ ai, suggest MoMo/bank transfer

Spawn **macos-engineer** agent:
10. macOS shared wallet views

### Sprint 15: Automation (Tuần 41-43)
Spawn **shared-core** agent:
11. **F4.3 Smart Rules Engine**
    - Rule model: conditions[], actions[]
    - RuleCondition: field (note/amount/category/time/dayOfWeek), operator (contains/equals/greaterThan), value
    - RuleAction: setCategory, addTag, sendNotification, setAccount
    - Examples:
      * IF note contains "Grab" → category = Di chuyển/Grab
      * IF amount > 5.000.000 → tag "Chi lớn" + notify
      * IF category = Ăn ngoài AND dayOfWeek = weekend → tag "Weekend"
    - RuleEngine: evaluate rules on new transactions
    - Priority ordering for conflicting rules

12. **F4.4 Bank Statement Import**
    - BankStatementParser protocol
    - CSV parser (generic)
    - VN bank templates: Vietcombank, Techcombank, BIDV, VPBank, MBBank, ACB, TPBank
    - Column mapping: auto-detect + user confirmation
    - Duplicate detection: fuzzy match (same date ± 1 day, same amount, similar note)
    - Import preview: show matched vs new transactions

13. **F4.5 Auto-savings Rules**
    - AutoSaveRule model: type (round_up/fixed/percentage/challenge), parameters
    - Round-up: mỗi giao dịch làm tròn → phần dư → goal
    - Fixed: X VND/ngày hoặc /tuần → goal
    - Percentage: X% mỗi income → goal
    - Challenge: 52-week challenge (tuần 1: 10k, tuần 2: 20k, ...)
    - Note: tracking/allocation only, không chuyển tiền thật

Spawn **ios-engineer** agent:
14. **Rule Builder UI** — Visual WHEN/IF/THEN builder
15. **Bank Import Flow** — Upload file → detect bank → map columns → preview → import
16. **Auto-savings Settings** — Choose rule type, configure, link to goal
17. **Import History** — Log of imports, undo capability

### Sprint 16: Freelancer Features (Tuần 44-46)
Spawn **shared-core** agent:
18. **F4.6 Income by Client/Project**
    - Client model: id, name, contactInfo, notes
    - Project model: id, name, client, budget, status
    - TagTransactionWithClientUseCase
    - ClientRevenueReportUseCase
    - ProjectProfitabilityUseCase

19. **F4.7 Business vs Personal Separation**
    - TransactionContext enum: personal, business
    - Toggle view between contexts
    - Separate reports per context
    - Tax export: business expenses cho kê khai thuế
    - VN freelancer tax: 2% doanh thu < 100tr/năm

Spawn **ios-engineer** + **macos-engineer** agents:
20. Client/Project management screens
21. Income dashboard by client (bar chart)
22. Context toggle (Personal ↔ Business) in tab bar/sidebar
23. Tax summary report export

### Sprint 17: Platform Polish (Tuần 47-50)
Spawn **macos-engineer** agent:
24. **F4.8 macOS Full Experience**
    - Keyboard shortcuts cho MỌI action
    - Table view with sortable columns + multi-select + bulk edit
    - Multi-window support (dashboard + entry simultaneously)
    - Drag & drop CSV import
    - Menu bar quick-entry widget
    - Spotlight integration (search transactions from Spotlight)

Spawn **ios-engineer** agent:
25. **F4.9 iPadOS Optimization**
    - Split view: list + detail simultaneously
    - Apple Pencil: annotate receipts
    - Keyboard shortcuts
    - Stage Manager support
    - Drag & drop between apps

26. **F4.10 Data Import from Other Apps**
    - Money Lover CSV import
    - YNAB export import
    - Monefy import
    - Spendee import
    - Generic CSV with column mapping
    - Import wizard: detect source → auto-map → preview → import

### Sprint 18: Final QA & Launch Prep (Tuần 51-54)
Spawn **test-engineer** agent:
27. Full regression testing all phases
28. Performance testing: 10K+ transactions
29. CloudKit sync stress testing (shared wallets)
30. Accessibility audit (WCAG 2.1 AA)

Spawn **code-reviewer** agent:
31. Full security audit
32. Privacy compliance review
33. App Store review guidelines compliance
34. Memory leak detection
35. Crash-free rate target: 99.9%

## Definition of Done — Phase 4
- [ ] Shared wallets functional between 2+ users
- [ ] Split bills with settlement tracking
- [ ] Smart rules executing correctly on new transactions
- [ ] VN bank statement import for top 7 banks
- [ ] Auto-savings rules tracking correctly
- [ ] Freelancer client/project tracking functional
- [ ] macOS full keyboard-driven experience
- [ ] iPadOS optimized layout
- [ ] Import from 5+ competing apps
- [ ] Full regression pass
- [ ] App Store submission ready
