# Data Model

## Overview

Data layer sử dụng SwiftData + CloudKit sync. Tất cả monetary values dùng `Decimal`
(KHÔNG BAO GIỜ dùng `Double`). Soft delete (`deletedAt`) cho mọi entity để hỗ trợ
CloudKit conflict resolution.

---

## Core Entities

### Account

Đại diện cho nơi giữ tiền thực tế của người dùng.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `UUID` | Primary key |
| `name` | `String` | Tên tài khoản (VD: "Ví tiền mặt", "Vietcombank") |
| `type` | `AccountType` | Loại tài khoản |
| `currency` | `CurrencyCode` | ISO 4217 currency code (mặc định `VND`) |
| `balance` | `Decimal` | Số dư hiện tại |
| `icon` | `String` | SF Symbol name |
| `color` | `String` | Hex color string |
| `isArchived` | `Bool` | Ẩn tài khoản cũ |
| `sortOrder` | `Int` | Thứ tự hiển thị tùy chỉnh |
| `note` | `String?` | Ghi chú (số tài khoản, chi nhánh...) |
| `createdAt` | `Date` | Ngày tạo |
| `updatedAt` | `Date` | Ngày cập nhật cuối |
| `deletedAt` | `Date?` | Soft delete cho CloudKit sync |

**Relationships:**
- `transactions` → `[Transaction]` (inverse: `account`)
- `incomingTransfers` → `[Transaction]` (inverse: `toAccount`)

**Business Rules:**
- Free tier: tối đa 5 tài khoản · Premium: không giới hạn
- Balance được tính lại từ giao dịch khi cần reconcile
- VND accounts: không hiện decimal (VND không có xu)

---

### Transaction

Ghi nhận mọi sự di chuyển tiền.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `UUID` | Primary key |
| `amount` | `Decimal` | Luôn positive, type quyết định hướng |
| `type` | `TransactionType` | income / expense / transfer |
| `note` | `String?` | Ghi chú người dùng |
| `date` | `Date` | Ngày giao dịch |
| `account` | `Account` | Tài khoản nguồn (bắt buộc) |
| `toAccount` | `Account?` | Tài khoản đích (chỉ cho transfer) |
| `category` | `Category` | Danh mục (bắt buộc) |
| `tags` | `[Tag]` | Tags tùy chỉnh |
| `receiptImageData` | `Data?` | Ảnh hóa đơn đính kèm |
| `latitude` | `Double?` | Vĩ độ (location) |
| `longitude` | `Double?` | Kinh độ (location) |
| `isRecurring` | `Bool` | Giao dịch thuộc recurring template |
| `recurringRule` | `RecurringRule?` | Link đến rule lặp lại |
| `metadata` | `[String: String]?` | AI data, source info, extra fields |
| `createdAt` | `Date` | Ngày tạo |
| `updatedAt` | `Date` | Ngày cập nhật cuối |
| `deletedAt` | `Date?` | Soft delete |

**Business Rules:**
- `amount` luôn > 0, `type` xác định income/expense
- Transfer: trừ `account`, cộng `toAccount`
- Transfer KHÔNG tính là income hay expense trong báo cáo
- Cross-currency transfer: lưu cả 2 amount hoặc tỷ giá trong `metadata`
- Quick input target: mở app → nhập → done < 5 giây

---

### Category

Hệ thống phân loại 2 cấp cho giao dịch.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `UUID` | Primary key |
| `name` | `String` | Tên mặc định |
| `localizedNames` | `[String: String]` | Localized names (key = locale, value = name) |
| `type` | `TransactionType` | income hoặc expense |
| `parent` | `Category?` | Category cha (nil = top-level) |
| `children` | `[Category]` | Sub-categories |
| `icon` | `String` | SF Symbol name |
| `color` | `String` | Hex color |
| `sortOrder` | `Int` | Thứ tự hiển thị |
| `isSystem` | `Bool` | Category mặc định (không xóa được) |
| `isHidden` | `Bool` | Ẩn khỏi danh sách chọn |
| `createdAt` | `Date` | Ngày tạo |
| `updatedAt` | `Date` | Ngày cập nhật |

