---
description: "Triển khai Freelancer & Business tools — F4.6 Client/Project tracking + F4.7 Business/Personal separation"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: Freelancer & Business Tools

## Feature Spec References
- F4.6: Income by Client/Project
- F4.7: Business vs Personal separation

## Đọc Context Trước
1. `CLAUDE.md` — tech stack, architecture rules, code conventions
2. `FinanceApp-Feature-Specification.md` → Section 7.3 (Freelancer/Business Features)
3. `docs/DATA-MODEL.md` — Transaction, Account, Category, Tag
4. `docs/ARCHITECTURE.md` — MVVM + Clean Architecture patterns
5. `docs/CONVENTIONS.md` — Swift naming, file organization

## Tasks

### FinanceCore

1. `Client` model:
   - id: UUID
   - name: String (VD: "Công ty ABC", "Anh Minh Design")
   - email: String?
   - phone: String?
   - company: String? — tên công ty (nếu client là cá nhân thuộc công ty)
   - address: String?
   - taxCode: String? — Mã số thuế (VN: 10 hoặc 13 chữ số)
   - notes: String?
   - color: String — hex color để phân biệt trên chart
   - isActive: Bool
   - totalRevenue: Decimal — cache tổng thu nhập từ client
   - createdAt: Date
   - updatedAt: Date
   - deletedAt: Date?

2. `ProjectStatus` enum:
   ```swift
   enum ProjectStatus: String, Codable, Sendable {
       case draft        // Đang soạn proposal
       case active       // Đang thực hiện
       case onHold       // Tạm dừng
       case completed    // Đã hoàn thành
       case cancelled    // Đã hủy
   }
   ```

3. `ProjectPricingType` enum:
   ```swift
   enum ProjectPricingType: String, Codable, Sendable {
       case fixedPrice   // Giá cố định (VD: 15.000.000₫ cho 1 website)
       case hourly       // Tính theo giờ (VD: 500.000₫/giờ)
       case milestone    // Thanh toán theo milestones
       case retainer     // Phí cố định hàng tháng
   }
   ```

4. `Project` model:
   - id: UUID
   - name: String (VD: "Website redesign", "Logo thiết kế")
   - client: Client
   - status: ProjectStatus
   - pricingType: ProjectPricingType
   - budgetAmount: Decimal — tổng giá trị hợp đồng
   - hourlyRate: Decimal? — (cho pricing type hourly)
   - currency: CurrencyCode (mặc định VND)
   - startDate: Date?
   - endDate: Date?
   - deadline: Date?
   - description: String?
   - totalIncome: Decimal — cache tổng đã nhận
   - totalExpense: Decimal — cache tổng chi phí cho project
   - createdAt: Date
   - updatedAt: Date
   - deletedAt: Date?

5. `ProjectMilestone` model:
   - id: UUID
   - projectId: UUID
   - name: String (VD: "Đặt cọc", "Bàn giao phase 1", "Nghiệm thu")
   - amount: Decimal
   - dueDate: Date?
   - isPaid: Bool
   - paidAt: Date?
   - invoiceId: UUID?
   - sortOrder: Int

6. `InvoiceStatus` enum:
   ```swift
   enum InvoiceStatus: String, Codable, Sendable {
       case draft        // Đang soạn
       case sent         // Đã gửi cho client
       case viewed       // Client đã xem (nếu track được)
       case paid         // Đã thanh toán
       case overdue      // Quá hạn
       case cancelled    // Đã hủy
   }
   ```

7. `Invoice` model:
   - id: UUID
   - invoiceNumber: String — auto-generate (VD: "INV-2026-001")
   - client: Client
   - project: Project?
   - items: [InvoiceItem]
   - subtotal: Decimal — tổng trước thuế
   - taxRate: Decimal? — % thuế (VN freelancer: 2% doanh thu < 100tr, 10% VAT)
   - taxAmount: Decimal?
   - totalAmount: Decimal — tổng sau thuế
   - currency: CurrencyCode
   - issueDate: Date
   - dueDate: Date
   - status: InvoiceStatus
   - notes: String? — ghi chú/điều khoản thanh toán
   - bankInfo: BankPaymentInfo? — thông tin CK cho khách thanh toán
   - createdAt: Date
   - updatedAt: Date

