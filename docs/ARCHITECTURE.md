# Architecture Overview

## Tầm Nhìn Kiến Trúc

FinanceApp là ứng dụng quản lý tài chính cá nhân **offline-first**, **privacy-first**,
native Apple, với AI hybrid (on-device + cloud). Kiến trúc đặt ưu tiên:

1. **Privacy**: Data tài chính mã hóa, AI on-device khi có thể
2. **Offline-first**: Hoạt động hoàn toàn offline, sync khi có mạng
3. **Native Apple**: Tận dụng toàn bộ ecosystem (iCloud, Widgets, Shortcuts, Watch, Handoff)
4. **Modular**: Swift Packages cho code sharing và testability

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Presentation Layer                         │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────────┐ │
│  │FinanceApp-  │  │FinanceApp-   │  │ Extensions             │ │
│  │iOS          │  │macOS         │  │ (Widgets, Watch,       │ │
│  │(SwiftUI)    │  │(SwiftUI)     │  │  Shortcuts, Intents)   │ │
│  └──────┬──────┘  └──────┬───────┘  └───────────┬────────────┘ │
├─────────┼────────────────┼──────────────────────┼──────────────┤
│         └────────────────┼──────────────────────┘              │
│                          ▼                                      │
│              Shared UI Layer                                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Packages/FinanceUI                                       │  │
│  │ Design System · Reusable Components · Theme · Charts     │  │
│  └──────────────────────────┬───────────────────────────────┘  │
├─────────────────────────────┼──────────────────────────────────┤
│                             ▼                                   │
│              Domain Layer                                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Packages/FinanceCore                                     │  │
│  │ Models · Use Cases · Protocols · Business Rules          │  │
│  │ AI/ML Interfaces · Formatters · Validators               │  │
│  └──────────────────────────┬───────────────────────────────┘  │
├─────────────────────────────┼──────────────────────────────────┤
│                             ▼                                   │
│              Data Layer                                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Packages/FinanceData                                     │  │
│  │ Repositories · SwiftData/CoreData · CloudKit Sync        │  │
│  │ Core ML Models · Exchange Rate Service · Import/Export   │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Module Dependencies

```
FinanceApp-iOS ──────┐
                     ├──► FinanceCore
FinanceApp-macOS ────┤    (no internal deps)
                     │
                     ├──► FinanceUI ──► FinanceCore
                     │
                     └──► FinanceData ──► FinanceCore

Widget Extension ────► FinanceCore, FinanceData
Watch App ───────────► FinanceCore, FinanceData
Shortcuts/Intents ───► FinanceCore, FinanceData
```

**Dependency Rules:**
- `FinanceCore` → **không** dependency nội bộ nào (platform-agnostic)
- `FinanceUI` → chỉ depend `FinanceCore`
- `FinanceData` → chỉ depend `FinanceCore`
- App targets → depend tất cả packages
- **KHÔNG** circular dependencies

---

## Key Patterns

### MVVM (Model-View-ViewModel)

```
┌─────────────┐     ┌───────────────┐     ┌──────────────┐
│    View      │────►│  ViewModel    │────►│  Use Case    │
│  (SwiftUI)   │     │  (@Observable)│     │  (Protocol)  │
│              │◄────│               │◄────│              │
│  - Binding   │     │  - State      │     │  - Logic     │
│  - Layout    │     │  - Actions    │     │  - Rules     │
│  - No logic  │     │  - Transform  │     │  - Validation│
└─────────────┘     └───────────────┘     └──────┬───────┘
                                                  │
                                           ┌──────▼───────┐
                                           │  Repository  │
                                           │  (Protocol)  │
                                           │              │
                                           │  - CRUD      │
                                           │  - Query     │
                                           │  - Sync      │
                                           └──────────────┘
```

- **Views**: Chỉ bind data + layout, KHÔNG chứa business logic
- **ViewModels**: `@Observable`, inject dependencies via `init`, expose state
- **Use Cases**: Protocol + implementation, single responsibility, pure business logic
- **Repositories**: Protocol-based abstraction, implementation trong FinanceData

### Repository Pattern
```swift
// Trong FinanceCore (protocol)
protocol TransactionRepository: Sendable {
    func fetch(filter: TransactionFilter) async throws -> [Transaction]
    func save(_ transaction: Transaction) async throws
    func delete(_ transaction: Transaction) async throws
}

// Trong FinanceData (implementation)
final class SwiftDataTransactionRepository: TransactionRepository { ... }
```

### Dependency Injection
- Protocol-based, inject via `init`
- Không dùng 3rd party DI framework
- App-level composition root tạo dependencies

---

## Platform Architecture