**Default Expense Categories (VN-optimized):**
- Ăn uống → Ăn ngoài, Đi chợ/nấu, Café/trà sữa
- Nhà ở → Tiền thuê, Điện nước, Internet, Đồ gia dụng
- Di chuyển → Xăng, Grab/taxi, Gửi xe, Bảo trì xe
- Mua sắm → Quần áo, Điện tử, Gia dụng
- Giải trí → Phim/show, Game, Du lịch, Sở thích
- Sức khỏe → Khám bệnh, Thuốc, Gym, Bảo hiểm
- Giáo dục → Khóa học, Sách, Học phí
- Gia đình → Con cái, Biếu bố mẹ, Quà tặng
- Tài chính → Trả nợ, Lãi vay, Phí ngân hàng, Bảo hiểm nhân thọ
- Khác

**Default Income Categories:**
- Lương, Thưởng, Freelance, Đầu tư, Cho thuê, Quà/biếu, Hoàn tiền, Khác

---

### Tag

Nhãn tùy chỉnh linh hoạt cho giao dịch.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `UUID` | Primary key |
| `name` | `String` | Tên tag |
| `color` | `String?` | Hex color (optional) |
| `createdAt` | `Date` | Ngày tạo |

**Relationships:** `transactions` → `[Transaction]` (many-to-many)

---

### Budget

Giới hạn chi tiêu cho danh mục theo kỳ.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `UUID` | Primary key |
| `category` | `Category` | Danh mục áp dụng |
| `amount` | `Decimal` | Số tiền giới hạn |
| `period` | `BudgetPeriod` | Kỳ ngân sách |
| `startDate` | `Date` | Ngày bắt đầu |
| `rollover` | `Bool` | Tiền dư chuyển sang kỳ sau (Premium) |
| `rolledAmount` | `Decimal` | Số tiền rollover từ kỳ trước |
| `alertThresholds` | `[Double]` | Ngưỡng cảnh báo (VD: [0.5, 0.8, 1.0]) |
| `createdAt` | `Date` | Ngày tạo |
| `updatedAt` | `Date` | Ngày cập nhật |

**Business Rules:**
- Free: tối đa 3 budgets · Premium: không giới hạn + rollover + smart suggest
- Smart suggest: gợi ý budget dựa trên trung bình chi tiêu 3 tháng
- Color-coded: xanh (< 50%), vàng (50-80%), cam (80-100%), đỏ (> 100%)

---

### Goal

Mục tiêu tiết kiệm tài chính.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `UUID` | Primary key |
| `name` | `String` | Tên mục tiêu (VD: "Mua iPhone 16") |
| `targetAmount` | `Decimal` | Số tiền cần đạt |
| `currentAmount` | `Decimal` | Số tiền hiện tại |
| `deadline` | `Date?` | Hạn chót (optional) |
| `icon` | `String` | SF Symbol hoặc emoji |
| `color` | `String` | Hex color |
| `linkedAccount` | `Account?` | Tài khoản tiết kiệm liên kết |
| `autoContributeRule` | `AutoContributeRule?` | Rule đóng góp tự động (Premium) |
| `createdAt` | `Date` | Ngày tạo |
| `updatedAt` | `Date` | Ngày cập nhật |

**Business Rules:**
- Free: tối đa 2 goals · Premium: không giới hạn + auto-contribute
- Celebration animation khi đạt 25%, 50%, 75%, 100%
- Smart nudge: "Bạn cần tiết kiệm X/tuần để đạt mục tiêu đúng hạn"

---

### RecurringRule

