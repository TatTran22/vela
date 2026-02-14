# API Specification

## Overview

FinanceApp là ứng dụng **offline-first**. Phần lớn xử lý diễn ra trên device.
External APIs chỉ dùng cho sync, exchange rates, và AI cloud features (Premium).

---

## 1. CloudKit API (iCloud Sync)

| Property | Value |
|----------|-------|
| **Container** | `iCloud.com.yourteam.FinanceApp` |
| **Database** | Private (user-specific data) |
| **Sync mechanism** | `NSPersistentCloudKitContainer` (automatic) |
| **Encryption** | Apple end-to-end encryption |

### Synced Entities
Tất cả core entities sync qua CloudKit private database:
- Account, Transaction, Category, Tag, Budget, Goal
- RecurringRule, Debt, Bill, ExchangeRate (cached)
- SharedWallet (dùng CloudKit shared database cho multi-user)

### Sync States
| State | Icon | Description |
|-------|------|-------------|
| Synced | ✓ | Data đã đồng bộ thành công |
| Syncing | ↻ | Đang đồng bộ |
| Offline | ○ | Không có kết nối, sẽ sync khi online |
| Error | ✗ | Lỗi sync, cần retry |

### Conflict Resolution
- **Simple fields** (name, amount, note...): Last-write-wins
- **Transactions**: Merge strategy — cả 2 versions đều giữ lại
- **Soft delete**: `deletedAt` field, filtered in queries, synced properly

---

## 2. Exchange Rate API

| Property | Value |
|----------|-------|
| **Provider** | Configurable (VD: exchangeratesapi.io, Open Exchange Rates) |
| **Base URL** | `https://api.exchangeratesapi.io/v1/` |
| **Auth** | API key (stored in Keychain) |
| **Transport** | HTTPS (TLS 1.3, certificate pinning) |

### Endpoints

#### GET `/latest`
Lấy tỷ giá mới nhất.

**Request:**
```
GET /latest?base=VND&symbols=USD,EUR,JPY,KRW,THB,SGD,AUD,GBP,CNY
Authorization: Bearer {api_key}
```

**Response:**
```json
{
  "base": "VND",
  "date": "2026-02-13",
  "rates": {
    "USD": 0.000039,
    "EUR": 0.000037,
    "JPY": 0.0059
  }
}
```

**Caching:**
- Free tier: cache 24 giờ, fetch mỗi ngày 1 lần
- Premium: cache 1 giờ, gần real-time

### Supported Currencies
VND (default), USD, EUR, JPY, KRW, THB, SGD, AUD, GBP, CNY
— mở rộng thêm theo nhu cầu.

---

## 3. AI Cloud API (Premium)

| Property | Value |
|----------|-------|
| **Provider** | Anthropic (Claude API) |
| **Backend proxy** | Custom backend relay (không expose API key trên client) |
| **Auth** | App authentication token (Keychain) |
| **Privacy** | Chỉ gửi aggregated data, KHÔNG gửi raw transactions hay PII |

### 3.1 AI Financial Assistant (Chat)

**Endpoint:** `POST /api/v1/ai/chat`

**Request:**
```json
{
  "message": "Tháng này tôi chi bao nhiêu cho ăn uống?",
  "context": {
    "currency": "VND",
    "locale": "vi",
    "monthly_summary": {
      "income_total": 30000000,
      "expense_total": 22000000,
      "category_breakdown": {
        "food_dining": 8500000,
        "transport": 3200000,
        "entertainment": 2100000
      }
    },
    "budget_status": {
      "food_dining": { "limit": 8000000, "spent": 8500000 }
    }
  }
}
```

**Response:**
```json
{
  "reply": "Tháng này bạn đã chi 8.500.000₫ cho ăn uống, vượt ngân sách 500.000₫ (6.25%). Bạn nên cân nhắc giảm chi tiêu ăn ngoài trong tuần còn lại.",
  "suggestions": ["Xem chi tiết ăn uống", "Điều chỉnh budget"]
}
```

**Limits:**
- Premium: 20 questions/tháng
- Family: 40 questions/tháng
- Model: Claude Sonnet

### 3.2 AI Insights Generator

**Endpoint:** `POST /api/v1/ai/insights`