### iOS App
- `NavigationStack` + `NavigationPath` cho navigation
- FAB (Floating Action Button) cho quick transaction input
- Tab-based layout: Dashboard, Transactions, Budgets, Reports, Settings
- Custom numpad với calculator cho nhập số tiền
- Adaptive layout cho iPhone SE → iPhone Pro Max

### macOS App
- `NavigationSplitView` (sidebar + detail)
- Menu bar quick-entry widget
- Keyboard shortcuts cho mọi action (⌘+N = new transaction...)
- Multi-window support (dashboard + entry cùng lúc)
- Table view với sort/filter mạnh, multi-select, bulk edit
- Dense information display phù hợp desktop

### iPadOS (Phase 4)
- Split view: list + detail cùng lúc
- Apple Pencil support (annotate receipts)
- Keyboard shortcuts
- Stage Manager support

### watchOS (Phase 2)
- Quick input: số tiền + category phổ biến
- Complication: chi tiêu hôm nay hoặc số dư
- Glance: tổng chi tiêu hôm nay, budget remaining

### Widgets (iOS/macOS)
- **Small**: Tổng số dư hoặc chi tiêu hôm nay
- **Medium**: Chi tiêu tuần này + mini chart
- **Large**: Top categories + giao dịch gần nhất
- Interactive: tap → mở app đúng section
- WidgetKit + App Intents

### Siri Shortcuts & App Intents
- "Ghi chi tiêu [số tiền] cho [danh mục]"
- "Hôm nay chi bao nhiêu?"
- "Còn bao nhiêu budget ăn uống?"
- Custom Shortcuts workflows

---

## AI Architecture — Hybrid Strategy

### Layer 1: On-Device AI (Core ML / Create ML)

```
┌───────────────────────────────────────────────────────────────┐
│                  ON-DEVICE AI (Free tier)                     │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────┐   ┌──────────────────────────────┐  │
│  │ Auto-Categorize     │   │ Receipt OCR                  │  │
│  │ (Text Classifier)   │   │ (Vision + Core ML)           │  │
│  ├─────────────────────┤   ├──────────────────────────────┤  │
│  │ Input: note, amount,│   │ Input: camera image          │  │
│  │   time, frequency   │   │ Output: amount, date,        │  │
│  │ Output: top 3       │   │   merchant, items            │  │
│  │   categories +      │   │ VN support: VND format,      │  │
│  │   confidence        │   │   hóa đơn tiếng Việt         │  │
│  │ Target: 70% @50tx,  │   │ Fallback: cloud nếu <70%    │  │
│  │   85% @200tx        │   │   accuracy                   │  │
│  └─────────────────────┘   └──────────────────────────────┘  │
│                                                               │
│  ┌─────────────────────┐   ┌──────────────────────────────┐  │
│  │ Pattern Detection   │   │ Anomaly Detection            │  │
│  │ (Tabular ML)        │   │ (Statistical: z-score, IQR)  │  │
│  ├─────────────────────┤   ├──────────────────────────────┤  │
│  │ Detect recurring    │   │ Flag unusual spending        │  │
│  │ patterns, habits    │   │ vs historical average        │  │
│  └─────────────────────┘   └──────────────────────────────┘  │
│                                                               │
│  ┌─────────────────────┐                                     │
│  │ Cash Flow Forecast  │                                     │
│  │ (Time Series ML)    │                                     │
│  │ Create ML Tabular   │                                     │
│  │ Regressor           │                                     │
│  └─────────────────────┘                                     │
│                                                               │
│  Privacy: ✓ 100% on-device                                  │
│  Latency: < 100ms (categorize < 50ms)                       │
│  Requires: iOS 17+ / macOS 14+                              │
└───────────────────────────────────────────────────────────────┘
```

### Layer 2: Cloud AI (Premium tier)

```
┌───────────────────────────────────────────────────────────────┐
│                  CLOUD AI (Premium only)                      │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────┐   ┌──────────────────────────────┐  │
│  │ AI Financial        │   │ Natural Language Insights     │  │
│  │ Assistant (Chat)    │   │ Generator                    │  │
│  ├─────────────────────┤   ├──────────────────────────────┤  │
│  │ Claude Sonnet API   │   │ Claude Haiku API             │  │
│  │ Context: aggregated │   │ Input: aggregated spending   │  │
│  │ data only, no PII   │   │ Output: weekly/monthly       │  │
│  │ 20 questions/month  │   │ digest in natural language   │  │
│  └─────────────────────┘   └──────────────────────────────┘  │
│                                                               │
│  ┌─────────────────────┐   ┌──────────────────────────────┐  │
│  │ Advanced Receipt    │   │ Comparative Analysis         │  │
│  │ Processing          │   │ (Anonymous benchmarks)       │  │
│  ├─────────────────────┤   ├──────────────────────────────┤  │
│  │ Fallback khi on-    │   │ Opt-in: so sánh với peers    │  │
│  │ device OCR < 70%    │   │ cùng mức thu nhập            │  │
│  └─────────────────────┘   └──────────────────────────────┘  │
│                                                               │
│  Privacy: Aggregated data only, no PII sent                  │
│  Latency: 1-3 seconds                                       │
│  Cost: ~$0.002-0.01 per request                              │
└───────────────────────────────────────────────────────────────┘
```

