---
description: "Triển khai feature Reports — F3.2 AI Insights (spending patterns, anomaly, Core ML) + F3.7 Custom Reports (templates, PDF export, schedule)"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: AI Insights & Custom Reports

## Feature Spec References
- F3.2: AI Financial Insights (spending patterns, anomaly detection, savings suggestions — on-device Core ML)
- F3.7: Custom Reports (user-defined templates, scheduled generation, PDF export, share)

## Đọc Context Trước
1. `CLAUDE.md` — tech stack, code rules, module structure
2. `FinanceApp-Feature-Specification.md` → section 6.1 "F3.2 — AI Financial Insights" + section 6.3 "F3.7 — Custom Reports"
3. `docs/DATA-MODEL.md` → Transaction, Category, Budget, Account entities
4. `docs/ARCHITECTURE.md` → Clean Architecture layers
5. `docs/DESIGN-SYSTEM.md` → chart styles, color palette

## Tasks

### FinanceCore

#### AI Insights (F3.2)
1. `FinancialInsight` model:
   - id: UUID
   - type: InsightType
   - title: String
   - description: String
   - severity: InsightSeverity
   - actionable: Bool
   - suggestedAction: SuggestedInsightAction?
   - relatedCategoryIds: [UUID]
   - relatedPeriod: ClosedRange<Date>
   - dataPoints: [InsightDataPoint]? (dữ liệu minh họa)
   - isRead: Bool
   - createdAt: Date

2. `InsightType` enum:
   - spendingAnomaly (chi tiêu bất thường so với trung bình)
   - savingsOpportunity (cơ hội tiết kiệm)
   - patternDetection (phát hiện thói quen chi tiêu)
   - subscriptionAlert (subscription ít dùng)
   - comparativeAnalysis (so sánh với mức trung bình)
   - budgetWarning (sắp vượt budget)
   - incomeChange (thu nhập thay đổi)
   - weeklyDigest (tổng kết tuần)
   - monthlyDigest (tổng kết tháng)

3. `InsightSeverity` enum:
   - info (thông tin, màu xanh)
   - warning (cảnh báo, màu vàng)
   - alert (quan trọng, màu đỏ)
   - positive (tích cực, màu xanh lá)

4. `SuggestedInsightAction` enum:
   - reduceCategorySpending(categoryId: UUID, targetAmount: Decimal)
   - cancelSubscription(transactionIds: [UUID])
   - createBudget(categoryId: UUID, suggestedAmount: Decimal)
   - reviewTransactions(filter: TransactionFilter)

5. `InsightDataPoint` model:
   - label: String
   - value: Decimal
   - date: Date?
   - color: String? (hex)

6. `GenerateInsightsUseCase` (protocol + implementation):
   - Input: dateRange: ClosedRange<Date>?
   - Output: [FinancialInsight]
   - Logic:
     a. Spending anomaly: so sánh chi tiêu category tháng này vs trung bình 3 tháng, flag nếu tăng > 30%
     b. Savings opportunity: tìm category chi tiêu lặp lại + cao → suggest giảm
     c. Pattern detection: phân tích time-of-day, day-of-week spending patterns
     d. Subscription alert: recurring expenses ít thay đổi, tổng > threshold
     e. Budget warning: budget đạt > 80% mà còn > 7 ngày trong kỳ

7. `AnomalyDetectionService` (protocol + implementation):
   - On-device: z-score calculation cho mỗi category
   - Input: category spending history (6+ months)
   - Output: [AnomalyResult] — categoryId, currentAmount, averageAmount, zScore, isAnomaly

8. `SpendingPatternService` (protocol + implementation):
   - Detect recurring patterns: same category + similar amount + regular interval
   - Detect time patterns: "chi tiêu nhiều vào cuối tuần", "mua café mỗi sáng"
   - Output: [SpendingPattern] — patternType, description, frequency, averageAmount

9. `InsightDeliveryService` (protocol + implementation):
   - scheduleWeeklyDigest() — push notification + in-app mỗi Chủ Nhật
   - scheduleMonthlyReport() — đầu tháng mới
   - checkAndDeliverInsights() — gọi khi mở app, check có insight mới không
   - Free tier: 1 insight/tuần, Premium: full weekly + monthly

#### Custom Reports (F3.7)
10. `ReportType` enum:
    - incomeVsExpense (thu chi theo thời gian)
    - categoryBreakdown (phân tích theo danh mục — pie, bar, treemap)
    - trendAnalysis (xu hướng 6-12 tháng)
    - netWorthOverTime (tài sản ròng theo thời gian)
    - cashFlowStatement (báo cáo dòng tiền)
    - taxSummary (tổng kết thuế cho freelancer)
    - custom (báo cáo tùy chỉnh)

11. `ReportTemplate` model:
    - id: UUID
    - name: String
    - type: ReportType
    - dateRange: ReportDateRange
    - includedAccountIds: [UUID]? (nil = all)
    - includedCategoryIds: [UUID]? (nil = all)
    - chartTypes: [ChartType]
    - groupBy: ReportGroupBy
    - isDefault: Bool (system templates)
    - createdAt: Date