Template cho giao dịch lặp lại.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `UUID` | Primary key |
| `frequency` | `RecurringFrequency` | Tần suất lặp |
| `interval` | `Int` | Bước nhảy (VD: every 2 weeks → frequency=weekly, interval=2) |
| `nextDate` | `Date` | Ngày tạo giao dịch tiếp theo |
| `endDate` | `Date?` | Ngày kết thúc (nil = vĩnh viễn) |
| `templateAmount` | `Decimal` | Số tiền template |
| `templateNote` | `String?` | Ghi chú template |
| `templateCategory` | `Category` | Danh mục template |
| `templateAccount` | `Account` | Tài khoản template |
| `templateType` | `TransactionType` | Loại giao dịch |
| `isAutoConfirm` | `Bool` | Tự động tạo hay chờ confirm |
| `reminderDaysBefore` | `Int` | Nhắc trước bao nhiêu ngày (1-3) |
| `createdAt` | `Date` | Ngày tạo |
| `updatedAt` | `Date` | Ngày cập nhật |

**Business Rules:**
- Free: tối đa 5 recurring · Premium: không giới hạn + subscription tracking
- Push notification trước 1-3 ngày
- Calendar view hiển thị tất cả recurring

---

### Debt

Quản lý nợ vay và cho vay cá nhân.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `UUID` | Primary key |
| `name` | `String` | Tên khoản nợ |
| `type` | `DebtType` | Nợ của tôi hay người khác nợ tôi |
| `principalAmount` | `Decimal` | Số tiền gốc |
| `remainingAmount` | `Decimal` | Số tiền còn lại |
| `interestRate` | `Decimal?` | Lãi suất (%/năm, nil cho vay cá nhân) |
| `interestType` | `InterestType?` | Cố định / thả nổi |
| `personName` | `String?` | Tên người vay/cho vay |
| `dueDate` | `Date?` | Ngày đến hạn |
| `notes` | `String?` | Ghi chú |
| `createdAt` | `Date` | Ngày tạo |
| `updatedAt` | `Date` | Ngày cập nhật |

**Relationships:** `payments` → `[Transaction]` (các lần trả nợ)

**Business Rules:**
- Free: tối đa 3 records · Premium: không giới hạn + Snowball/Avalanche strategies
- Hỗ trợ lãi suất thả nổi (phổ biến ở VN)

---

### SharedWallet (Phase 4)

Ví chung cho gia đình/cặp đôi.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `UUID` | Primary key |
| `name` | `String` | Tên ví chung |
| `members` | `[SharedWalletMember]` | Danh sách thành viên |
| `inviteCode` | `String` | Mã mời tham gia |
| `createdAt` | `Date` | Ngày tạo |
| `updatedAt` | `Date` | Ngày cập nhật |

### SharedWalletMember

| Field | Type | Description |
|-------|------|-------------|
| `id` | `UUID` | Primary key |
| `userIdentifier` | `String` | Apple ID / CloudKit user record |
| `role` | `WalletRole` | Quyền hạn |
| `joinedAt` | `Date` | Ngày tham gia |

---

### ExchangeRate

Tỷ giá quy đổi tiền tệ.

| Field | Type | Description |
|-------|------|-------------|
| `baseCurrency` | `CurrencyCode` | Đồng tiền gốc |
| `targetCurrency` | `CurrencyCode` | Đồng tiền đích |
| `rate` | `Decimal` | Tỷ giá |
| `date` | `Date` | Ngày cập nhật |
| `source` | `String` | Nguồn tỷ giá (API provider) |

**Business Rules:** Free: cập nhật hàng ngày · Premium: real-time rates

---

### Bill (Phase 2)

Hóa đơn cần thanh toán định kỳ.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `UUID` | Primary key |
| `name` | `String` | Tên hóa đơn |
| `amount` | `Decimal` | Số tiền (cố định hoặc ước lượng) |
| `isEstimated` | `Bool` | Số tiền chỉ là ước lượng |
| `dueDate` | `Date` | Ngày đến hạn |
| `frequency` | `RecurringFrequency` | Tần suất |
| `category` | `Category` | Danh mục liên kết |
| `isPaid` | `Bool` | Đã thanh toán kỳ này chưa |
| `reminderDaysBefore` | `[Int]` | Nhắc trước bao nhiêu ngày [3, 1, 0] |
| `createdAt` | `Date` | Ngày tạo |
| `updatedAt` | `Date` | Ngày cập nhật |

