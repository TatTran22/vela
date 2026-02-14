---
description: "Accessibility audit checklist — VoiceOver, Dynamic Type, color contrast, Reduce Motion, Switch Control, per-screen audit"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Accessibility Audit

## Đọc Context Trước
1. `CLAUDE.md`
2. `docs/ARCHITECTURE.md`
3. `docs/DESIGN-SYSTEM.md`
4. `docs/CONVENTIONS.md`

## Accessibility Standards Reference

| Standard | Requirement |
|----------|-------------|
| VoiceOver | Full navigation on 100% of screens |
| Dynamic Type | All text respects system font size (xSmall → AX5) |
| Color Contrast | WCAG AA — 4.5:1 normal text, 3:1 large text (18pt+ or 14pt bold) |
| Reduce Motion | Respect `accessibilityReduceMotion`, no forced animations |
| Bold Text | Respect `accessibilityBoldText` system setting |
| Switch Control | All interactive elements reachable via Switch Control |

---

## Audit Checklist

### 1. VoiceOver — Full Navigation
- [ ] Every screen is navigable start-to-finish using VoiceOver swipe gestures
- [ ] Tab bar items have correct labels ("Tổng quan", "Giao dịch", "Ngân sách", "Cài đặt")
- [ ] Navigation back buttons announce destination ("Quay lại Tổng quan")
- [ ] Modal sheets announce their title when presented
- [ ] Alerts and confirmation dialogs are fully accessible
- [ ] No "dead zones" — every visible element is reachable or explicitly hidden from accessibility
- [ ] Focus order follows visual/logical order (top-to-bottom, left-to-right)
- [ ] Focus moves to new content when navigation occurs (sheets, push, alerts)
- [ ] Dismissing a sheet returns focus to the triggering element

**Pass criteria:** Complete every user flow (add transaction, view report, set budget) using only VoiceOver.

### 2. Accessibility Labels on ALL Interactive Elements
- [ ] All buttons have descriptive `accessibilityLabel` (not just icon name)
- [ ] FAB "+" button: label = "Thêm giao dịch mới" (not "plus" or "add")
- [ ] Swipe actions (delete, edit) have labels: "Xóa giao dịch", "Sửa giao dịch"
- [ ] Category icons: label = category name ("Ăn uống", "Di chuyển")
- [ ] Account cards: label includes account name + type + balance
- [ ] Chart elements: label describes data ("Ăn uống: 2.100.000 đồng, 35% chi tiêu")
- [ ] Toggle switches: label includes current state ("Bật Face ID: đang tắt")
- [ ] Custom numpad keys: labels match function ("k — nhân nghìn", "tr — nhân triệu")
- [ ] Sync status badge: label = "Đồng bộ: đã đồng bộ" / "đang đồng bộ" / "ngoại tuyến"
- [ ] No element uses raw SF Symbol name as accessibility label

**Pass criteria:** VoiceOver reads meaningful Vietnamese descriptions for every interactive element.

### 3. Accessibility Hints for Complex Actions
- [ ] Long press actions have hints: "Nhấn giữ để xem thêm tùy chọn"
- [ ] Swipeable rows have hints: "Vuốt trái để xóa, vuốt phải để sửa"
- [ ] Drill-down cards have hints: "Nhấn hai lần để xem chi tiết"
- [ ] Budget progress bar hint: "Nhấn hai lần để xem giao dịch trong danh mục này"
- [ ] Goal progress ring hint: "Nhấn hai lần để thêm tiền vào mục tiêu"
- [ ] Receipt scan button hint: "Nhấn hai lần để chụp hóa đơn"
- [ ] Search field hint: "Tìm kiếm theo ghi chú, danh mục, số tiền hoặc thẻ"
- [ ] Editable amount fields hint: "Nhấn hai lần để nhập số tiền"

**Pass criteria:** New users can discover all hidden/complex actions through VoiceOver hints alone.

### 4. Accessibility Values for Progress & Amounts
- [ ] Budget progress bar: `accessibilityValue = "80 phần trăm, 6.400.000 trên 8.000.000 đồng"`
- [ ] Goal progress ring: `accessibilityValue = "75 phần trăm, còn 5.000.000 đồng"`
- [ ] Account balance: value reads full amount in words-friendly format
- [ ] Transaction amounts: `accessibilityValue` includes sign ("chi 150.000 đồng" / "thu 30.000.000 đồng")
- [ ] Date values: read as full date ("Thứ Hai, ngày 10 tháng 2 năm 2026")
- [ ] Percentage values: read as "X phần trăm" not just number
- [ ] Currency amounts: always include currency name ("đồng" for VND, "đô la" for USD)
- [ ] Slider controls (if any): announce current value and range