12. `ReportDateRange` enum:
    - thisWeek
    - thisMonth
    - lastMonth
    - last3Months
    - last6Months
    - thisYear
    - lastYear
    - custom(start: Date, end: Date)

13. `ChartType` enum:
    - pieChart
    - barChart
    - lineChart
    - stackedBarChart
    - areaChart
    - treemap

14. `ReportGroupBy` enum:
    - day
    - week
    - month
    - quarter
    - year
    - category
    - account

15. `GeneratedReport` model:
    - id: UUID
    - template: ReportTemplate
    - title: String
    - generatedAt: Date
    - dateRange: ClosedRange<Date>
    - sections: [ReportSection]
    - summary: ReportSummary

16. `ReportSection` model:
    - title: String
    - chartType: ChartType
    - dataPoints: [ReportDataPoint]
    - subtitle: String? (mô tả ngắn)

17. `ReportDataPoint` model:
    - label: String
    - value: Decimal
    - percentage: Double?
    - color: String (hex)
    - children: [ReportDataPoint]? (for treemap/drill-down)

18. `ReportSummary` model:
    - totalIncome: Decimal
    - totalExpense: Decimal
    - netAmount: Decimal (income - expense)
    - topExpenseCategory: String
    - topIncomeSource: String
    - comparisonWithPreviousPeriod: Decimal? (% change)

19. `GenerateReportUseCase` (protocol + implementation):
    - Input: ReportTemplate
    - Output: GeneratedReport
    - Logic: query transactions theo template filters → aggregate → build sections

20. `ExportReportUseCase` (protocol + implementation):
    - Input: GeneratedReport, format: ExportFormat
    - Output: Data (file content)
    - ExportFormat enum: pdf, csv, image (PNG share card)

21. `PDFReportGenerator`:
    - Generate PDF đẹp từ GeneratedReport
    - Header: app logo + report title + date range
    - Summary section: key metrics cards
    - Chart sections: render Swift Charts → PDF
    - Footer: generated date, disclaimer
    - A4 format, support VND formatting

22. `ScheduleReportUseCase` (protocol + implementation):
    - Input: ReportTemplate, schedule: ReportSchedule
    - Schedule enum: weekly(dayOfWeek: Int), monthly(dayOfMonth: Int)
    - Delivery: email (nếu configured) + in-app notification
    - Logic: register background task → generate report → notify

### FinanceData
23. `InsightEntity` @Model:
    - All fields from FinancialInsight
    - Index on: (createdAt DESC), (type), (isRead)

24. `InsightRepositoryImpl`:
    - saveInsights([FinancialInsight])
    - fetchUnread() -> [FinancialInsight]
    - fetchAll(limit: Int, offset: Int) -> [FinancialInsight]
    - markAsRead(id: UUID)
    - markAllAsRead()
    - deleteOldInsights(olderThan: Date) — cleanup > 3 tháng

25. `ReportTemplateEntity` @Model:
    - All fields from ReportTemplate
    - Index on: (createdAt DESC)

26. `ReportScheduleEntity` @Model:
    - templateId: UUID, schedule: String (encoded), lastGeneratedAt: Date?, isActive: Bool

27. `ReportRepositoryImpl`:
    - saveTemplate(ReportTemplate)
    - fetchTemplates() -> [ReportTemplate]
    - deleteTemplate(id: UUID)
    - saveSchedule(templateId: UUID, schedule: ReportSchedule)
    - fetchActiveSchedules() -> [(ReportTemplate, ReportSchedule)]

### FinanceUI
28. `InsightCard` — card hiển thị một insight:
    - Icon (theo InsightType) + severity color indicator
    - Title (bold) + description
    - Action button nếu actionable (VD: "Xem chi tiết", "Tạo budget")
    - Mini chart/data visualization nếu có dataPoints

29. `InsightBadge` — badge severity:
    - Colored dot: info (blue), warning (yellow), alert (red), positive (green)

30. `WeeklyDigestCard` — card tổng kết tuần:
    - Tổng thu, tổng chi, so sánh tuần trước
    - Top 3 categories chart (horizontal bar)
    - Key insight highlight

31. `ReportChartView` — generic chart component dùng Swift Charts:
    - Input: ChartType + [ReportDataPoint]
    - Render pie chart, bar chart, line chart, stacked bar, area chart
    - Interactive: tap segment → highlight + show detail
    - Animated transitions

32. `ReportSummaryCard` — card tổng kết report:
    - Income / Expense / Net
    - Comparison badge: "+15% vs tháng trước"
    - Top category highlight

33. `PDFPreviewView` — preview PDF trước khi export/share

34. `ShareReportSheet` — share sheet với options:
    - PDF, CSV, Image (share card)
    - AirDrop, Messages, Email, Save to Files

