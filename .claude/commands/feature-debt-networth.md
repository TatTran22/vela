---
description: "Triển khai features Debt & Net Worth — F3.5 Debt Tracking + F3.6 Lend/Borrow + F3.8 Net Worth Dashboard (Premium)"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: Debt Tracking, Lend/Borrow & Net Worth

## Feature Spec References
- F3.5: Debt Tracking (loans, credit card debt, payment schedules, amortization)
- F3.6: Cho vay/mượn cá nhân (Lend/Borrow — track tiền cho vay/mượn, reminders)
- F3.8: Net Worth Tracker (assets vs liabilities, historical tracking, chart)

## Đọc Context Trước
1. `CLAUDE.md` — tech stack, code rules, module structure
2. `FinanceApp-Feature-Specification.md` → section 6.2 "F3.5 — Debt Tracking" + "F3.6 — Cho vay/mượn cá nhân" + section 6.3 "F3.8 — Net Worth Tracker"
3. `docs/DATA-MODEL.md` → Debt entity, Account entity, Transaction entity
4. `docs/ARCHITECTURE.md` → Clean Architecture layers
5. `docs/CONVENTIONS.md` → Swift naming, Decimal usage

## Tasks

### FinanceCore

#### Debt Tracking (F3.5)
1. `Debt` model (mở rộng từ DATA-MODEL):
   - id: UUID
   - name: String
   - type: DebtType (owedByMe, owedToMe)
   - category: DebtCategory
   - principalAmount: Decimal
   - remainingAmount: Decimal
   - interestRate: Decimal? (%/năm)
   - interestType: InterestType? (fixed, floating)
   - startDate: Date
   - dueDate: Date?
   - termMonths: Int? (kỳ hạn tháng)
   - paymentFrequency: PaymentFrequency
   - minimumPayment: Decimal?
   - personName: String? (cho vay cá nhân)
   - linkedAccountId: UUID?
   - notes: String?
   - isActive: Bool
   - createdAt: Date
   - updatedAt: Date

2. `DebtCategory` enum:
   - bankLoan (vay ngân hàng)
   - creditCard (thẻ tín dụng)
   - personalLoan (vay cá nhân)
   - mortgage (vay mua nhà)
   - vehicleLoan (vay mua xe)
   - studentLoan (vay học)
   - other

3. `PaymentFrequency` enum:
   - monthly
   - biweekly
   - weekly
   - quarterly
   - yearly
   - custom(days: Int)

4. `PaymentScheduleEntry` model:
   - date: Date
   - paymentNumber: Int
   - totalPayment: Decimal
   - principalPayment: Decimal
   - interestPayment: Decimal
   - remainingBalance: Decimal
   - isPaid: Bool
   - linkedTransactionId: UUID?

5. `DebtPayoffStrategy` enum:
   - snowball (nợ nhỏ nhất trước — tâm lý tốt)
   - avalanche (lãi suất cao nhất trước — tối ưu tài chính)
   - custom (tùy chỉnh thứ tự)

6. `DebtPayoffPlan` model:
   - strategy: DebtPayoffStrategy
   - debts: [Debt] (sorted theo strategy)
   - monthlyBudget: Decimal (tổng tiền trả nợ/tháng)
   - projectedPayoffDate: Date
   - totalInterestPaid: Decimal
   - totalInterestSaved: Decimal (so với minimum payment only)
   - schedule: [DebtPayoffMonthEntry]

7. `DebtPayoffMonthEntry` model:
   - month: Date
   - payments: [(debtId: UUID, amount: Decimal, principal: Decimal, interest: Decimal)]
   - totalPaid: Decimal
   - totalRemainingDebt: Decimal

8. `AmortizationCalculator`:
   - calculateMonthlyPayment(principal: Decimal, annualRate: Decimal, termMonths: Int) -> Decimal
   - generateSchedule(debt: Debt) -> [PaymentScheduleEntry]
   - calculateTotalInterest(debt: Debt) -> Decimal
   - calculatePayoffDate(debt: Debt, monthlyPayment: Decimal) -> Date
   - calculateSavingsWithExtraPayment(debt: Debt, extraAmount: Decimal) -> (savedInterest: Decimal, monthsSaved: Int)
   - Handle lãi suất thả nổi (floating): recalculate khi rate thay đổi
   - Handle lãi giảm dần (VN-style diminishing balance)