**Pass criteria:** VoiceOver users understand exact values without needing visual display.

### 5. Custom Rotor Actions for Transaction Lists
- [ ] Custom rotor for "Danh mục" — jump between category groups
- [ ] Custom rotor for "Ngày" — jump between date groups
- [ ] Custom rotor for "Tài khoản" — filter by account
- [ ] Rotor actions on transaction row: "Xóa", "Sửa", "Nhân đôi", "Đổi danh mục"
- [ ] Custom rotor implemented via `accessibilityCustomContent` or `accessibilityRotorEntry`
- [ ] Rotor labels in Vietnamese for Vietnamese locale, English for English locale

**Pass criteria:** VoiceOver users can efficiently navigate large transaction lists using rotor.

### 6. Dynamic Type Support
- [ ] ALL text uses system text styles (`.body`, `.title`, `.caption`, etc.) or scaled custom fonts
- [ ] `@ScaledMetric` used for spacing/sizing that should scale with text
- [ ] No fixed-height constraints that clip text at large sizes
- [ ] Amount display (`heroAmount`, `largeAmount`) scales with Dynamic Type
- [ ] Custom numpad adapts layout for larger text sizes
- [ ] Dashboard cards reflow for Accessibility sizes (AX1-AX5)
- [ ] Transaction list rows expand height for large text
- [ ] Category picker grid adjusts columns for large text
- [ ] Charts have minimum readable text size
- [ ] Test at ALL sizes: xSmall, Small, Medium (default), Large, xLarge, xxLarge, xxxLarge, AX1, AX2, AX3, AX4, AX5
- [ ] No text truncation that hides important information at large sizes

**Pass criteria:** App is fully usable at AX5 (largest Accessibility size). No text clipped or overlapping.

### 7. Color Contrast — WCAG AA
- [ ] Normal text (< 18pt): contrast ratio >= 4.5:1 against background
- [ ] Large text (>= 18pt or >= 14pt bold): contrast ratio >= 3:1 against background
- [ ] Income green (`#34C759` / `#30D158`) meets contrast on both light and dark backgrounds
- [ ] Expense red (`#FF3B30` / `#FF453A`) meets contrast on both light and dark backgrounds
- [ ] Warning orange (`#FF9500` / `#FF9F0A`) meets contrast on both light and dark backgrounds
- [ ] Budget progress bar colors meet contrast against track background
- [ ] Chart colors distinguishable (not relying on color alone — use patterns/labels)
- [ ] Category icon background color + foreground icon meet contrast requirement
- [ ] Placeholder text meets minimum 3:1 contrast
- [ ] Focus indicators (selection states) clearly visible in both color modes
- [ ] All semantic colors from Design System tested in Light + Dark mode

**Pass criteria:** Xcode Accessibility Inspector reports no contrast violations on any screen.

### 8. Non-Color Indicators
- [ ] Income/Expense NOT distinguished by color alone — use +/- signs and icons
- [ ] Budget status uses icon indicators alongside colors (checkmark/warning/exclamation)
- [ ] Chart slices have labels, not just colors
- [ ] Sync status uses icon shapes alongside colored dots (✓ ↻ ○ ✗)
- [ ] Error states have text message, not just red color
- [ ] Success states have text/icon confirmation, not just green color
- [ ] Transaction type (income/expense/transfer) indicated by icon + text + color

**Pass criteria:** App is fully usable with grayscale display filter enabled.

### 9. Reduce Motion Support
- [ ] Check `UIAccessibility.isReduceMotionEnabled` / `@Environment(\.accessibilityReduceMotion)`
- [ ] Transaction save animation: replace checkmark animation with simple fade
- [ ] Budget threshold pulse: replace with static highlight
- [ ] Goal milestone confetti: replace with static "Congratulations" text
- [ ] Chart draw animation: replace with instant display
- [ ] Number counter animation: replace with instant value
- [ ] Pull-to-refresh: use system default (already respects Reduce Motion)
- [ ] Navigation transitions: use system default reduced transitions
- [ ] No `withAnimation` blocks that ignore Reduce Motion setting
- [ ] Loading spinners: acceptable (functional, not decorative)

**Pass criteria:** No decorative animations play when Reduce Motion is enabled.

### 10. Bold Text Support
- [ ] App responds to `UIAccessibility.isBoldTextEnabled`
- [ ] System fonts automatically respect Bold Text — verify no custom font overrides
- [ ] Custom-weight fonts (if any) increase weight when Bold Text is on
- [ ] Icon stroke weights increase with Bold Text where applicable
- [ ] Chart labels become bold when Bold Text is enabled
- [ ] Thin/ultralight font weights never used (minimum regular weight)

