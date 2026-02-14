---
description: "Triển khai feature Ecosystem — F1.10 iOS Widget + F2.8 Apple Watch (Phase 2) + F2.9 Siri Shortcuts (Phase 2)"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: Ecosystem (Widget, Watch, Siri)

## Feature Spec References
- F1.10: iOS Widget (Phase 1)
- F2.8: Apple Watch (Phase 2 — skip for now)
- F2.9: Siri Shortcuts (Phase 2 — skip for now)

## Đọc Context Trước
1. `CLAUDE.md`
2. `FinanceApp-Feature-Specification.md` → F1.10, F2.8, F2.9
3. `docs/ARCHITECTURE.md`

## Phase 1 Scope: iOS Widget Only

### FinanceCore (Shared)
1. `WidgetData` model:
   - totalBalance: Decimal
   - todaySpending: Decimal
   - weeklySpending: Decimal
   - weeklyDailyAmounts: [(date: Date, amount: Decimal)] (7 days)
   - topCategories: [(name: String, icon: String, amount: Decimal)] (top 3)
   - recentTransactions: [(note: String, category: String, amount: Decimal, date: Date)] (3 items)
   - primaryCurrency: CurrencyCode
   - lastUpdated: Date
2. `GetWidgetDataUseCase`:
   - Fetch aggregated data for widget display
   - Lightweight query (no full transaction objects)

### FinanceData
3. `WidgetDataProvider`:
   - App Group shared container for widget ↔ app data
   - Write widget data on transaction changes
   - Read-only from widget extension
4. `AppGroupStore`:
   - UserDefaults(suiteName: "group.com.vela.finance")
   - Encode/decode WidgetData

### Widget Extension
5. `FinanceWidgetBundle` — @main WidgetBundle
6. `BalanceWidget` (Small):
   - Total balance prominently displayed
   - OR Today's spending (user configurable)
   - Currency formatted
   - Last updated timestamp
7. `WeeklyWidget` (Medium):
   - Weekly spending total
   - Mini bar chart (7 days, Swift Charts)
   - Today highlighted
8. `DetailWidget` (Large):
   - Top 3 categories with amounts
   - 3 recent transactions
   - Balance at bottom
9. `WidgetTimelineProvider`:
   - getSnapshot — show sample data for gallery
   - getTimeline — refresh every 30 minutes + on transaction change
   - placeholder — redacted layout
10. `WidgetConfigIntent` (AppIntentConfiguration):
    - Small widget: choose "Balance" or "Today's Spending"
    - Account filter: specific account or "All"
11. Deep links from widget:
    - Tap balance → Dashboard
    - Tap transaction → TransactionDetailView
    - Tap "+" area → QuickInputView

### iOS
12. Widget preview in Settings → "Customize Widget"
13. Update widget timeline when transaction is created/edited/deleted:
    - `WidgetCenter.shared.reloadAllTimelines()`

### Tests
14. WidgetData — correct aggregation, currency formatting
15. TimelineProvider — snapshot has sample data, timeline refreshes
16. AppGroupStore — encode/decode round trip
17. DeepLinks — correct URL scheme, navigation

---

## Phase 2 Placeholder (DO NOT IMPLEMENT YET)

### F2.8 Apple Watch
- watchOS app companion
- Quick transaction entry (amount + category)
- Today's balance + spending glance
- Complications

### F2.9 Siri Shortcuts
- "Thêm chi tiêu [amount] cho [category]"
- "Số dư của tôi"
- "Hôm nay tôi tiêu bao nhiêu"
- App Intents framework
