# Design System

## Nguyên Tắc Thiết Kế

- **Apple-native**: Tuân thủ Apple HIG, dùng system components khi có thể
- **Intelligently simple**: AI làm nặng phía sau, người dùng thấy đơn giản
- **Information density**: iOS = card-based / macOS = dense table-based
- **Consistent**: Cùng design language trên iOS, macOS, watchOS, widgets

---

## Colors

### Semantic Colors

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `income` | `#34C759` (System Green) | `#30D158` | Thu nhập, positive changes, goals đạt |
| `expense` | `#FF3B30` (System Red) | `#FF453A` | Chi tiêu, negative changes, vượt budget |
| `transfer` | `#007AFF` (System Blue) | `#0A84FF` | Chuyển khoản, neutral actions |
| `warning` | `#FF9500` (System Orange) | `#FF9F0A` | Budget sắp hết (80-100%), cảnh báo |
| `background` | System Background | System Background | Main background |
| `cardBackground` | Secondary System BG | Secondary System BG | Card surfaces |
| `textPrimary` | Label | Label | Main text |
| `textSecondary` | Secondary Label | Secondary Label | Timestamps, notes, captions |
| `textTertiary` | Tertiary Label | Tertiary Label | Placeholders, disabled |

### Budget Status Colors

| Status | Color | Condition |
|--------|-------|-----------|
| Safe | `income` (green) | < 50% budget used |
| Caution | `warning` (yellow/orange) | 50-80% budget used |
| Danger | `expense` (red) | 80-100% budget used |
| Over budget | `expense` (red, bold) | > 100% budget used |

### Category Colors
Mỗi default category có màu riêng. User có thể tùy chỉnh.

| Category | Color | SF Symbol |
|----------|-------|-----------|
| Ăn uống | `#FF9500` | `fork.knife` |
| Nhà ở | `#5856D6` | `house.fill` |
| Di chuyển | `#007AFF` | `car.fill` |
| Mua sắm | `#FF2D55` | `bag.fill` |
| Giải trí | `#AF52DE` | `gamecontroller.fill` |
| Sức khỏe | `#34C759` | `heart.fill` |
| Giáo dục | `#5AC8FA` | `book.fill` |
| Gia đình | `#FF6482` | `person.2.fill` |
| Tài chính | `#8E8E93` | `banknote.fill` |
| Lương | `#34C759` | `briefcase.fill` |
| Freelance | `#5856D6` | `laptopcomputer` |

---

## Typography

| Token | Font | Size | Weight | Usage |
|-------|------|------|--------|-------|
| `heroAmount` | `.largeTitle` | 34pt | Bold, Rounded | Dashboard tổng số dư |
| `largeAmount` | `.title` | 28pt | Bold, Rounded | Card balances |
| `amount` | `.title3` | 20pt | Semibold, Rounded | List item amounts |
| `smallAmount` | `.body` | 17pt | Semibold, Monospaced | Budget progress values |
| `heading` | `.title2` | 22pt | Bold | Section headers |
| `subheading` | `.headline` | 17pt | Semibold | Card titles, row titles |
| `body` | `.body` | 17pt | Regular | General text |
| `caption` | `.caption` | 12pt | Regular | Timestamps, secondary info |
| `footnote` | `.footnote` | 13pt | Regular | Disclaimers, hints |

**Rules:**
- Monetary amounts luôn dùng Rounded design (`.rounded`)
- Support Dynamic Type tất cả sizes
- Minimum text size: không bao giờ nhỏ hơn `.caption2`

---

## Spacing

| Token | Value | Usage |
|-------|-------|-------|
| `xxs` | 2pt | Inline spacing |
| `xs` | 4pt | Tight spacing, icon-to-text |
| `sm` | 8pt | Compact elements, list padding |
| `md` | 16pt | Standard spacing, card padding |
| `lg` | 24pt | Section spacing |
| `xl` | 32pt | Large section gaps |
| `xxl` | 48pt | Page top/bottom margins |

---

## Corner Radius

| Token | Value | Usage |
|-------|-------|-------|
| `small` | 8pt | Buttons, tags, chips |
| `medium` | 12pt | Cards, input fields |
| `large` | 16pt | Modal sheets, large cards |
| `full` | 50% | Circular avatars, category icons |

---

## Components

### AmountText
Hiển thị số tiền với format và màu phù hợp.

```
Props:
  - amount: Decimal
  - type: TransactionType (quyết định màu: income=green, expense=red, transfer=blue)
  - currency: CurrencyCode (quyết định format)
  - style: AmountStyle (.hero, .large, .regular, .small)
  - showSign: Bool (hiện +/- prefix)
  - compact: Bool (hiện "1,5tr" thay vì "1.500.000₫")
```