### AI Data Flow & Privacy

```
User Data (on device)
    │
    ├─ Raw transactions ──────► NEVER leaves device
    ├─ Receipt images ────────► On-device OCR first
    │                            └─► Cloud only if on-device fails (opt-in)
    │
    ├─ Aggregated summaries ──► Cloud AI (Premium)
    │   (category totals, trends — no individual transactions)
    │
    └─ Anonymous benchmarks ──► Cloud (opt-in only)
        (income bracket, spending ratios — no identity)
```

### Model Training Pipeline

| Model | Training Approach | Update Frequency |
|-------|------------------|-----------------|
| Categorizer | Pre-trained VN spending data + federated fine-tuning on-device | Continuous (on-device) |
| Receipt OCR | Pre-trained Vision + fine-tuned VN receipts/invoices | Quarterly (app update) |
| Forecasting | Create ML TabularRegressor, trained per-user on-device | Weekly (on-device) |
| Anomaly | Statistical (z-score, IQR) — no ML model needed | Real-time |
| NL Insights | Claude API with prompt engineering | Prompt updates via server config |

---

## Data & Sync Architecture

### Offline-First Strategy

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│   iPhone     │      │   CloudKit   │      │   Mac        │
│              │      │   Private DB │      │              │
│  SwiftData   │◄────►│              │◄────►│  SwiftData   │
│  (SQLite +   │ sync │   Apple E2E  │ sync │  (SQLite +   │
│   SQLCipher) │      │   Encrypted  │      │   SQLCipher) │
│              │      │              │      │              │
│  ✓ Full      │      │              │      │  ✓ Full      │
│    offline   │      │              │      │    offline   │
└──────────────┘      └──────────────┘      └──────────────┘
```

- **Mechanism**: `NSPersistentCloudKitContainer`
- **Conflict Resolution**: Last-write-wins cho simple fields, merge cho transactions
- **Sync Status**: UI hiển thị synced ✓ / syncing ↻ / offline ○
- **Soft Delete**: `deletedAt` field, CloudKit cần pour proper sync

### Data Security

| Layer | Implementation |
|-------|---------------|
| Data at rest | SwiftData + SQLCipher encryption |
| Data in transit | TLS 1.3, certificate pinning |
| Authentication | Biometric (Face ID/Touch ID) + passcode |
| Sensitive data | Keychain for API keys, tokens |
| Cloud sync | CloudKit (Apple end-to-end encryption) |
| AI data | Aggregated only, no PII to cloud |
| App lock | Auto-lock after 1/5/15 minutes (configurable) |

---

## Performance Targets

| Metric | Target |
|--------|--------|
| App launch → interactive | < 1 second |
| Transaction input → save | < 100ms |
| Receipt scan → result | < 3 seconds |
| AI categorization | < 50ms |
| Search 10K transactions | < 200ms |
| Sync conflict resolution | < 500ms |
| App size | < 50MB |

---

## Localization Architecture

| Language | Priority | Scope |
|----------|----------|-------|
| Tiếng Việt | P0 | Full app |
| English | P0 | Full app |
| 日本語 | P2 | Basic UI |
| 한국어 | P2 | Basic UI |

- App tự detect locale → suggest ngôn ngữ + đồng tiền
- Cho đổi thủ công trong Settings
- String catalogs cho localization
- Category names: hệ thống localized (VD: "Ăn uống" / "Food & Dining")

---

## Accessibility

- VoiceOver support 100%
- Dynamic Type (all text sizes)
- Color contrast ≥ 4.5:1
- Reduce Motion support
- Bold Text support
- Switch Control compatible
- Semantic colors cho income (green) / expense (red) + icon indicators

---

## Deployment & Requirements

| Platform | Min Version | Notes |
|----------|-------------|-------|
| iOS | 17.0 | Primary target |
| macOS | 14.0 | Companion app |
| watchOS | 10.0 | Phase 2 |
| iPadOS | 17.0 | Phase 4 (shares iOS target) |

- **Language**: Swift 6.1+, strict concurrency
- **UI**: SwiftUI (primary), AppKit integration khi cần trên macOS
- **Data**: SwiftData + CloudKit sync
- **Testing**: XCTest, Swift Testing framework, XCUITest
- **CI/CD**: Xcode Cloud hoặc GitHub Actions
