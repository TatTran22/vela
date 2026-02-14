---
description: "Triển khai feature Dashboard — F1.7 Home Screen + F1.8 Báo cáo chi tiêu cơ bản"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: Dashboard

## Feature Spec References
- F1.7: Dashboard (Home Screen)
- F1.8: Báo cáo chi tiêu cơ bản

## Đọc Context Trước
1. `CLAUDE.md`
2. `FinanceApp-Feature-Specification.md` → F1.7, F1.8
3. `docs/ARCHITECTURE.md`
4. `docs/DESIGN-SYSTEM.md`

## Tasks

### FinanceCore
1. `DashboardData` model:
   - totalBalance: Decimal (all accounts, primary currency)
   - monthlyIncome: Decimal
   - monthlyExpense: Decimal
   - monthlyRemaining: Decimal (income - expense)
   - dailySpending: [(date: Date, amount: Decimal)] (last 7 days)
   - recentTransactions: [Transaction] (last 5)
   - topCategories: [(category: Category, amount: Decimal, percentage: Double)]
2. `GetDashboardDataUseCase`:
   - Aggregate from accounts, transactions repositories
   - Respect custom month start date (from Settings)
   - Convert multi-currency to primary currency
3. `ReportData` model:
   - period: ReportPeriod (week, month, lastMonth, custom range)
   - categoryBreakdown: [(Category, Decimal, Double)] — for pie chart
   - timeSeriesIncome: [(Date, Decimal)] — for bar chart
   - timeSeriesExpense: [(Date, Decimal)] — for bar chart
   - trendData: [(month: Date, income: Decimal, expense: Decimal)] — 6 months
   - totalIncome: Decimal, totalExpense: Decimal, netAmount: Decimal
4. `GetReportDataUseCase`:
   - Filter by period, account, category
   - Free tier: current month only
   - Premium: full history + export
5. `ReportPeriod` enum: thisWeek, thisMonth, lastMonth, custom(DateInterval)
6. `ExportReportUseCase`:
   - Generate CSV or JSON from report data
   - Premium only

### FinanceUI
7. `BalanceSummaryCard`:
   - Large total balance
   - Income (green) / Expense (red) / Remaining
   - Tap → detailed breakdown
8. `MiniSpendingChart` — Swift Charts:
   - Bar chart, last 7 days daily spending
   - Highlight today
   - Tap bar → show amount
9. `RecentTransactionsList`:
   - 3-5 items, compact row (icon + note + amount)
   - "Xem tất cả" footer link
10. `PieChartView` — Swift Charts:
    - Category breakdown
    - Tap slice → highlight + show details
    - Legend with category icons
11. `BarChartView` — Swift Charts:
    - Income vs Expense by time period
    - Grouped bars (income green, expense red)
12. `TrendLineChart` — Swift Charts:
    - 6-month trend line
    - Income line + Expense line
    - Net area fill
13. `PeriodPicker` — segmented control: Tuần | Tháng | Tháng trước | Tùy chỉnh

### iOS
14. `DashboardView` (Home tab):
    - ScrollView vertical
    - BalanceSummaryCard (top)
    - MiniSpendingChart
    - RecentTransactionsList
    - Quick "+" FAB button (bottom-right) → QuickInputView
    - Pull-to-refresh
15. `ReportsView` (Reports tab):
    - PeriodPicker (top)
    - PieChartView (category breakdown)
    - BarChartView (income/expense over time)
    - TrendLineChart (6-month trend)
    - Category detail list (tap → transactions)
    - Export button (premium badge if free)
16. `CategoryBreakdownRow`:
    - Category icon + name + amount + percentage bar
    - Tap → TransactionListView filtered by category

### macOS
17. Dashboard as main content area in NavigationSplitView:
    - Dense layout, side-by-side cards
    - BalanceSummaryCard (top-left)
    - MiniSpendingChart (top-right)
    - RecentTransactionsList (bottom-left)
    - Quick stats (bottom-right)
18. Reports in separate tab/section:
    - Larger charts (more space)
    - Table view for category breakdown (sortable)
    - Date range picker (macOS-native)
    - Export to CSV/JSON via Save dialog

### Tests
19. DashboardData — correct aggregation, multi-currency conversion
20. ReportData — period filtering, category breakdown percentages sum to 100%
21. CustomMonthStart — day 25 start: correct income/expense boundaries
22. Charts — data points correct for 7-day, 6-month ranges
23. Export — CSV format valid, JSON parseable
24. FreeTier — reports limited to current month