8. `InvoiceItem` model:
   - id: UUID
   - description: String (VD: "Thiết kế homepage", "Consulting 8 giờ")
   - quantity: Decimal (số lượng hoặc số giờ)
   - unitPrice: Decimal
   - amount: Decimal — quantity × unitPrice

9. `BankPaymentInfo` model:
   ```swift
   struct BankPaymentInfo: Codable, Sendable {
       var bankName: String        // VD: "Vietcombank"
       var bankCode: String        // VD: "VCB" (NAPAS code)
       var accountNumber: String   // Số tài khoản
       var accountHolder: String   // Tên chủ tài khoản
       var branch: String?         // Chi nhánh
   }
   ```

10. `TransactionContext` enum:
    ```swift
    enum TransactionContext: String, Codable, Sendable {
        case personal     // Chi tiêu cá nhân
        case business     // Chi tiêu công việc
    }
    ```

11. Extend `Transaction` model (hoặc thêm vào metadata):
    - context: TransactionContext (mặc định .personal)
    - clientId: UUID? — link đến client
    - projectId: UUID? — link đến project
    - invoiceId: UUID? — link đến invoice

12. `CreateClientUseCase`:
    - Validate: name not empty
    - Validate taxCode format (VN: 10 hoặc 13 digits)
    - Set default color

13. `CreateProjectUseCase`:
    - Validate: name not empty, client exists
    - Validate budgetAmount > 0
    - Tạo milestones mặc định cho milestone pricing type
    - Set status = .draft

14. `UpdateProjectStatusUseCase`:
    - Validate state transitions (draft → active → completed/onHold/cancelled)
    - Khi completed: tính final profitability

15. `GetProjectProfitabilityUseCase`:
    - Input: projectId
    - Tính: totalIncome - totalExpense = profit
    - Profit margin: profit / totalIncome × 100
    - So sánh với budget: over/under budget

16. `CreateInvoiceUseCase`:
    - Auto-generate invoiceNumber: "INV-{year}-{sequential}"
    - Tính subtotal, taxAmount, totalAmount
    - Validate items not empty
    - Set status = .draft

17. `CalculateFreelancerTaxUseCase` (VN tax rules):
    ```
    Thuế TNCN cho freelancer VN (cá nhân không có ĐKKD):
    - Doanh thu < 100.000.000₫/năm: thuế = 2% × doanh thu (thuế TNCN = 1% + thuế GTGT = 1%)

    Freelancer có ĐKKD (hộ kinh doanh):
    - Thuế TNCN: 0.5-2% tùy ngành
    - Thuế GTGT: 1-5% tùy ngành
    - Thường áp dụng: thiết kế/IT = 2% TNCN + 5% GTGT

    Input: tổng doanh thu năm, loại đăng ký
    Output: ước tính thuế phải nộp, số tiền sau thuế
    ```

18. `GetClientRevenueReportUseCase`:
    - Tổng revenue theo client, sorted DESC
    - Revenue by period (tháng/quý/năm)
    - Client ranking: top clients by revenue

19. `GetBusinessVsPersonalReportUseCase`:
    - Split tất cả transactions theo context (business/personal)
    - Tính riêng: income, expense, net cho mỗi context
    - So sánh tỷ lệ business/personal

20. `ExportTaxReportUseCase` (VN tax-friendly):
    - Input: year, context = .business
    - Output: structured data cho kê khai thuế:
      - Tổng doanh thu từ freelance
      - Chi tiết theo client
      - Chi phí hợp lý (business expenses)
      - Ước tính thuế TNCN
    - Export formats: CSV, PDF
    - CSV columns: Ngày | Mô tả | Client | Project | Thu nhập | Chi phí | Ghi chú

