# Phase 2 — Core Growth (Tháng 4-6)

> **Mục tiêu**: Biến tracking thành planning. Thêm budget, goals,
> recurring, và on-device AI cơ bản.

## Tổng Quan

| Metric | Target |
|--------|--------|
| Tổng features mới | 9 features |
| Platforms | iOS + macOS + watchOS (basic) |
| Timeline | Tháng 4-6 |
| Goal | 5,000 users, 10% Premium trial |
| Validation | Users có set budget và quay lại check không? |

---

## Features

### F2.1 — Budget Theo Danh Mục

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Đặt giới hạn chi tiêu cho từng danh mục mỗi tháng |
| **Tạo** | Chọn category → nhập số tiền → chọn kỳ (tháng/tuần) |
| **Tracking** | Progress bar: đã chi / ngân sách, % đã dùng |
| **Alerts** | Push khi đạt 80%, 100%, vượt budget |
| **Rollover** | Premium: tiền dư → cộng kỳ sau |
| **Smart suggest** | Gợi ý budget dựa trên TB 3 tháng trước |
| **Tier** | 🆓 Free: 3 budgets · 💎 Premium: unlimited + rollover + suggest |

### F2.2 — Budget Tổng (Envelope Method)

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Concept** | "Mỗi đồng đều có việc": Thu nhập → phân bổ vào categories |
| **Flow** | Có thu nhập → app hỏi "Phân bổ vào đâu?" → kéo thả / quick assign |
| **Ưu tiên** | Thiết yếu → Muốn có → Tiết kiệm/Đầu tư |
| **Tier** | 💎 Premium |

### F2.3 — Recurring Transactions

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Tần suất** | Hàng ngày, tuần, 2 tuần, tháng, quý, năm, tùy chỉnh |
| **Ví dụ** | Tiền thuê (1/tháng), Lương (25/tháng), Netflix (hàng tháng) |
| **Hành vi** | Tự động tạo giao dịch, cho skip/edit trước confirm |
| **Nhắc nhở** | Push notification trước 1-3 ngày |
| **Calendar** | Xem tất cả recurring trên lịch tháng |
| **Subscription** | Gom nhóm subscriptions → tổng chi phí/tháng |
| **Tier** | 🆓 Free: 5 recurring · 💎 Premium: unlimited + subscription tracking |

### F2.4 — Savings Goals

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Tạo goal** | Tên, số tiền mục tiêu, deadline, icon/ảnh |
| **Tracking** | Progress ring/bar, còn thiếu, dự kiến hoàn thành |
| **Đóng góp** | Thủ công hoặc auto (link tài khoản tiết kiệm) |
| **Smart nudge** | "Cần tiết kiệm 500K/tuần để đạt mục tiêu đúng hạn" |
| **Milestones** | Celebration animation khi đạt 25%, 50%, 75%, 100% |
| **Tier** | 🆓 Free: 2 goals · 💎 Premium: unlimited + auto-contribute |

### F2.5 — Auto-Categorization (Core ML)

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Cơ chế** | On-device Core ML, học từ lịch sử cá nhân |
| **Input** | Ghi chú, số tiền, thời gian, tần suất |
| **Output** | Top 3 categories + confidence |
| **Learning** | User chọn khác → model update locally |
| **Accuracy** | 70% @50 giao dịch, 85% @200 giao dịch |
| **Privacy** | 100% on-device |
| **Tier** | 🆓 Free |

### F2.6 — Smart Transaction Suggestion

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Gợi ý giao dịch dựa trên pattern |
| **Ví dụ** | "Thường mua café sáng thứ Hai. Nhập 35K Café?" |
| **Cơ chế** | Pattern matching: thời gian + category + số tiền tương tự |
| **UX** | Notification hoặc card, 1-tap confirm |
| **Tier** | 💎 Premium |

### F2.7 — Bill Reminders

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Tạo** | Tên, số tiền, ngày đến hạn, tần suất |
| **Default VN** | Tiền điện, nước, Internet, tiền nhà |
| **Thông báo** | Push: 3 ngày, 1 ngày trước, ngày đến hạn |
| **Đánh dấu** | "Đã thanh toán" → auto tạo expense |
| **Calendar** | Xem bills trên calendar view |
| **Tier** | 🆓 Free: 5 bills · 💎 Premium: unlimited |

### F2.8 — Apple Watch App

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Complication** | Chi tiêu hôm nay hoặc số dư |
| **Quick input** | Nhập nhanh số tiền + category phổ biến |
| **Glance** | Tổng chi hôm nay, budget remaining |
| **Tier** | 💎 Premium |

### F2.9 — Siri Shortcuts & App Intents

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Intents** | "Ghi chi tiêu X cho Y", "Hôm nay chi bao nhiêu?", "Budget ăn uống còn bao nhiêu?" |
| **Shortcuts** | Workflow tùy chỉnh (VD: sáng → dashboard summary) |
| **Tier** | 🆓 Free (basic) · 💎 Premium (custom) |

---

## Technical Tasks

- [ ] Budget data model + CRUD
- [ ] Budget progress tracking + alerts
- [ ] Envelope budgeting UI
- [ ] RecurringRule engine + auto-create transactions
- [ ] Subscription tracking view
- [ ] Goal data model + progress tracking
- [ ] Core ML auto-categorization model
- [ ] Pattern detection for smart suggestions
- [ ] Bill reminders + notification scheduling
- [ ] watchOS app (SwiftUI)
- [ ] App Intents + Siri integration
- [ ] Calendar view component
- [ ] Push notification infrastructure