### iOS
35. `InsightsView` — tab/section hiển thị insights:
    - Carousel unread insights (horizontal scroll)
    - "Tuần này" section: weekly digest
    - "Tất cả insights" list (grouped by date)
    - Pull-to-refresh → regenerate insights
    - Empty state: "Cần thêm dữ liệu để tạo insights" (< 1 tháng data)

36. `InsightsViewModel` (@Observable):
    - Dependencies: GenerateInsightsUseCase, InsightRepository, InsightDeliveryService
    - State: insights: [FinancialInsight], weeklyDigest: FinancialInsight?
    - isLoading: Bool, unreadCount: Int
    - Methods: loadInsights(), markAsRead(UUID), refreshInsights()
    - Auto-refresh khi có transactions mới

37. `ReportsView` — main reports screen:
    - Tabs: "Có sẵn" (default templates) + "Tùy chỉnh" (user templates)
    - Grid/list of report templates
    - Tap template → generate + show report
    - FAB: "Tạo báo cáo mới"

38. `ReportsViewModel` (@Observable):
    - Dependencies: GenerateReportUseCase, ExportReportUseCase, ReportRepository
    - State: templates: [ReportTemplate], generatedReport: GeneratedReport?
    - isGenerating: Bool, exportFormat: ExportFormat?
    - Methods: generateReport(ReportTemplate), exportReport(ExportFormat), createTemplate(), deleteTemplate()

39. `ReportDetailView` — hiển thị report đã generate:
    - Summary card top
    - Chart sections (scrollable)
    - Toolbar: Share, Export PDF, Export CSV
    - Date range picker để thay đổi kỳ báo cáo

40. `ReportBuilderView` — tạo custom report template:
    - Step 1: Chọn loại báo cáo (ReportType)
    - Step 2: Chọn date range
    - Step 3: Chọn accounts, categories filter
    - Step 4: Chọn chart types
    - Step 5: Đặt tên + save template

41. `ReportScheduleView` — cài đặt schedule cho report:
    - Toggle on/off
    - Frequency picker: weekly / monthly
    - Day picker
    - Email input (optional)

42. Navigation integration:
    - Tab "Báo cáo" chứa cả Insights + Reports
    - Segmented control: "Insights" | "Báo cáo"
    - Badge trên tab cho unread insights count
    - Dashboard → "Xem báo cáo" link

### macOS
43. `InsightsMacView`:
    - Sidebar section "Insights" với unread count badge
    - Main content: list view với richer detail
    - Click insight → expand inline với full data + chart

44. `ReportsMacView`:
    - Sidebar: templates list
    - Main: generated report với larger charts
    - Toolbar: Export PDF (⌘E), Share (⌘⇧S), Print (⌘P)
    - Drag PDF report to Finder to save

45. `ReportBuilderMacView`:
    - Single form layout (không cần step-by-step như iOS)
    - Live preview bên phải khi thay đổi options
    - Keyboard: ⌘⇧R → new report

46. Keyboard shortcuts:
    - ⌘R: Refresh insights/reports
    - ⌘E: Export current report as PDF
    - ⌘P: Print report
    - ⌘⇧R: New custom report

### Tests
47. `GenerateInsightsUseCaseTests`:
    - Category spending +40% vs average → spendingAnomaly insight
    - Recurring small expenses → savingsOpportunity ("giảm café = tiết kiệm X/năm")
    - Weekend spending > weekday → patternDetection insight
    - Budget at 85% with 20 days left → budgetWarning
    - < 1 month data → returns empty/minimal insights
    - No transactions → returns empty

48. `AnomalyDetectionServiceTests`:
    - Spending 2 standard deviations above mean → isAnomaly = true
    - Normal spending → isAnomaly = false
    - Only 1 month data → no anomaly detection (not enough data)
    - Zero spending in previously active category → flagged

49. `SpendingPatternServiceTests`:
    - Daily café purchases → detect pattern "Mua café hàng ngày"
    - Weekend restaurant visits → detect "Chi tiêu ăn ngoài cuối tuần"
    - Random spending → no pattern detected

50. `GenerateReportUseCaseTests`:
    - Income vs Expense report → correct totals, correct grouping
    - Category breakdown → percentages sum to 100%
    - Trend analysis → 6 months data points
    - Filter by account → only transactions from that account
    - Filter by category → correct subset
    - Empty date range → empty report (not error)

51. `PDFReportGeneratorTests`:
    - Generated PDF is valid (non-empty Data)
    - PDF contains report title and date range
    - VND amounts formatted correctly (1.000.000 ₫)

52. `ExportReportUseCaseTests`:
    - Export PDF → valid PDF data
    - Export CSV → valid CSV with headers + rows
    - Export image → valid PNG data

53. `InsightDeliveryServiceTests`:
    - Free tier: 1 insight/week max
    - Premium: full weekly digest delivered
    - Schedule respects timezone
    - No duplicate delivery for same insight