21. `GenerateInvoicePDFUseCase`:
    - Input: Invoice
    - Output: PDF Data
    - Template: professional invoice layout
    - Includes: logo area, invoice info, client info, items table, totals, bank info + VietQR
    - Vietnamese + English bilingual option

### FinanceData

22. `ClientEntity` @Model:
    - Indexes: (name), (isActive), (taxCode)
    - Relationship: projects → [ProjectEntity]

23. `ProjectEntity` @Model:
    - Indexes: (clientId), (status), (startDate)
    - Relationship: client → ClientEntity, milestones → [ProjectMilestoneEntity]

24. `ProjectMilestoneEntity` @Model:
    - Indexes: (projectId, sortOrder)

25. `InvoiceEntity` @Model:
    - Indexes: (invoiceNumber) UNIQUE, (clientId), (status), (dueDate)
    - Relationship: client → ClientEntity, project → ProjectEntity?

26. `InvoiceItemEntity` @Model

27. `ClientRepositoryImpl`:
    - CRUD clients
    - getActiveClients, searchClients(query:)
    - getClientWithRevenue(clientId:) — client + total revenue

28. `ProjectRepositoryImpl`:
    - CRUD projects
    - getProjectsByClient(clientId:)
    - getActiveProjects
    - getProjectWithTransactions(projectId:)

29. `InvoiceRepositoryImpl`:
    - CRUD invoices
    - getInvoicesByClient(clientId:)
    - getInvoicesByStatus(status:)
    - getNextInvoiceNumber(year:) → Int

30. Extend `TransactionEntity`:
    - Thêm field: context (String, "personal"/"business"), clientId (UUID?), projectId (UUID?)
    - Indexes thêm: (context), (clientId), (projectId)

31. Extend `TransactionRepositoryImpl`:
    - getTransactions(context:) — filter by personal/business
    - getTransactions(clientId:)
    - getTransactions(projectId:)
    - getBusinessExpenses(dateRange:) — cho tax report

### FinanceUI

32. `ClientAvatar` — circle với initials + color, hoặc company logo placeholder
33. `ProjectStatusBadge` — colored badge: Draft (xám), Active (xanh), OnHold (vàng), Completed (xanh lá), Cancelled (đỏ)
34. `InvoiceStatusBadge` — badge cho invoice status với color coding
35. `ProfitabilityBar` — horizontal bar: income (xanh) vs expense (đỏ), profit displayed
36. `ContextToggle` — segmented control: "Tất cả | Cá nhân | Công việc" toggle filter
37. `InvoicePreviewCard` — preview card của invoice: number, client, amount, status, due date
38. `TaxEstimateCard` — card hiển thị ước tính thuế: doanh thu, thuế suất, thuế phải nộp
39. `RevenueByClientChart` — horizontal bar chart: revenue per client, sorted DESC
40. `ProjectTimelineView` — horizontal timeline: milestones với status dots

### iOS

41. `ClientListView`:
    - Danh sách clients, search bar
    - Card: tên, company, tổng revenue, số projects active
    - FAB "Thêm khách hàng"
    - Sort: theo tên / revenue / gần đây

42. `ClientListViewModel`:
    - @Observable, inject ClientRepository
    - clients: [Client], searchText: String
    - sortOption: ClientSortOption

43. `ClientDetailView`:
    - Header: name, company, contact info
    - Tabs: Projects | Invoices | Transactions
    - Summary: tổng revenue, projects completed, outstanding invoices

44. `ProjectListView`:
    - Filter by status (segmented control)
    - Card: tên project, client, budget, progress, status
    - Sort: theo deadline / revenue / status

45. `ProjectDetailView`:
    - Header: name, client, status badge, budget
    - Milestones timeline (sortable, mark as paid)
    - Transactions linked to project
    - Profitability summary: income vs expense vs profit

46. `ProjectDetailViewModel`:
    - @Observable
    - project: Project, milestones: [ProjectMilestone]
    - transactions: [Transaction], profitability: ProfitabilityData