9. `GeneratePayoffPlanUseCase` (protocol + implementation):
   - Input: debts: [Debt], strategy: DebtPayoffStrategy, monthlyBudget: Decimal
   - Output: DebtPayoffPlan
   - Logic: sort debts by strategy → allocate minimum payments → extra to target debt → project timeline

10. `CreateDebtUseCase` (protocol + implementation):
    - Input: Debt properties
    - Output: Debt
    - Validate: principalAmount > 0, interestRate >= 0, termMonths > 0
    - Auto-generate payment schedule

11. `RecordDebtPaymentUseCase` (protocol + implementation):
    - Input: debtId: UUID, amount: Decimal, date: Date
    - Output: Transaction (expense type) + updated Debt
    - Logic: create transaction, reduce remainingAmount, mark schedule entry paid
    - If remainingAmount == 0 → mark debt isActive = false

#### Lend/Borrow (F3.6)
12. `LendBorrowRecord` model:
    - id: UUID
    - type: LendBorrowType
    - personName: String
    - personContact: String? (phone/email)
    - amount: Decimal
    - remainingAmount: Decimal
    - currency: CurrencyCode
    - date: Date (ngày cho vay/mượn)
    - dueDate: Date? (hạn trả)
    - note: String?
    - reminderEnabled: Bool
    - reminderDate: Date?
    - isSettled: Bool (đã trả xong)
    - createdAt: Date
    - updatedAt: Date

13. `LendBorrowType` enum:
    - lent (tôi cho người khác mượn)
    - borrowed (tôi mượn người khác)

14. `LendBorrowPayment` model:
    - id: UUID
    - recordId: UUID
    - amount: Decimal
    - date: Date
    - note: String?
    - linkedTransactionId: UUID?

15. `CreateLendBorrowUseCase` (protocol + implementation):
    - Input: LendBorrowRecord properties
    - Output: LendBorrowRecord
    - Validate: amount > 0, personName not empty
    - Free tier: max 3 records, Premium: unlimited
    - Auto-create transaction: lent → expense (money out), borrowed → income (money in)

16. `RecordLendBorrowPaymentUseCase` (protocol + implementation):
    - Input: recordId, amount, date
    - Output: LendBorrowPayment + updated LendBorrowRecord
    - Logic: reduce remainingAmount, create reverse transaction
    - If remainingAmount == 0 → mark isSettled = true

17. `LendBorrowReminderService` (protocol + implementation):
    - scheduleReminder(recordId: UUID, date: Date)
    - cancelReminder(recordId: UUID)
    - checkOverdue() -> [LendBorrowRecord] (quá hạn chưa trả)
    - Push notification: "Nhắc: [Tên] còn nợ bạn 500.000₫, đến hạn ngày 15/03"

#### Net Worth (F3.8)
18. `AssetType` enum:
    - cashAndBank (tiền mặt + ngân hàng — auto từ accounts)
    - investment (đầu tư — cổ phiếu, quỹ)
    - realEstate (bất động sản — nhập thủ công)
    - gold (vàng SJC — auto-update giá)
    - crypto (tiền điện tử)
    - vehicle (xe cộ)
    - other

19. `ManualAsset` model:
    - id: UUID
    - name: String
    - type: AssetType
    - currentValue: Decimal
    - currency: CurrencyCode
    - purchaseValue: Decimal? (giá mua)
    - purchaseDate: Date?
    - note: String?
    - autoUpdatePrice: Bool (cho vàng, crypto)
    - lastUpdatedAt: Date
    - createdAt: Date

20. `NetWorthSnapshot` model:
    - id: UUID
    - date: Date
    - totalAssets: Decimal
    - totalLiabilities: Decimal
    - netWorth: Decimal (assets - liabilities)
    - assetBreakdown: [AssetBreakdownEntry]
    - liabilityBreakdown: [LiabilityBreakdownEntry]