### TransactionRow
Một dòng giao dịch trong danh sách.

```
Layout:
  ┌──────────────────────────────────────────────┐
  │ [Icon]  Category Name          +150.000₫     │
  │         Note text · 14:30      Ví tiền mặt   │
  └──────────────────────────────────────────────┘

Props:
  - transaction: Transaction
  - showAccount: Bool
Actions:
  - Swipe left: Delete
  - Swipe right: Edit
  - Long press: Duplicate, Change category
```

### AccountCard
Card hiển thị thông tin tài khoản.

```
Layout:
  ┌──────────────────────────────┐
  │ [Icon] Vietcombank           │
  │ Ngân hàng                    │
  │                              │
  │ 15.200.000 ₫                 │
  └──────────────────────────────┘

Props:
  - account: Account
  - showBalance: Bool (ẩn/hiện số dư)
Style:
  - Background: category color with 10% opacity
  - Border: 1pt category color with 20% opacity
```

### BudgetProgressBar
Thanh tiến trình budget với color-coded thresholds.

```
Layout:
  Ăn uống                 6.400.000 / 8.000.000₫
  [████████████████░░░░░] 80%

Props:
  - budget: Budget
  - spent: Decimal
  - showLabel: Bool
Colors:
  - 0-50%: income (green)
  - 50-80%: warning (orange)
  - 80-100%: expense (red)
  - >100%: expense (red) + overflow indicator
```

### CategoryPicker
Chọn danh mục cho giao dịch.

```
Layout (Grid mode - default):
  ┌──────┐ ┌──────┐ ┌──────┐
  │ 🍜   │ │ 🏠   │ │ 🚗   │
  │Ăn uống│ │Nhà ở │ │Di chuyển│
  └──────┘ └──────┘ └──────┘

Features:
  - Top 6 recent categories hiện đầu tiên
  - AI suggested category highlighted (border glow)
  - "Xem tất cả" → full category list với sub-categories
  - Search/filter categories
```

### QuickAmountInput
Bàn phím số tùy chỉnh cho nhập tiền.

```
Layout:
  ┌──────────────────────────────┐
  │         150.000 ₫            │  ← Live amount display
  ├──────┬──────┬──────┬────────┤
  │  1   │  2   │  3   │   ⌫    │
  ├──────┼──────┼──────┼────────┤
  │  4   │  5   │  6   │   +    │
  ├──────┼──────┼──────┼────────┤
  │  7   │  8   │  9   │   −    │
  ├──────┼──────┼──────┼────────┤
  │  k   │  0   │  tr  │   =    │
  └──────┴──────┴──────┴────────┘

Features:
  - "k" button: × 1.000 (150k = 150.000₫)
  - "tr" button: × 1.000.000 (1.5tr = 1.500.000₫)
  - Mini calculator: 150k + 200k = 350.000₫
  - Haptic feedback on tap
```

### GoalProgressRing
Vòng tiến trình cho savings goals.

```
Layout:
  ┌─────────────────────┐
  │    ┌─────────┐      │
  │    │  75%    │      │
  │    │ 🎯     │      │
  │    └─────────┘      │
  │  Mua iPhone 16      │
  │  15tr / 20tr        │
  │  Còn 2 tháng        │
  └─────────────────────┘

Milestones: 25%, 50%, 75%, 100% — celebration animation
```

### SyncStatusBadge
Hiển thị trạng thái đồng bộ CloudKit.

```
States:
  ✓ Synced     (green dot)
  ↻ Syncing    (animated blue)
  ○ Offline    (gray dot)
  ✗ Error      (red dot)
```

### DashboardCard
Card tổng quan trên màn hình chính.

```
Layout (iOS):
  ┌──────────────────────────────────┐
  │ Tổng số dư            15,2tr ₫  │
  ├──────────────────────────────────┤
  │ Thu nhập    │  Chi tiêu  │ Còn lại │
  │ +30tr       │  -22tr     │  8tr    │
  ├──────────────────────────────────┤
  │ [Mini bar chart - 7 ngày]       │
  ├──────────────────────────────────┤
  │ Giao dịch gần nhất:             │
  │  🍜 Ăn trưa        -85.000₫    │
  │  ☕ Café            -45.000₫    │
  │  💼 Lương      +30.000.000₫    │
  └──────────────────────────────────┘
```

---

## Charts

| Chart Type | Usage | Framework |
|------------|-------|-----------|
| Pie/Donut | Category breakdown | Swift Charts |
| Bar chart | Thu/chi theo thời gian (tuần/tháng) | Swift Charts |
| Line chart | Spending trend 6 tháng, Cash flow forecast | Swift Charts |
| Treemap | Category breakdown (advanced) | Custom |
| Stacked area | Net worth over time (assets vs liabilities) | Swift Charts |
| Progress ring | Goal progress, Budget circular | Custom SwiftUI |