**Request:**
```json
{
  "type": "weekly_digest",
  "locale": "vi",
  "data": {
    "period": "2026-W07",
    "total_expense": 5200000,
    "vs_last_week": 1.15,
    "top_categories": [
      { "name": "food_dining", "amount": 2100000, "vs_avg": 1.4 }
    ],
    "anomalies": [
      { "category": "shopping", "amount": 1500000, "avg": 500000 }
    ]
  }
}
```

**Response:**
```json
{
  "insights": [
    {
      "type": "anomaly",
      "title": "Chi tiêu Mua sắm tăng đột biến",
      "body": "Tuần này bạn chi 1.500.000₫ cho mua sắm, gấp 3 lần trung bình.",
      "priority": "high"
    }
  ]
}
```

**Delivery:** Weekly digest (push + in-app), Monthly report
**Model:** Claude Haiku (cost-effective)

### 3.3 Receipt Processing (Cloud fallback)

**Endpoint:** `POST /api/v1/ai/receipt`

**Request:** `multipart/form-data` with receipt image

**Response:**
```json
{
  "total": 385000,
  "currency": "VND",
  "date": "2026-02-12",
  "merchant": "Highland Coffee",
  "items": [
    { "name": "Phin Sữa Đá", "amount": 45000 },
    { "name": "Bánh Mì", "amount": 35000 }
  ],
  "confidence": 0.92
}
```

**Trigger:** Chỉ khi on-device OCR accuracy < 70% VÀ user opt-in

---

## 4. On-Device AI APIs (Core ML / Vision)

### 4.1 Auto-Categorization
| Property | Value |
|----------|-------|
| **Framework** | Core ML (Text Classifier) |
| **Input** | Transaction note, amount, time, frequency |
| **Output** | Top 3 categories + confidence scores |
| **Latency** | < 50ms |
| **Privacy** | 100% on-device, data never leaves device |

### 4.2 Receipt OCR
| Property | Value |
|----------|-------|
| **Framework** | Vision framework + Core ML |
| **Supported** | Hóa đơn VAT VN, receipt POS, bill nhà hàng, hóa đơn điện/nước |
| **VN-specific** | Nhận diện VND format (1.000.000 / 1,000,000 / 1000000), tiếng Việt |
| **Latency** | < 3 seconds |

### 4.3 Cash Flow Forecasting
| Property | Value |
|----------|-------|
| **Framework** | Create ML TabularRegressor |
| **Input** | Historical transactions, recurring rules, seasonal patterns |
| **Output** | Predicted balance cho 1-3 tháng tới |
| **Training** | Per-user, on-device, updated weekly |

### 4.4 Anomaly Detection
| Property | Value |
|----------|-------|
| **Method** | Statistical (z-score, IQR) — no ML model |
| **Trigger** | Real-time khi tạo transaction mới |
| **Alert** | Khi spending > 2σ so với historical average |

---

## 5. Internal Module APIs

### FinanceCore — Public Protocols

```swift
// Transaction operations
protocol TransactionRepository: Sendable {
    func fetch(filter: TransactionFilter) async throws -> [Transaction]
    func save(_ transaction: Transaction) async throws
    func update(_ transaction: Transaction) async throws
    func delete(_ transaction: Transaction) async throws
    func search(query: String) async throws -> [Transaction]
}

// Account operations
protocol AccountRepository: Sendable {
    func fetchAll() async throws -> [Account]
    func save(_ account: Account) async throws
    func update(_ account: Account) async throws
    func archive(_ account: Account) async throws
    func totalBalance(in currency: CurrencyCode) async throws -> Decimal
}

// Budget operations
protocol BudgetRepository: Sendable {
    func fetchAll() async throws -> [Budget]
    func save(_ budget: Budget) async throws
    func spending(for budget: Budget, in period: DateInterval) async throws -> Decimal
}

// Category operations
protocol CategoryRepository: Sendable {
    func fetchAll(type: TransactionType?) async throws -> [Category]
    func save(_ category: Category) async throws
    func suggestCategory(for note: String, amount: Decimal) async throws -> [CategorySuggestion]
}

// Exchange rate operations
protocol ExchangeRateService: Sendable {
    func rate(from: CurrencyCode, to: CurrencyCode) async throws -> Decimal
    func convert(_ amount: Decimal, from: CurrencyCode, to: CurrencyCode) async throws -> Decimal
    func refreshRates() async throws
}

// Goal operations
protocol GoalRepository: Sendable {
    func fetchAll() async throws -> [Goal]
    func save(_ goal: Goal) async throws
    func contribute(_ amount: Decimal, to goal: Goal) async throws
}

// Report generation
protocol ReportService: Sendable {
    func generateMonthlyReport(for month: Date) async throws -> MonthlyReport
    func categoryBreakdown(in period: DateInterval) async throws -> [CategoryBreakdown]
    func incomeVsExpense(in period: DateInterval) async throws -> IncomeExpenseReport
    func netWorth(at date: Date) async throws -> NetWorthReport
}
```

