---
description: "Triển khai feature Savings Goals — F2.4 Mục tiêu tiết kiệm với tracking tiến độ + auto-contribute"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: Savings Goals

## Feature Spec References
- F2.4: Savings Goals (đặt mục tiêu tiết kiệm, theo dõi tiến độ %, auto-contribute rules)

## Đọc Context Trước
1. `CLAUDE.md` — coding conventions, architecture rules
2. `FinanceApp-Feature-Specification.md` → section 5.3 (F2.4)
3. `docs/DATA-MODEL.md` → Goal entity, AutoContributeRule, Account relationship
4. `docs/ARCHITECTURE.md` — MVVM + Clean Architecture layers
5. `docs/CONVENTIONS.md` — Swift style guide

## Tasks

### FinanceCore

1. `GoalStatus` enum:
   ```swift
   enum GoalStatus: String, Codable, Sendable {
       case active        // Đang tiết kiệm
       case completed     // Đã đạt 100%
       case paused        // Tạm dừng
       case expired       // Quá deadline mà chưa đạt
   }
   ```

2. `GoalMilestone` enum:
   ```swift
   enum GoalMilestone: Double, Codable, Sendable {
       case quarter = 0.25   // 25%
       case half = 0.50      // 50%
       case threeQuarters = 0.75  // 75%
       case complete = 1.0   // 100%
   }
   ```

3. `AutoContributeType` enum:
   ```swift
   enum AutoContributeType: String, Codable, Sendable {
       case fixedAmount     // Số tiền cố định mỗi kỳ
       case percentOfIncome // % thu nhập
       case roundUp         // Làm tròn giao dịch, phần dư vào goal
   }
   ```

4. `AutoContributeRule` model:
   - id: UUID
   - type: AutoContributeType
   - amount: Decimal? (cho fixedAmount)
   - percentage: Double? (cho percentOfIncome)
   - frequency: RecurringFrequency (daily/weekly/monthly)
   - isEnabled: Bool
   - createdAt: Date

5. `Goal` model:
   - id: UUID
   - name: String (VD: "Mua iPhone 16", "Du lịch Nhật")
   - targetAmount: Decimal
   - currentAmount: Decimal
   - deadline: Date? (optional)
   - icon: String (SF Symbol name)
   - color: String (hex)
   - status: GoalStatus
   - linkedAccount: Account? (tài khoản tiết kiệm liên kết)
   - autoContributeRule: AutoContributeRule? (Premium)
   - notes: String?
   - createdAt: Date
   - updatedAt: Date

6. `GoalSummary` value type:
   - goal: Goal
   - progressPercent: Double (currentAmount / targetAmount * 100)
   - remainingAmount: Decimal (targetAmount - currentAmount)
   - daysUntilDeadline: Int? (nil nếu không có deadline)
   - requiredPerWeek: Decimal? (remainingAmount / weeksUntilDeadline)
   - requiredPerMonth: Decimal? (remainingAmount / monthsUntilDeadline)
   - currentMilestone: GoalMilestone? (milestone hiện tại đã đạt)
   - nextMilestone: GoalMilestone? (milestone tiếp theo)
   - isOnTrack: Bool (dựa trên pace hiện tại vs deadline)

7. `GoalContribution` model:
   - id: UUID
   - goalId: UUID
   - amount: Decimal
   - date: Date
   - note: String? (VD: "Tiết kiệm từ lương tháng 3")
   - isAutomatic: Bool (từ auto-contribute rule)
   - createdAt: Date

8. `GoalRepositoryProtocol`:
   - saveGoal(_ goal: Goal) async throws
   - deleteGoal(id: UUID) async throws
   - fetchGoals(status: GoalStatus?) async throws -> [Goal]
   - fetchGoal(id: UUID) async throws -> Goal?
   - addContribution(_ contribution: GoalContribution) async throws
   - fetchContributions(goalId: UUID) async throws -> [GoalContribution]
   - updateGoalAmount(id: UUID, newAmount: Decimal) async throws

9. `CreateGoalUseCase`:
   - Validate: name không rỗng, targetAmount > 0
   - Free tier check: tối đa 2 goals
   - Nếu có deadline: validate deadline > today
   - Set status = .active

10. `ContributeToGoalUseCase`:
    - Input: goalId, amount, note
    - Validate: amount > 0
    - Update currentAmount += amount
    - Check milestones: nếu vượt 25%/50%/75%/100% → trigger celebration
    - Nếu currentAmount >= targetAmount → set status = .completed

11. `GetGoalSummariesUseCase`:
    - Tính toán progressPercent, remainingAmount
    - Tính requiredPerWeek/Month nếu có deadline
    - Determine isOnTrack dựa trên pace
    - Sort: active trước, completed sau

12. `ProcessAutoContributeUseCase` (Premium):
    - Chạy theo schedule (daily/weekly/monthly)
    - Với fixedAmount: tạo contribution với amount cố định
    - Với percentOfIncome: tính % từ income transactions gần nhất
    - Với roundUp: tính tổng round-up từ expense transactions
    - Tạo GoalContribution với isAutomatic = true