**Chart Interaction:**
- Tap slice → drill down xem transactions
- Pinch to zoom timeline charts
- Long press → detail popover

---

## iOS Layout

### Tab Bar
| Tab | Icon | Title |
|-----|------|-------|
| Dashboard | `house.fill` | Tổng quan |
| Transactions | `list.bullet` | Giao dịch |
| + (FAB) | `plus.circle.fill` | (Floating, center) |
| Budgets | `chart.pie.fill` | Ngân sách |
| Settings | `gearshape.fill` | Cài đặt |

### Navigation
- `NavigationStack` + `NavigationPath`
- Swipe-back gesture
- Deep link support (from widgets, notifications, shortcuts)

---

## macOS Layout

### Sidebar Navigation
```
┌─────────────┬──────────────────────────────┐
│ Sidebar     │ Content                      │
│             │                              │
│ 📊 Tổng quan│  (Dashboard / Detail view)  │
│ 💳 Giao dịch│                              │
│ 📁 Tài khoản│                              │
│ 📊 Ngân sách│                              │
│ 🎯 Mục tiêu │                              │
│ 📈 Báo cáo │                              │
│             │                              │
│ ──────────  │                              │
│ ⚙️ Cài đặt │                              │
└─────────────┴──────────────────────────────┘
```

### Keyboard Shortcuts
| Shortcut | Action |
|----------|--------|
| `⌘+N` | New transaction |
| `⌘+F` | Search transactions |
| `⌘+1..6` | Switch sidebar sections |
| `⌘+,` | Settings |
| `⌘+E` | Export |
| `⌘+I` | Import |
| `Delete` | Delete selected |

---

## Widgets

### Small Widget (iOS/macOS)
```
┌──────────────────┐
│ Hôm nay          │
│ -485.000₫        │
│ 3 giao dịch      │
└──────────────────┘
```

### Medium Widget
```
┌──────────────────────────────────┐
│ Chi tiêu tuần này    -3.250.000₫│
│ [▓▓▓▓▓▓▓░░░░] 65% budget       │
│ 🍜 Ăn uống 1,2tr  🚗 Di chuyển 800k │
└──────────────────────────────────┘
```

### Large Widget
```
┌──────────────────────────────────┐
│ Tổng quan tuần                   │
│ Thu: +8.000.000₫  Chi: -5.200.000₫│
│ ─────────────────────────────────│
│ Top categories:                  │
│  🍜 Ăn uống      2.100.000₫     │
│  🚗 Di chuyển    1.500.000₫     │
│  🛍 Mua sắm       800.000₫     │
│ ─────────────────────────────────│
│ Gần đây:                        │
│  Highland Coffee    -45.000₫     │
│  Grab              -85.000₫     │
└──────────────────────────────────┘
```

---

## Animations & Motion

| Animation | Type | Duration | Notes |
|-----------|------|----------|-------|
| Transaction save | Checkmark + haptic | 0.3s | Success feedback |
| Budget threshold | Pulse glow | 0.5s | Khi đạt 80%, 100% |
| Goal milestone | Confetti + scale | 1.0s | Khi đạt 25/50/75/100% |
| Chart appear | Fade + draw | 0.5s | Stagger per element |
| Pull to refresh | Standard iOS | System | Sync trigger |
| Delete swipe | Slide + fade | 0.3s | Standard destructive |
| Number counter | Count up animation | 0.4s | Dashboard amounts |

**Reduce Motion:** Tất cả animations fallback thành fade-in/out đơn giản.

---

## Onboarding Flow

| Step | Content | Skippable |
|------|---------|-----------|
| 1 | Chọn đồng tiền chính (detect locale → suggest VND) | ✗ |
| 2 | Tạo tài khoản đầu tiên (gợi ý: Ví tiền mặt + Ngân hàng chính) | ✗ |
| 3 | Nhập số dư hiện tại | ✓ |
| 4 | Nhập 1 giao dịch thử (giới thiệu quick input) | ✓ |
| 5 | Feature highlights carousel (3 slides) | ✓ |

**Target:** Xong onboarding < 2 phút.

---

## Dark Mode

- Sử dụng semantic system colors (tự adapt)
- Custom colors: cung cấp cả Light + Dark variants
- Test cả 2 modes cho mọi screen
- Amount colors (income/expense) có adjusted variants cho dark mode
- Charts: adjust opacity/stroke cho readability

---

## Iconography

- Ưu tiên **SF Symbols** cho tất cả icons
- Category icons: SF Symbols (user customizable)
- Account type icons: SF Symbols
- Navigation icons: SF Symbols
- Custom icons chỉ dùng cho: app icon, logo, đặc biệt illustrations
