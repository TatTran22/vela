---
description: "Triển khai feature Recurring & Bills — F2.3 Giao dịch lặp lại + F2.7 Nhắc nhở hóa đơn"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: Recurring Transactions & Bill Reminders

## Feature Spec References
- F2.3: Recurring Transactions (templates, auto-create on schedule, quản lý subscription)
- F2.7: Bill Reminders (upcoming bills, push notifications, mark as paid, overdue tracking)

## Đọc Context Trước
1. `CLAUDE.md` — coding conventions, architecture rules
2. `FinanceApp-Feature-Specification.md` → sections 5.2 (F2.3), 5.5 (F2.7)
3. `docs/DATA-MODEL.md` → RecurringRule entity, Bill entity, RecurringFrequency enum
4. `docs/ARCHITECTURE.md` — MVVM + Clean Architecture layers
5. `docs/CONVENTIONS.md` — Swift style guide

## Tasks

### FinanceCore

1. `RecurringFrequency` enum (nếu chưa có):
   ```swift
   enum RecurringFrequency: String, Codable, Sendable {
       case daily
       case weekly
       case biweekly
       case monthly
       case quarterly
       case yearly
   }
   ```

2. `RecurringStatus` enum:
   ```swift
   enum RecurringStatus: String, Codable, Sendable {
       case active      // Đang hoạt động
       case paused      // Tạm dừng
       case completed   // Đã kết thúc (endDate passed)
   }
   ```

3. `RecurringRule` model:
   - id: UUID
   - name: String (VD: "Tiền thuê nhà", "Netflix")
   - frequency: RecurringFrequency
   - interval: Int (VD: every 2 weeks → frequency=weekly, interval=2)
   - nextDate: Date (ngày tạo giao dịch tiếp theo)
   - endDate: Date? (nil = vĩnh viễn)
   - templateAmount: Decimal
   - templateNote: String?
   - templateCategory: Category
   - templateAccount: Account
   - templateType: TransactionType (income/expense)
   - isAutoConfirm: Bool (tự động tạo hay chờ user confirm)
   - reminderDaysBefore: Int (1-3 ngày)
   - status: RecurringStatus
   - isSubscription: Bool (đánh dấu là subscription — Netflix, Spotify...)
   - createdAt: Date
   - updatedAt: Date

4. `BillStatus` enum:
   ```swift
   enum BillStatus: String, Codable, Sendable {
       case upcoming    // Sắp đến hạn
       case due         // Đến hạn hôm nay
       case overdue     // Quá hạn
       case paid        // Đã thanh toán
   }
   ```

5. `Bill` model:
   - id: UUID
   - name: String (VD: "Tiền điện", "Tiền nước", "Internet")
   - amount: Decimal
   - isEstimated: Bool (số tiền chỉ ước lượng)
   - dueDate: Date (ngày đến hạn kỳ hiện tại)
   - frequency: RecurringFrequency
   - category: Category
   - account: Account? (tài khoản thanh toán mặc định)
   - isPaid: Bool (đã thanh toán kỳ này)
   - paidDate: Date? (ngày thanh toán thực tế)
   - paidTransactionId: UUID? (link đến giao dịch đã tạo)
   - reminderDaysBefore: [Int] (mặc định [3, 1, 0])
   - notes: String?
   - createdAt: Date
   - updatedAt: Date

6. `BillSummary` value type:
   - bill: Bill
   - status: BillStatus (computed từ dueDate + isPaid)
   - daysUntilDue: Int (negative nếu overdue)
   - isOverdue: Bool

7. `RecurringRepositoryProtocol`:
   - saveRecurringRule(_ rule: RecurringRule) async throws
   - deleteRecurringRule(id: UUID) async throws
   - fetchRecurringRules(status: RecurringStatus?) async throws -> [RecurringRule]
   - fetchDueRecurringRules(on date: Date) async throws -> [RecurringRule]
   - updateNextDate(id: UUID, nextDate: Date) async throws
   - fetchSubscriptions() async throws -> [RecurringRule] // isSubscription == true

8. `BillRepositoryProtocol`:
   - saveBill(_ bill: Bill) async throws
   - deleteBill(id: UUID) async throws
   - fetchBills(status: BillStatus?) async throws -> [Bill]
   - fetchUpcomingBills(within days: Int) async throws -> [Bill]
   - markBillAsPaid(id: UUID, transactionId: UUID, paidDate: Date) async throws
   - resetBillForNextPeriod(id: UUID) async throws
   - fetchOverdueBills() async throws -> [Bill]

9. `CreateRecurringRuleUseCase`:
   - Validate: amount > 0, nextDate >= today, category exists
   - Free tier check: tối đa 5 recurring rules
   - Calculate nextDate based on frequency + interval
   - Set status = .active