13. `SmartNudgeUseCase`:
    - Input: GoalSummary
    - Output: String message (VD: "Bạn cần tiết kiệm 500.000₫/tuần để đạt mục tiêu đúng hạn")
    - Nếu behind pace: cảnh báo + suggest tăng contribution
    - Nếu ahead of pace: khích lệ "Tuyệt vời! Bạn đang nhanh hơn kế hoạch"
    - Nếu gần milestone: "Chỉ còn 50.000₫ nữa là đạt 50%!"

### FinanceData

14. `GoalEntity` @Model:
    - Map 1:1 với Goal model
    - Relationship: linkedAccount → AccountEntity (optional)
    - Indexes: (status), (deadline)

15. `GoalContributionEntity` @Model:
    - Map 1:1 với GoalContribution model
    - Relationship: goal → GoalEntity
    - Indexes: (goalId, date)

16. `AutoContributeRuleEntity` @Model:
    - Map 1:1 với AutoContributeRule
    - Relationship: goal → GoalEntity (1:1)

17. `GoalRepositoryImpl`:
    - Implement GoalRepositoryProtocol
    - Fetch contributions với pagination
    - Efficient aggregate cho currentAmount verification

### FinanceUI

18. `GoalProgressRing` — circular progress indicator:
    - Animated ring fill (0% → currentPercent)
    - Color: xanh dương gradient
    - Center text: "65%" hoặc icon
    - Milestone markers at 25%, 50%, 75%

19. `GoalCard` — card hiển thị 1 goal:
    - Goal icon + name
    - GoalProgressRing (compact)
    - "150.000₫ / 500.000₫"
    - Remaining: "Còn thiếu 350.000₫"
    - Deadline badge: "Còn 45 ngày" (vàng nếu gần hạn, đỏ nếu quá hạn)
    - Smart nudge text nhỏ ở bottom

20. `GoalMilestoneAnimation` — celebration khi đạt milestone:
    - Confetti animation (25%, 50%, 75%)
    - Star burst animation (100% — completed)
    - Haptic feedback
    - Congratulation message

21. `ContributionRow` — 1 row trong contribution history:
    - Date + amount + note
    - Badge "Tự động" nếu isAutomatic
    - Running total

22. `SmartNudgeBanner` — banner gợi ý trên goal detail:
    - Icon + message text
    - Action button (VD: "Đóng góp ngay")
    - Dismissable

### iOS

23. `GoalListView`:
    - Horizontal scroll carousel cho active goals (GoalCards)
    - Section "Đã hoàn thành" collapsed
    - FAB "+" → CreateGoalView
    - Empty state: "Bạn chưa có mục tiêu nào. Bắt đầu tiết kiệm cho điều bạn muốn!"
    - Pull-to-refresh

24. `GoalListViewModel`:
    - @Observable class
    - activeGoals: [GoalSummary]
    - completedGoals: [GoalSummary]
    - Load + refresh goals
    - Delete goal (swipe)

25. `CreateGoalView`:
    - Name input (text field)
    - Target amount input (QuickNumpad)
    - Deadline picker (optional, DatePicker)
    - Icon picker (grid SF Symbols phổ biến: cart, airplane, house, car, gift, heart...)
    - Color picker
    - Link account toggle + account picker
    - Auto-contribute setup (Premium badge nếu free):
      - Type selector (fixed/percent/roundUp)
      - Amount/percentage input
      - Frequency picker

26. `CreateGoalViewModel`:
    - Validate input
    - Call CreateGoalUseCase
    - Premium gate cho auto-contribute

27. `GoalDetailView`:
    - Large GoalProgressRing
    - Goal info (name, target, deadline, smart nudge)
    - "Đóng góp" button → ContributeSheet
    - Contribution history (LazyVStack)
    - Trend chart: contributions over time
    - Edit / Pause / Delete actions

28. `GoalDetailViewModel`:
    - Load goal detail + contributions
    - Handle contribute action
    - Check + trigger milestone celebrations

29. `ContributeSheet`:
    - Amount input (QuickNumpad)
    - Note input (optional)
    - Quick amounts: "50K", "100K", "200K", "500K"
    - Show resulting progress preview: "Sau khi đóng góp: 65% → 75%"

### macOS

30. `GoalSidebarView`:
    - List goals trong sidebar grouped by status
    - Progress indicator inline
    - Click → detail trong main content

31. `GoalDashboardView`:
    - Grid layout: multiple GoalCards
    - Large detail panel khi select goal
    - Contribution history table
    - Keyboard shortcut ⌘G → quick contribute

32. `GoalTableView`:
    - Table columns: Name | Target | Current | Progress | Deadline | Status
    - Sortable columns
    - Inline contribute (double-click amount)

### Tests

33. CreateGoal — name validation, amount > 0, deadline in future, free tier limit (2)
34. Contribute — amount update, milestone detection (25/50/75/100%), status change to completed
35. GoalSummary — progressPercent, remainingAmount, requiredPerWeek/Month calculations
36. SmartNudge — on track message, behind pace warning, near milestone message
37. AutoContribute — fixedAmount deduction, percentOfIncome calculation, roundUp accumulation
38. GoalStatus transitions — active → completed, active → paused → active, active → expired
39. Edge cases — zero target (rejected), contribute more than remaining, deadline today, no deadline goal
40. GoalProgressRing — animation states, milestone markers positioning