### FinanceData — Implementation Details
- `SwiftDataTransactionRepository` — SwiftData-backed implementation
- `SwiftDataAccountRepository`
- `CloudKitSyncManager` — Manages sync status and conflict resolution
- `CoreMLCategorizationService` — On-device auto-categorization
- `VisionReceiptScanner` — On-device OCR
- `CachedExchangeRateService` — Rate fetching with local cache

### FinanceUI — Public Components
- `AmountText` — Formatted currency display with color
- `TransactionRow` — List row for transactions
- `AccountCard` — Account summary card
- `BudgetProgressBar` — Color-coded budget progress
- `CategoryPicker` — Grid/list category selector
- `QuickAmountInput` — Custom numpad with calculator
- `ChartViews` — Pie, Bar, Line charts
- `SyncStatusIndicator` — CloudKit sync status badge

---

## 6. App Intents & Shortcuts API

### Registered Intents
```swift
// Quick transaction input
struct AddTransactionIntent: AppIntent {
    @Parameter(title: "Amount") var amount: Decimal
    @Parameter(title: "Category") var category: CategoryEntity
    @Parameter(title: "Account") var account: AccountEntity?
    @Parameter(title: "Note") var note: String?
}

// Query intents
struct GetTodaySpendingIntent: AppIntent { }
struct GetBudgetStatusIntent: AppIntent {
    @Parameter(title: "Category") var category: CategoryEntity?
}
struct GetAccountBalanceIntent: AppIntent {
    @Parameter(title: "Account") var account: AccountEntity
}
```

### Siri Phrases (Vietnamese + English)
- "Ghi chi tiêu 50 nghìn cho café" / "Add expense 50k for coffee"
- "Hôm nay chi bao nhiêu?" / "How much did I spend today?"
- "Còn bao nhiêu budget ăn uống?" / "How much food budget left?"

---

## 7. Push Notifications

| Type | Trigger | Content |
|------|---------|---------|
| Budget alert | Spending reaches 80%, 100% of budget | "Budget Ăn uống đã dùng 80% (6,4tr/8tr)" |
| Bill reminder | 3 days, 1 day before due date | "Tiền thuê nhà 8.000.000₫ đến hạn ngày 1/3" |
| Recurring confirm | On recurring transaction date | "Xác nhận giao dịch Netflix 199.000₫?" |
| AI insight | Weekly (configurable) | "Chi tiêu tuần này: insights mới" |
| Goal milestone | At 25%, 50%, 75%, 100% | "Chúc mừng! Mục tiêu 'Mua iPhone' đạt 50%! 🎉" |
| Debt reminder | Before due date | "Nhắc: bạn cần trả 2.000.000₫ cho Minh trước 15/3" |

---

## 8. Data Import/Export

### Import Formats
| Source | Format | Phase |
|--------|--------|-------|
| CSV (generic) | `.csv` | MVP |
| Money Lover | `.csv` (export format) | Phase 4 |
| Monefy, Spendee, YNAB, MoneyWiz | `.csv` variants | Phase 4 |
| VN Bank Statements | CSV, Excel, PDF (OCR) | Phase 4 |

**Supported VN Banks:** Vietcombank, Techcombank, BIDV, VPBank, MBBank, ACB, TPBank

### Export Formats
| Format | Content | Tier |
|--------|---------|------|
| CSV | Raw transaction data | Premium |
| JSON | Structured data backup | Premium |
| PDF | Formatted monthly/annual report | Premium |
| Share Image | Visual summary card for social | Premium |

### Backup
- iCloud automatic (via CloudKit sync)
- Manual export JSON (full data backup)
- Settings → Data → Export
