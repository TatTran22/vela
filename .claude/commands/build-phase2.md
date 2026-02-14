---
description: "Triển khai Phase 2 — Budgets, Goals, Recurring, On-device AI, Bills, Apple Watch, Siri Shortcuts."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Phase 2 — Core Growth Implementation

Triển khai Phase 2 theo FinanceApp-Feature-Specification.md.

## Đọc Context
1. `CLAUDE.md`
2. `FinanceApp-Feature-Specification.md` → Phần "Phase 2 — Core Growth"
3. Scan Phase 1 code để hiểu patterns đã thiết lập

## Thứ Tự Triển Khai

### Sprint 6: Budgeting (Tuần 13-15)
Spawn **shared-core** agent:
1. **F2.1 Budget Model & Use Cases**
   - Budget model: id, category, amount, period (weekly/monthly), startDate, rollover, alerts
   - BudgetPeriod enum
   - BudgetAlert thresholds (50%, 80%, 100%)
   - CreateBudgetUseCase, GetBudgetStatusUseCase
   - CalculateBudgetRemainingUseCase (spent vs budget, % used)
   - Smart suggest: trung bình chi tiêu 3 tháng → gợi ý budget amount

2. **F2.2 Envelope Method (Premium)**
   - EnvelopeAllocation model
   - AllocateIncomeUseCase: khi có income → phân bổ vào categories
   - Priority ordering: Thiết yếu → Muốn có → Tiết kiệm

Spawn **data-architect** agent:
3. BudgetEntity + BudgetRepository
4. Query: tổng chi tiêu theo category trong period → so sánh với budget

Spawn **ios-engineer** agent:
5. **Budget List View** — Tất cả budgets với progress bars (color-coded)
6. **Create/Edit Budget** — Form với category picker + amount + period
7. **Budget Detail** — Transactions thuộc budget, trend mini chart
8. **Budget Alerts** — Local notifications khi đạt threshold

Spawn **macos-engineer** agent:
9. macOS budget views (table-based, sidebar integration)

### Sprint 7: Goals & Recurring (Tuần 16-18)
Spawn **shared-core** agent:
10. **F2.4 Goal Model & Use Cases**
    - Goal model: id, name, targetAmount, currentAmount, deadline, icon, linkedAccount
    - ContributeToGoalUseCase
    - CalculateGoalProjectionUseCase ("cần tiết kiệm X/tuần để đạt deadline")
    - Milestone tracking (25%, 50%, 75%, 100%)

11. **F2.3 Recurring Model & Use Cases**
    - RecurringRule model: frequency, nextDate, endDate, template, isAutoConfirm
    - Frequency enum: daily, weekly, biweekly, monthly, quarterly, yearly
    - GenerateRecurringTransactionsUseCase (chạy khi mở app)
    - SkipRecurringUseCase, EditRecurringUseCase

12. **F2.7 Bill Reminders**
    - Bill model kế thừa recurring + due date + isPaid status
    - Default VN bills: Tiền điện, nước, internet, nhà
    - MarkBillPaidUseCase → auto-create expense transaction
    - UpcomingBillsUseCase

Spawn **data-architect** agent:
13. GoalEntity, RecurringRuleEntity, BillEntity + repositories
14. Scheduling logic: next occurrence calculation

Spawn **ios-engineer** agent:
15. **Goals Screen** — Goal list with progress rings, celebration animations
16. **Create/Edit Goal** — Name, amount, deadline, icon/photo
17. **Recurring Management** — List, create, calendar view
18. **Bills Dashboard** — Upcoming bills, calendar overlay, mark paid
19. **Subscription Tracker** — Group recurring subscriptions, total monthly cost

Spawn **macos-engineer** agent:
20. macOS goals, recurring, bills views

### Sprint 8: On-Device AI (Tuần 19-21)
Spawn **shared-core** agent:
21. **F2.5 Auto-categorization (Core ML)**
    - TransactionClassifier model (Create ML Text Classifier)
    - Training data: VN transaction descriptions → categories
    - Input: note text + amount + time-of-day
    - Output: top 3 category predictions with confidence
    - On-device training pipeline: user corrections → retrain
    - Target: 70% accuracy sau 50 transactions, 85% sau 200

22. **F2.6 Smart Transaction Suggestion**
    - Pattern detector: same time + same category + similar amount
    - SuggestTransactionUseCase
    - "Bạn thường mua café vào sáng thứ Hai. Nhập 35.000₫?"

Spawn **ios-engineer** agent:
23. Integrate AI suggestions vào Quick Input flow
24. Category picker: highlight AI-suggested category
25. Suggestion notification/card on dashboard

### Sprint 9: Apple Ecosystem (Tuần 22-24)
Spawn **ios-engineer** agent:
26. **F2.8 Apple Watch App**
    - Complication: chi tiêu hôm nay / số dư
    - Quick input: amount → top 4 categories → save
    - Glance: budget remaining

27. **F2.9 Siri Shortcuts & App Intents**
    - AppIntent: "Ghi chi tiêu [amount] cho [category]"
    - AppIntent: "Hôm nay chi bao nhiêu?"
    - AppIntent: "Còn bao nhiêu budget [category]?"
    - Shortcuts gallery integration

Spawn **test-engineer** agent:
28. Unit tests cho all Phase 2 use cases
29. Budget calculation accuracy tests
30. Recurring generation edge cases (month boundaries, leap year)
31. AI categorization accuracy benchmark
32. Apple Watch UI tests

## Definition of Done — Phase 2
- [ ] Budget tracking hoạt động với alerts
- [ ] Goals với progress tracking và projections
- [ ] Recurring transactions tự generate đúng schedule
- [ ] Bill reminders push notifications hoạt động
- [ ] AI categorization đạt > 70% accuracy trên test set
- [ ] Apple Watch app compilable và functional
- [ ] Siri Shortcuts hoạt động bằng giọng nói
- [ ] 80%+ test coverage cho code mới