21. `AssetBreakdownEntry` model:
    - type: AssetType
    - name: String
    - value: Decimal
    - currency: CurrencyCode
    - source: AssetSource (account, manualAsset, calculated)

22. `LiabilityBreakdownEntry` model:
    - type: DebtCategory
    - name: String
    - value: Decimal
    - currency: CurrencyCode
    - source: LiabilitySource (debt, creditCard, lendBorrow)

23. `CalculateNetWorthUseCase` (protocol + implementation):
    - Output: NetWorthSnapshot
    - Assets from:
      a. Account balances (cash, bank, savings, investment, eWallet)
      b. Manual assets (real estate, gold, crypto, vehicles)
      c. Money lent to others (LendBorrow.lent, unsettled)
    - Liabilities from:
      a. Debts (remainingAmount)
      b. Credit card balances (negative account balance)
      c. Money borrowed (LendBorrow.borrowed, unsettled)
    - Multi-currency: convert tất cả về đồng tiền chính

24. `TrackNetWorthHistoryUseCase` (protocol + implementation):
    - takeSnapshot() — chụp snapshot hiện tại, lưu vào history
    - Auto-snapshot: 1 lần/tuần hoặc khi có thay đổi lớn (> 5%)
    - getHistory(months: Int) -> [NetWorthSnapshot]

25. `GoldPriceService` protocol (đặc thù VN):
    - fetchSJCGoldPrice() async throws -> Decimal (giá vàng SJC/lượng)
    - fetchWorldGoldPrice() async throws -> Decimal (giá vàng thế giới/ounce)
    - Auto-update daily

### FinanceData
26. `DebtEntity` @Model (mở rộng từ DATA-MODEL):
    - All fields from Debt model
    - Indexes: (isActive), (type), (dueDate)

27. `PaymentScheduleEntity` @Model:
    - All fields from PaymentScheduleEntry
    - debtId: UUID
    - Index on: (debtId, date)

28. `DebtRepositoryImpl`:
    - save(debt: Debt)
    - fetchActive() -> [Debt]
    - fetchAll() -> [Debt]
    - update(debt: Debt)
    - fetchSchedule(debtId: UUID) -> [PaymentScheduleEntry]
    - markPaymentPaid(scheduleEntryId: UUID, transactionId: UUID)

29. `LendBorrowRecordEntity` @Model:
    - All fields from LendBorrowRecord
    - Indexes: (isSettled), (personName), (dueDate)

30. `LendBorrowPaymentEntity` @Model:
    - All fields from LendBorrowPayment
    - Index on: (recordId, date)

31. `LendBorrowRepositoryImpl`:
    - save(record: LendBorrowRecord)
    - fetchActive() -> [LendBorrowRecord] (unsettled)
    - fetchByPerson(name: String) -> [LendBorrowRecord]
    - fetchAll() -> [LendBorrowRecord]
    - savePayment(LendBorrowPayment)
    - fetchPayments(recordId: UUID) -> [LendBorrowPayment]
    - countActiveRecords() -> Int (for free tier limit check)

32. `ManualAssetEntity` @Model:
    - All fields from ManualAsset
    - Index on: (type)

33. `NetWorthSnapshotEntity` @Model:
    - All fields from NetWorthSnapshot (breakdown encoded as JSON)
    - Index on: (date DESC)

34. `NetWorthRepositoryImpl`:
    - saveSnapshot(NetWorthSnapshot)
    - fetchHistory(limit: Int) -> [NetWorthSnapshot]
    - saveManualAsset(ManualAsset)
    - fetchManualAssets() -> [ManualAsset]
    - updateManualAsset(ManualAsset)
    - deleteManualAsset(id: UUID)

### FinanceUI
35. `DebtCard` — card hiển thị một khoản nợ:
    - Name + type icon + remaining/principal
    - Progress bar: đã trả / tổng gốc
    - Interest rate badge
    - Next payment date + amount
    - Color-coded: active (blue), overdue (red), paid-off (green)

