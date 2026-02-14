---
description: "Triển khai feature Budgets — F2.1 Budget theo danh mục + F2.2 Envelope Method"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: Budgets

## Feature Spec References
- F2.1: Budget theo danh mục (monthly/weekly budget per category, alerts 80%/100%)
- F2.2: Budget tổng — Envelope Method (phân bổ thu nhập vào phong bì, YNAB-style)

## Đọc Context Trước
1. `CLAUDE.md` — coding conventions, architecture rules
2. `FinanceApp-Feature-Specification.md` → sections 5.1 (F2.1, F2.2)
3. `docs/DATA-MODEL.md` → Budget entity, BudgetPeriod enum, Category relationship
4. `docs/ARCHITECTURE.md` — MVVM + Clean Architecture layers
5. `docs/CONVENTIONS.md` — Swift style guide

## Tasks

### FinanceCore

1. `BudgetPeriod` enum (nếu chưa có):
   ```swift
   enum BudgetPeriod: String, Codable, Sendable {
       case weekly
       case monthly
       case yearly
   }
   ```

2. `BudgetStatus` enum:
   ```swift
   enum BudgetStatus: Sendable {
       case onTrack      // < 50%
       case warning       // 50-80%
       case nearLimit     // 80-100%
       case overBudget    // > 100%
   }
   ```

3. `Budget` model:
   - id: UUID
   - category: Category
   - amount: Decimal (giới hạn chi tiêu)
   - period: BudgetPeriod (weekly/monthly/yearly)
   - startDate: Date
   - rollover: Bool (Premium only)
   - rolledAmount: Decimal (số tiền rollover từ kỳ trước)
   - alertThresholds: [Double] (mặc định [0.5, 0.8, 1.0])
   - createdAt: Date
   - updatedAt: Date

4. `BudgetSummary` value type:
   - budget: Budget
   - spentAmount: Decimal (tổng chi tiêu trong kỳ hiện tại)
   - remainingAmount: Decimal (amount + rolledAmount - spentAmount)
   - percentUsed: Double (spentAmount / totalBudget * 100)
   - status: BudgetStatus
   - daysRemaining: Int (còn bao nhiêu ngày trong kỳ)
   - dailyAllowance: Decimal (remainingAmount / daysRemaining)

5. `Envelope` model (F2.2 — Premium):
   - id: UUID
   - name: String
   - category: Category
   - allocatedAmount: Decimal (số tiền được phân bổ)
   - spentAmount: Decimal
   - priority: EnvelopePriority (essential, want, savings)
   - sortOrder: Int
   - createdAt: Date
   - updatedAt: Date

6. `EnvelopePriority` enum:
   ```swift
   enum EnvelopePriority: String, Codable, Sendable {
       case essential   // Thiết yếu (nhà, ăn, xe)
       case want        // Muốn có (giải trí, mua sắm)
       case savings     // Tiết kiệm/Đầu tư
   }
   ```

7. `EnvelopeAllocation` value type:
   - envelope: Envelope
   - remainingAmount: Decimal
   - percentUsed: Double

8. `BudgetRepositoryProtocol`:
   - saveBudget(_ budget: Budget) async throws
   - deleteBudget(id: UUID) async throws
   - fetchBudgets() async throws -> [Budget]
   - fetchBudget(forCategory: UUID) async throws -> Budget?
   - fetchBudgetSummaries(period: BudgetPeriod, date: Date) async throws -> [BudgetSummary]

9. `EnvelopeRepositoryProtocol`:
   - saveEnvelope(_ envelope: Envelope) async throws
   - deleteEnvelope(id: UUID) async throws
   - fetchEnvelopes() async throws -> [Envelope]
   - allocateIncome(amount: Decimal, to envelopes: [(UUID, Decimal)]) async throws

10. `CreateBudgetUseCase`:
    - Validate: amount > 0, category chưa có budget cùng period
    - Free tier check: tối đa 3 budgets
    - Gợi ý budget dựa trên trung bình chi tiêu 3 tháng (smart suggest)

11. `GetBudgetSummariesUseCase`:
    - Tính toán spent amount từ transactions trong kỳ hiện tại
    - Tính rollover nếu Premium + rollover enabled
    - Trả về danh sách BudgetSummary, sorted by percentUsed descending

12. `CheckBudgetAlertsUseCase`:
    - So sánh percentUsed với alertThresholds
    - Trả về danh sách budgets cần cảnh báo (đạt 80%, 100%, vượt)
    - Dùng cho push notification trigger

13. `SuggestBudgetAmountUseCase`:
    - Input: category ID
    - Tính trung bình chi tiêu 3 tháng gần nhất cho category
    - Output: suggested amount (rounded lên hàng chục nghìn VND)