**Default VN Bills:** Tiền điện, Tiền nước, Internet, Tiền nhà

---

## Enums

### TransactionType
```swift
enum TransactionType: String, Codable, Sendable {
    case income
    case expense
    case transfer
}
```

### AccountType
```swift
enum AccountType: String, Codable, Sendable {
    case cash          // Tiền mặt
    case bank          // Ngân hàng (checking/savings)
    case creditCard    // Thẻ tín dụng
    case eWallet       // Ví điện tử (MoMo, ZaloPay, VNPay)
    case savings       // Tiết kiệm
    case investment    // Đầu tư
    case loan          // Vay
}
```

### BudgetPeriod
```swift
enum BudgetPeriod: String, Codable, Sendable {
    case weekly
    case monthly
    case yearly
}
```

### RecurringFrequency
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

### DebtType
```swift
enum DebtType: String, Codable, Sendable {
    case owedByMe     // Tôi nợ người khác
    case owedToMe     // Người khác nợ tôi
}
```

### InterestType
```swift
enum InterestType: String, Codable, Sendable {
    case fixed         // Lãi suất cố định
    case floating      // Lãi suất thả nổi (phổ biến VN)
}
```

### WalletRole
```swift
enum WalletRole: String, Codable, Sendable {
    case owner         // Full access
    case member        // Add transactions, view reports
    case viewer        // Xem only
}
```

### CurrencyCode
```swift
// ISO 4217 — Các đồng tiền hỗ trợ ban đầu
enum CurrencyCode: String, Codable, Sendable {
    case VND  // Việt Nam Đồng (mặc định)
    case USD  // US Dollar
    case EUR  // Euro
    case JPY  // Japanese Yen
    case KRW  // Korean Won
    case THB  // Thai Baht
    case SGD  // Singapore Dollar
    case AUD  // Australian Dollar
    case GBP  // British Pound
    case CNY  // Chinese Yuan
}
```

---

## Entity Relationship Diagram

```
Account ◄──── Transaction ────► Category
  │               │                 │
  │               │                 └── parent ──► Category
  │               │
  │               ├── tags ◄──► Tag (many-to-many)
  │               │
  │               └── recurringRule ──► RecurringRule
  │
  ├── linkedGoal ◄── Goal
  │
  └── SharedWallet ──► SharedWalletMember

Budget ──► Category
Debt ──► [Transaction] (payments)
Bill ──► Category
ExchangeRate (standalone)
```

---

## Data Storage Strategy

| Concern | Approach |
|---------|----------|
| **Persistence** | SwiftData (backed by SQLite) |
| **Encryption** | SQLCipher cho data at rest |
| **Sync** | CloudKit private database (NSPersistentCloudKitContainer) |
| **Conflict** | Last-write-wins cho simple fields, merge cho transactions |
| **Offline** | Full offline-first, sync khi có mạng |
| **Migration** | Lightweight migration via SwiftData schema versioning |
| **Soft Delete** | `deletedAt` field, filtered out in queries, synced to CloudKit |
| **Amounts** | `Decimal` everywhere — never `Double` for money |
| **Dates** | UTC storage, local timezone display |

## VND-Specific Considerations

- VND không có đơn vị nhỏ (xu) → không hiện decimal places
- Format: `1.000.000 ₫` (dấu chấm phân cách hàng nghìn)
- Quick input shortcuts: `k` = ×1.000, `tr` = ×1.000.000
  - VD: `150k` → `150.000₫`, `1.5tr` → `1.500.000₫`
- Số tiền lớn phổ biến → UI cần handle hiển thị gọn (VD: `1,5tr` thay vì `1.500.000`)