36. `PaymentScheduleTable` — bảng lịch trả nợ:
    - Columns: #, Date, Payment, Principal, Interest, Remaining
    - Highlight current/next payment
    - Paid rows: strikethrough + checkmark

37. `PayoffStrategyComparison` — so sánh Snowball vs Avalanche:
    - Side-by-side: total interest, payoff date, monthly timeline
    - Highlight savings difference

38. `LendBorrowPersonRow` — row cho người vay/mượn:
    - Avatar placeholder + person name
    - Amount owed (red for borrowed, green for lent)
    - Due date countdown: "Còn 5 ngày" / "Quá hạn 3 ngày"
    - Action: nhắc trả / ghi nhận đã trả

39. `NetWorthCard` — card tổng quan tài sản ròng:
    - Net Worth số lớn
    - Trend arrow: ↑ +5.2% vs tháng trước
    - Mini stacked area chart (assets vs liabilities)

40. `NetWorthChart` — full stacked area chart:
    - Swift Charts: area chart
    - X-axis: thời gian (months)
    - Y-axis: amount
    - 2 layers: total assets (green) stacked with total liabilities (red)
    - Net worth line overlay
    - Interactive: tap point → show snapshot detail

41. `AssetBreakdownChart` — pie/donut chart tài sản:
    - Segments by AssetType, color-coded
    - Center: total assets amount
    - Tap segment → detail list

42. `ManualAssetRow` — row cho tài sản nhập thủ công:
    - Icon (by type) + name + current value
    - Change vs purchase value: "+15.2%" or "−3.1%"
    - Last updated date

### iOS
43. `DebtListView` — danh sách nợ:
    - Segmented: "Nợ của tôi" | "Người khác nợ tôi"
    - Summary card top: tổng nợ, tổng cho vay, net
    - DebtCard list
    - FAB: "Thêm khoản nợ"
    - Empty state: "Chưa có khoản nợ nào"

44. `DebtListViewModel` (@Observable):
    - Dependencies: DebtRepository, CreateDebtUseCase, GeneratePayoffPlanUseCase
    - State: debts: [Debt], totalOwed: Decimal, totalLent: Decimal
    - Methods: loadDebts(), addDebt(), deleteDebt(), generatePayoffPlan()

45. `DebtDetailView` — chi tiết khoản nợ:
    - Header: name, amount, interest rate, remaining
    - Progress section: paid vs total
    - Payment schedule table (scrollable)
    - "Trả nợ" button → record payment
    - "Xem lịch trả" → full amortization schedule
    - Extra payment calculator: "Nếu trả thêm X/tháng → tiết kiệm Y lãi, xong sớm Z tháng"

46. `DebtFormView` — form tạo/sửa khoản nợ:
    - Name, category (picker), principal amount
    - Interest rate + type (fixed/floating) toggle
    - Term months, payment frequency
    - Due date, linked account
    - Notes

47. `PayoffPlanView` — hiển thị payoff strategy:
    - Strategy picker: Snowball / Avalanche / Custom
    - Monthly budget input
    - Timeline visualization
    - Strategy comparison card
    - "Áp dụng" button

48. `LendBorrowListView` — danh sách cho vay/mượn:
    - Grouped by person
    - Person header: tổng net (tôi nợ họ - họ nợ tôi)
    - Records list per person
    - "Thêm" FAB

49. `LendBorrowFormView` — form tạo record:
    - Type toggle: Cho vay / Mượn
    - Person name (autocomplete từ history)
    - Amount, date, due date
    - Note, reminder toggle + date

50. `LendBorrowDetailView`:
    - Record info + payment history
    - "Ghi nhận thanh toán" button
    - Partial payment support
    - "Nhắc trả" → share message / create reminder

51. `NetWorthView` — main net worth screen:
    - Net Worth hero number + trend
    - NetWorthChart (area chart over time)
    - Assets section: AssetBreakdownChart + list
    - Liabilities section: breakdown + list
    - "Thêm tài sản" button cho manual assets