**Pass criteria:** All text visibly bolder when Bold Text setting is enabled.

### 11. Switch Control Compatibility
- [ ] All interactive elements focusable by Switch Control scanning
- [ ] No gesture-only actions without alternative (swipe actions have menu alternative)
- [ ] Custom numpad keys individually selectable by Switch Control
- [ ] Category picker grid navigable item-by-item
- [ ] Chart interactive elements have alternative access (list view of data)
- [ ] Drag-and-drop (account reorder) has alternative (edit mode with move buttons)
- [ ] No time-limited interactions (auto-dismiss toasts must be accessible)

**Pass criteria:** Complete core user flows (add transaction, view dashboard) using Switch Control.

### 12. Per-Screen Audit Checklist

#### Dashboard (Home Screen)
- [ ] Total balance announced with currency
- [ ] Income/Expense/Remaining cards individually accessible
- [ ] Mini chart has text alternative summarizing trend
- [ ] Recent transactions list fully navigable
- [ ] All cards have tap target >= 44x44pt

#### Transaction Input
- [ ] Custom numpad fully accessible (each key labeled)
- [ ] "k" and "tr" buttons clearly labeled for VoiceOver
- [ ] Amount display reads current value after each key press
- [ ] Category picker announces AI suggestion
- [ ] Account selector announces current selection
- [ ] Date picker accessible
- [ ] Save confirmation announced

#### Transaction List
- [ ] Group headers (dates) announced as headings
- [ ] Each transaction row reads: category, note, amount, account
- [ ] Search field accessible with clear button
- [ ] Filter controls accessible
- [ ] Empty state announced
- [ ] Pull-to-refresh announced ("Đang làm mới")

#### Budget Screen
- [ ] Budget name and category announced
- [ ] Progress percentage and amounts announced
- [ ] Budget status (safe/caution/danger) announced
- [ ] Add budget button accessible
- [ ] Empty state for no budgets

#### Reports / Charts
- [ ] Each chart has text summary alternative
- [ ] Pie chart slices individually selectable with value announced
- [ ] Bar chart bars individually selectable with value announced
- [ ] Time period selector accessible
- [ ] Export button accessible

#### Settings
- [ ] All toggles have labels + current state
- [ ] Picker selections announce current value
- [ ] Destructive actions (delete data) have confirmation
- [ ] Version/build info readable

### 13. Automated Accessibility Tests (XCUITest)
- [ ] Test: every screen has no accessibility warnings (`audit()` API)
- [ ] Test: all buttons have non-empty `accessibilityLabel`
- [ ] Test: VoiceOver navigation order matches visual order on key screens
- [ ] Test: all images have `accessibilityLabel` or are marked decorative
- [ ] Test: no `accessibilityLabel` contains raw SF Symbol name
- [ ] Test: Dynamic Type large size does not cause overlapping elements
- [ ] Test: minimum tap target size 44x44pt for all interactive elements

**Pass criteria:** All XCUITest accessibility tests pass in CI pipeline.

### 14. Vietnamese VoiceOver Pronunciation
- [ ] Currency "VND" reads as "đồng" (not "vê en đê")
- [ ] Category names pronunciated correctly in Vietnamese
- [ ] Amount "1.500.000₫" reads as "một triệu năm trăm nghìn đồng"
- [ ] Abbreviated amounts "1,5tr" reads as "một phẩy năm triệu đồng"
- [ ] Date format reads correctly in Vietnamese locale
- [ ] Mixed Vietnamese/English text handled gracefully
- [ ] `accessibilityLanguage` set appropriately for bilingual content
- [ ] Proper `accessibilityAttributedLabel` for amounts with currency symbols

**Pass criteria:** Vietnamese VoiceOver reads all financial content naturally and correctly.

---

## Actions
For each failed check:
1. Create an accessibility fix task with priority
2. Implement fix following Apple Accessibility Programming Guide
3. Test with VoiceOver on real device (simulator VoiceOver differs)
4. Test with Dynamic Type at AX5 on real device
5. Re-verify and document

## Output
Generate an accessibility report:
- Pass count / Total checks
- **Critical** (blocks release): VoiceOver cannot complete core flows, missing labels on key elements
- **Important** (should fix): Dynamic Type issues, contrast violations, missing hints
- **Enhancement** (post-release): custom rotor, advanced VoiceOver optimizations
- Screens tested (list each screen + pass/fail)
- Testing devices + iOS/macOS versions