14. `AllocateIncomeUseCase` (F2.2 — Premium):
    - Input: income amount, allocation rules
    - Phân bổ tiền vào envelopes theo priority hoặc custom amounts
    - Validate: tổng allocation <= income amount

### FinanceData

15. `BudgetEntity` @Model:
    - Map 1:1 với Budget model
    - Relationship: category → CategoryEntity
    - Indexes: (category), (period, startDate)

16. `EnvelopeEntity` @Model:
    - Map 1:1 với Envelope model
    - Relationship: category → CategoryEntity
    - Index: (sortOrder)

17. `BudgetRepositoryImpl`:
    - Implement BudgetRepositoryProtocol
    - Fetch spent amount bằng query transactions filtered by category + date range
    - Efficient aggregate query cho tổng chi tiêu

18. `EnvelopeRepositoryImpl`:
    - Implement EnvelopeRepositoryProtocol
    - Batch allocation update trong single transaction

### FinanceUI

19. `BudgetProgressBar` — horizontal bar with color-coded fill:
    - Xanh (< 50%), vàng (50-80%), cam (80-100%), đỏ (> 100%)
    - Hiển thị: "250.000₫ / 500.000₫" + "50%"
    - Animated fill khi appear

20. `BudgetCard` — card hiển thị 1 budget:
    - Category icon + name
    - BudgetProgressBar
    - Remaining amount + daily allowance
    - Warning badge khi near/over limit

21. `BudgetOverviewHeader` — tổng quan tất cả budgets:
    - Tổng budget vs tổng đã chi
    - Overall progress ring
    - Số budgets on-track / warning / over

22. `EnvelopeRow` — 1 row trong envelope list:
    - Category icon + name + priority badge
    - Allocated vs spent
    - Mini progress bar

23. `IncomeAllocationSheet` — sheet phân bổ thu nhập (F2.2):
    - Hiển thị income amount ở top
    - List envelopes với input field cho mỗi cái
    - "Còn lại chưa phân bổ: X₫"
    - Quick actions: "Phân bổ đều", "Theo tỷ lệ tháng trước"

### iOS

24. `BudgetListView`:
    - BudgetOverviewHeader ở top
    - LazyVStack danh sách BudgetCards
    - FAB button "+" → tạo budget mới
    - Tap budget → BudgetDetailView
    - Empty state: "Chưa có ngân sách. Tạo ngân sách đầu tiên để kiểm soát chi tiêu!"

25. `BudgetListViewModel`:
    - @Observable class
    - budgetSummaries: [BudgetSummary]
    - selectedPeriod: BudgetPeriod
    - Load + refresh budget summaries
    - Delete budget (swipe action)

26. `CreateBudgetView`:
    - Category picker (chỉ hiện categories chưa có budget)
    - Amount input (QuickNumpad)
    - Period selector (weekly/monthly/yearly)
    - Smart suggest button: "Gợi ý dựa trên chi tiêu trước"
    - Rollover toggle (Premium badge nếu free)
    - Alert thresholds config (advanced)

27. `CreateBudgetViewModel`:
    - Validate input
    - Call CreateBudgetUseCase
    - Show smart suggest amount

28. `BudgetDetailView`:
    - Budget info + large progress bar
    - Danh sách giao dịch thuộc category trong kỳ
    - Trend chart: chi tiêu category qua các tháng
    - Edit / Delete actions

29. `EnvelopeView` (F2.2 — Premium):
    - List tất cả envelopes grouped by priority
    - Tổng allocated vs tổng income
    - "Phân bổ thu nhập" button → IncomeAllocationSheet

30. `EnvelopeViewModel`:
    - Load envelopes
    - Handle allocation logic
    - Premium gate check

### macOS

31. `BudgetSidebarView`:
    - List budgets trong sidebar
    - Click → detail trong main content
    - Tổng overview ở header

32. `BudgetTableView`:
    - Table columns: Category | Budget | Spent | Remaining | % | Status
    - Sortable columns
    - Inline edit budget amount
    - Keyboard shortcut ⌘B → toggle budget view

33. `EnvelopeManagerView` (F2.2 — macOS):
    - Split view: envelope list + allocation panel
    - Drag & drop reorder envelopes
    - Keyboard-driven allocation input

### Tests

34. CreateBudget — amount validation, duplicate category check, free tier limit (3)
35. BudgetSummary calculation — spent amount, remaining, percentUsed, status transitions
36. Budget alerts — trigger at 80%, 100%, correct threshold matching
37. Smart suggest — average calculation from 3 months data, VND rounding
38. Rollover — carry over unused amount, accumulation across months
39. Envelope allocation — total <= income, priority ordering, partial allocation
40. BudgetProgressBar — color transitions at 50%/80%/100% thresholds
41. Edge cases — zero budget, no transactions in period, category deleted while budget exists