10. `ProcessRecurringTransactionsUseCase`:
    - Chạy daily (background task hoặc app launch)
    - Fetch all active rules where nextDate <= today
    - Cho mỗi rule:
      - Nếu isAutoConfirm: tạo Transaction tự động
      - Nếu !isAutoConfirm: tạo pending notification cho user
    - Update nextDate = calculate next occurrence
    - Nếu nextDate > endDate: set status = .completed

11. `CalculateNextDateUseCase`:
    - Input: currentDate, frequency, interval
    - Logic:
      - daily: + (1 * interval) days
      - weekly: + (7 * interval) days
      - biweekly: + 14 days
      - monthly: + (1 * interval) months (handle cuối tháng 28/29/30/31)
      - quarterly: + 3 months
      - yearly: + (1 * interval) years
    - Handle edge cases: Feb 29, month-end dates

12. `GetSubscriptionSummaryUseCase`:
    - Fetch all recurring với isSubscription = true
    - Tính tổng chi phí subscription/tháng (normalize frequency to monthly)
    - Group by category
    - Output: totalMonthly, list of subscriptions with monthly cost

13. `CreateBillUseCase`:
    - Validate: name không rỗng, amount > 0, dueDate exists
    - Free tier check: tối đa 5 bills
    - Set isPaid = false
    - Setup default reminders [3, 1, 0]

14. `MarkBillAsPaidUseCase`:
    - Input: billId, actualAmount (có thể khác estimated), accountId
    - Tạo Transaction expense tự động
    - Set bill.isPaid = true, bill.paidDate = today
    - Link transaction → bill.paidTransactionId
    - Calculate next dueDate cho kỳ tiếp theo
    - Reset isPaid = false cho kỳ mới

15. `CheckBillRemindersUseCase`:
    - Chạy daily
    - Fetch unpaid bills where dueDate within reminderDaysBefore
    - Trả về danh sách (bill, daysUntilDue) cần push notification
    - Include overdue bills (daysUntilDue < 0)

16. `GetUpcomingBillsUseCase`:
    - Input: days ahead (default 30)
    - Fetch bills sorted by dueDate
    - Include status (upcoming/due/overdue/paid)
    - Group by: "Quá hạn", "Hôm nay", "Tuần này", "Tháng này"

### FinanceData

17. `RecurringRuleEntity` @Model:
    - Map 1:1 với RecurringRule model
    - Relationships: templateCategory → CategoryEntity, templateAccount → AccountEntity
    - Indexes: (status, nextDate), (isSubscription)

18. `BillEntity` @Model:
    - Map 1:1 với Bill model
    - Relationships: category → CategoryEntity, account → AccountEntity
    - Indexes: (dueDate), (isPaid, dueDate)

19. `RecurringRepositoryImpl`:
    - Implement RecurringRepositoryProtocol
    - Efficient query cho due rules (nextDate <= today AND status == active)
    - Subscription filtering

20. `BillRepositoryImpl`:
    - Implement BillRepositoryProtocol
    - Upcoming bills query with date range
    - Overdue detection: dueDate < today AND isPaid == false

21. `RecurringBackgroundTask`:
    - BGTaskScheduler registration cho daily processing
    - Fallback: process on app launch if background task missed
    - Call ProcessRecurringTransactionsUseCase + CheckBillRemindersUseCase

### FinanceUI

22. `RecurringRuleRow` — 1 row cho recurring rule:
    - Category icon + name + amount
    - Frequency badge: "Hàng tháng", "Hàng tuần"...
    - Next date: "Tiếp theo: 01/04/2026"
    - Status indicator (active/paused)
    - Subscription badge nếu isSubscription

23. `BillRow` — 1 row cho bill:
    - Category icon + bill name + amount
    - Due date + status badge:
      - "Còn 3 ngày" (xanh)
      - "Hôm nay" (vàng)
      - "Quá hạn 2 ngày" (đỏ)
      - "Đã thanh toán ✓" (xanh lá)
    - "Thanh toán" button (khi chưa paid)
    - Amount italic nếu isEstimated + "(ước lượng)"

24. `SubscriptionSummaryCard` — card tổng quan subscription:
    - "Tổng subscription: 450.000₫/tháng"
    - Breakdown by category (mini list)
    - Trend vs tháng trước

25. `BillCalendarView` — calendar hiển thị bills + recurring:
    - Month calendar grid
    - Dots/badges trên ngày có bill/recurring
    - Tap ngày → list bills/recurring ngày đó
    - Color-coded: paid (xanh lá), upcoming (xanh), overdue (đỏ)

26. `UpcomingBillsBanner` — banner cho dashboard:
    - "3 hóa đơn đến hạn trong 7 ngày tới"
    - Mini list: bill name + amount + due date
    - Tap → BillListView