52. `NetWorthViewModel` (@Observable):
    - Dependencies: CalculateNetWorthUseCase, TrackNetWorthHistoryUseCase, NetWorthRepository
    - State: currentNetWorth: NetWorthSnapshot?, history: [NetWorthSnapshot]
    - manualAssets: [ManualAsset], trend: Decimal (% change)
    - Methods: loadNetWorth(), addManualAsset(), updateAsset(), refreshHistory()

53. `ManualAssetFormView` — form thêm/sửa tài sản:
    - Type picker (real estate, gold, crypto, vehicle, other)
    - Name, current value, purchase value, purchase date
    - Currency picker
    - Auto-update toggle (cho gold SJC, crypto)
    - Note

54. Navigation integration:
    - Tab "Tài chính" hoặc sub-section trong "Thêm":
      - Debt Tracking
      - Cho vay/Mượn
      - Net Worth
    - Dashboard widget: Net Worth mini card
    - Notification: "Khoản nợ X đến hạn thanh toán ngày Y"

### macOS
55. `DebtMacView`:
    - Sidebar: debt list (grouped by category)
    - Main: debt detail + schedule table
    - Toolbar: Add debt (⌘N), Payoff plan, Export schedule

56. `LendBorrowMacView`:
    - Table view: Person | Type | Amount | Remaining | Due Date | Status
    - Sortable columns
    - Right-click: Record payment, Send reminder, Delete

57. `NetWorthMacView`:
    - Full-width chart area (larger, more detailed chart)
    - Split: Assets table | Liabilities table (below chart)
    - Keyboard: ⌘⇧N → add manual asset

58. Keyboard shortcuts:
    - ⌘N: Add new debt/asset (context-dependent)
    - ⌘⇧D: Open Debt Tracking
    - ⌘⇧W: Open Net Worth
    - ⌘D: Record debt payment (khi đang xem debt detail)

### Tests
59. `AmortizationCalculatorTests`:
    - Monthly payment calculation: 100M VND, 8%/năm, 120 tháng → expected payment
    - Total interest calculation correct
    - Generate schedule: 120 entries, last entry remainingBalance ≈ 0
    - Extra payment: reduces total interest + months
    - Floating rate: recalculate after rate change
    - Edge: 0% interest → principal only payments
    - Edge: 1 month term → single payment

60. `GeneratePayoffPlanUseCaseTests`:
    - Snowball: debts sorted by remainingAmount ASC
    - Avalanche: debts sorted by interestRate DESC
    - Monthly budget < sum of minimums → error
    - Single debt → straightforward plan
    - All debts paid off → projectedPayoffDate correct

61. `CreateDebtUseCaseTests`:
    - Valid debt → saved correctly
    - principalAmount <= 0 → validation error
    - interestRate < 0 → validation error
    - Credit card debt → no term required

62. `RecordDebtPaymentUseCaseTests`:
    - Payment reduces remainingAmount correctly
    - Full payoff → debt marked inactive
    - Payment > remainingAmount → error or cap at remaining
    - Transaction created with correct type and amount

63. `CreateLendBorrowUseCaseTests`:
    - Lent record → expense transaction created
    - Borrowed record → income transaction created
    - Free tier: 4th record → error (limit 3)
    - Premium: unlimited records
    - Empty person name → validation error

64. `RecordLendBorrowPaymentUseCaseTests`:
    - Partial payment → remaining updated
    - Full payment → isSettled = true
    - Payment > remaining → error

65. `LendBorrowReminderServiceTests`:
    - Schedule reminder → notification created
    - Overdue check → returns records past dueDate
    - Cancel reminder → notification removed

66. `CalculateNetWorthUseCaseTests`:
    - Assets = sum of accounts + manual assets + lent money
    - Liabilities = sum of debts + borrowed money + credit card balance
    - Net worth = assets - liabilities
    - Multi-currency: all converted to primary currency
    - No data → net worth = 0

67. `TrackNetWorthHistoryUseCaseTests`:
    - takeSnapshot → saved to history
    - History sorted by date DESC
    - Auto-snapshot triggers on > 5% change

68. `GoldPriceServiceTests`:
    - Fetch SJC price → valid Decimal > 0
    - Network error → proper error handling
    - Cache: return cached price if < 1 hour old