47. `CreateInvoiceView`:
    - Step 1: Chọn client (hoặc tạo mới)
    - Step 2: Chọn project (optional)
    - Step 3: Thêm items (description, quantity, unit price)
    - Step 4: Tax settings (2% TNCN, VAT, custom)
    - Step 5: Payment info (bank account, VietQR)
    - Step 6: Preview PDF → Send/Save

48. `CreateInvoiceViewModel`:
    - @Observable
    - Multi-step state management
    - Auto-calculate totals, tax
    - Generate PDF preview

49. `InvoiceDetailView`:
    - Full invoice display (PDF-like layout)
    - Actions: Mark as Sent, Mark as Paid, Download PDF, Share
    - Link to transaction khi đã paid

50. `BusinessPersonalToggleView`:
    - Persistent toggle trên navigation bar (hoặc tab bar)
    - "Cá nhân 👤" | "Công việc 💼" | "Tất cả"
    - Filter ảnh hưởng toàn app: dashboard, transactions, reports
    - Badge cho context khi nhập giao dịch mới

51. `BusinessDashboardView`:
    - Thay thế dashboard chính khi context = .business
    - Revenue tháng này, outstanding invoices
    - Top clients by revenue (mini chart)
    - Upcoming milestones / deadlines
    - Tax estimate year-to-date

52. `TaxReportView`:
    - Chọn năm tài chính
    - Summary: tổng doanh thu, chi phí hợp lý, thuế ước tính
    - Detail: breakdown theo client, theo quý
    - Export: CSV cho kê khai thuế, PDF report
    - Hướng dẫn kê khai: "Doanh thu < 100tr → thuế 2%" vs "Có ĐKKD → thuế theo ngành"

53. `TaxReportViewModel`:
    - @Observable
    - year: Int, totalRevenue: Decimal, totalExpenses: Decimal
    - estimatedTax: Decimal, registrationType: FreelancerRegistrationType
    - quarterlyBreakdown: [QuarterData]

### macOS

54. `ClientProjectSidebarView`:
    - Sidebar: Clients (expandable) → Projects under each client
    - Quick filter: Active / All / Archived
    - Drag transaction onto project → link

55. `InvoiceTableView`:
    - Table: Invoice # | Client | Amount | Status | Issue Date | Due Date
    - Sortable columns
    - Status filter (tabs)
    - Double-click → preview PDF
    - ⌘P → print invoice

56. `BusinessReportsDashboardView`:
    - Multi-panel layout:
      - Revenue by client (bar chart)
      - Monthly revenue trend (line chart)
      - Project profitability (table)
      - Tax summary (card)
    - Export all reports

57. `macOS Keyboard shortcuts`:
    - ⌘⇧C → New client
    - ⌘⇧P → New project
    - ⌘⇧I → New invoice
    - ⌘B → Toggle Business/Personal context
    - ⌘⇧T → Tax report

### Tests

58. CreateClient — validate name required, taxCode format (10/13 digits VN)
59. CreateProject — status transitions (draft→active→completed, không thể completed→draft)
60. ProjectProfitability — income 15tr, expense 3tr → profit 12tr, margin 80%
61. CreateInvoice — auto-generate invoiceNumber sequential, calculate totals
62. FreelancerTax VN — doanh thu 80tr → thuế 2% = 1.6tr; doanh thu 150tr → cần ĐKKD
63. InvoiceItem calculation — quantity 8h × unitPrice 500k = 4.000.000₫
64. BusinessPersonalFilter — filter transactions by context, report separation
65. ExportTaxReport — CSV output đúng format, tổng khớp
66. ClientRevenue — aggregate revenue across projects, sorted correctly
67. MilestonePayment — mark milestone paid → create income transaction → update project total
68. InvoicePDF — generate PDF with correct layout, VietQR embedded
69. TaxCode validation — "0123456789" (10 digits) valid, "0123456789012" (13 digits) valid, "abc" invalid
70. Context toggle — switching context filters all views correctly