### iOS

27. `RecurringListView`:
    - Segmented control: "Tất cả" | "Subscription"
    - LazyVStack danh sách RecurringRuleRows
    - FAB "+" → CreateRecurringView
    - Swipe actions: Pause, Edit, Delete
    - Section header: "Active" / "Paused" / "Completed"
    - Subscription tab: SubscriptionSummaryCard ở top + list

28. `RecurringListViewModel`:
    - @Observable class
    - recurringRules: [RecurringRule]
    - subscriptionTotal: Decimal
    - filter: RecurringStatus?
    - showSubscriptionsOnly: Bool
    - Load + refresh, pause/resume actions

29. `CreateRecurringView`:
    - Name input
    - Amount input (QuickNumpad)
    - Type selector (income/expense)
    - Category picker
    - Account picker
    - Frequency picker (daily/weekly/biweekly/monthly/quarterly/yearly)
    - Interval input (VD: "mỗi 2 tuần")
    - Start date picker
    - End date picker (optional)
    - Auto-confirm toggle
    - Reminder days picker (1-3)
    - Subscription toggle
    - Note input

30. `CreateRecurringViewModel`:
    - Validate input
    - Call CreateRecurringRuleUseCase
    - Free tier check + Premium gate

31. `BillListView`:
    - Segmented: "Sắp đến hạn" | "Lịch" | "Tất cả"
    - "Sắp đến hạn" tab:
      - Grouped: "Quá hạn" (đỏ), "Hôm nay", "Tuần này", "Tháng này"
      - BillRows with "Thanh toán" button
    - "Lịch" tab: BillCalendarView
    - "Tất cả" tab: full list with paid/unpaid filter
    - FAB "+" → CreateBillView

32. `BillListViewModel`:
    - @Observable class
    - upcomingBills: [BillSummary] grouped
    - overdueBills: [BillSummary]
    - Load + refresh
    - markAsPaid action → MarkBillAsPaidUseCase

33. `CreateBillView`:
    - Name input (with VN defaults: "Tiền điện", "Tiền nước", "Internet", "Tiền nhà")
    - Amount input + isEstimated toggle
    - Due date picker
    - Frequency picker
    - Category picker (auto-suggest based on name)
    - Account picker (default payment account)
    - Reminder config: checkboxes "3 ngày trước", "1 ngày trước", "Ngày đến hạn"
    - Note input

34. `CreateBillViewModel`:
    - Validate input
    - Call CreateBillUseCase
    - Auto-suggest category from bill name
    - Free tier check

35. `PayBillSheet`:
    - Bill info summary
    - Actual amount input (pre-filled, editable nếu estimated)
    - Account picker
    - Date picker (default today)
    - Note input
    - "Thanh toán" button → creates transaction + marks bill paid

36. Notification setup:
    - Register UNUserNotificationCenter categories
    - Recurring reminder: "Tiền thuê nhà 8.000.000₫ sẽ đến hạn ngày 01/04"
    - Bill reminder: "Hóa đơn tiền điện đến hạn trong 3 ngày"
    - Actions trên notification: "Đánh dấu đã trả", "Nhắc lại sau"

### macOS

37. `RecurringTableView`:
    - Table columns: Name | Amount | Frequency | Next Date | Status | Type
    - Sortable columns
    - Multi-select + bulk pause/delete
    - Keyboard shortcut ⌘R → create recurring

38. `BillDashboardView`:
    - Split view: upcoming bills list + calendar
    - Click bill → detail panel
    - Quick pay: double-click → PayBillSheet
    - Overdue bills highlighted in sidebar

39. `SubscriptionManagerView`:
    - Dedicated view cho subscription management
    - Total monthly/yearly cost prominent
    - List with cancel/pause actions
    - Category breakdown chart

### Tests

40. CreateRecurringRule — amount validation, free tier limit (5), frequency/interval setup
41. CalculateNextDate — monthly edge cases (Jan 31 → Feb 28), yearly (leap year), biweekly
42. ProcessRecurring — auto-confirm creates transaction, non-auto creates notification
43. RecurringStatus transitions — active → paused → active, active → completed (endDate)
44. Subscription summary — monthly cost normalization (yearly/12, weekly*4.33)
45. CreateBill — validation, default VN bills setup, reminder config
46. MarkBillAsPaid — transaction created, bill reset for next period, link verification
47. BillReminders — correct trigger at 3/1/0 days before due, overdue detection
48. BillStatus computation — upcoming/due/overdue/paid based on dueDate + isPaid
49. Edge cases — bill amount change between periods, recurring rule deleted mid-cycle, timezone handling for due dates
50. Calendar view data — correct dots on calendar dates, multiple bills on same day
