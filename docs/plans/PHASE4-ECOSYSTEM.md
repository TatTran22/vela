# Phase 4 — Ecosystem & Scale (Tháng 11-14)

> **Mục tiêu**: Social features, advanced automation, bank integration path,
> và mở rộng ecosystem.

## Tổng Quan

| Metric | Target |
|--------|--------|
| Tổng features mới | 10 features |
| Timeline | Tháng 11-14 |
| Goal | 50,000 users, 12% paying, 4.7★ App Store |
| Validation | Shared wallet adoption, freelancer segment growth |

---

## Features

### F4.1 — Shared Wallets (Gia Đình/Cặp Đôi)

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mời** | Qua Apple ID / link mời |
| **Cấu trúc** | Tài khoản riêng (chỉ mình thấy) + Tài khoản chung (cả 2 thấy) |
| **Tính năng** | Budget chung, giao dịch tagged "ai chi", báo cáo cá nhân vs chung |
| **Permissions** | Owner (full), Member (add + view), Viewer (xem only) |
| **Privacy** | Tài khoản riêng luôn private |
| **Tier** | 💎 Premium: 1 partner · 💎💎 Family: 5 người |

### F4.2 — Split Bills

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Flow** | Nhập tổng → chọn người → chia đều hoặc custom |
| **Tracking** | Ai nợ ai, settle up |
| **Integration** | Suggest banking/MoMo transfer link |
| **VN** | "Đi nhậu" culture — chia tiền rất phổ biến |
| **Tier** | 🆓 Free: basic · 💎 Premium: groups, history, settle tracking |

### F4.3 — Smart Rules Engine

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Ví dụ** | IF "Grab" → category Di chuyển; IF > 5tr → tag "Chi lớn" + alert |
| **Builder** | Visual rule builder (WHEN → IF → THEN) |
| **Tier** | 💎 Premium |

### F4.4 — Bank Statement Import

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Format** | CSV, Excel, PDF (OCR) |
| **VN Banks** | Vietcombank, Techcombank, BIDV, VPBank, MBBank, ACB, TPBank |
| **Duplicate** | AI detect giao dịch trùng |
| **Mapping** | Auto-map columns, user confirm lần đầu |
| **Tier** | 💎 Premium |

### F4.5 — Auto-Savings Rules

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Rules** | Round-up (làm tròn lên → dư vào savings), Fixed (X/ngày), Percentage (% income → goal), Challenge (52-week...) |
| **Lưu ý** | Tracking/allocation only, không chuyển tiền thật |
| **Tier** | 💎 Premium |

### F4.6 — Income by Client/Project

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Tạo** | Client profile + Project (tên, client, budget) |
| **Tracking** | Thu nhập mỗi client/project, pending invoices |
| **Report** | Top clients, project profitability |
| **Thuế** | Ước tính thuế TNCN (freelancer VN: 2% doanh thu < 100tr/năm) |
| **Tier** | 💎 Premium |

### F4.7 — Business vs Personal Separation

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Cơ chế** | Tag-based: "personal" / "business" |
| **Report** | Báo cáo riêng mỗi context |
| **Tax** | Export chi phí business cho kê khai thuế |
| **Tier** | 💎 Premium |

### F4.8 — macOS Full Experience

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Exclusive** | Keyboard shortcuts, table view sort/filter, multi-window, drag & drop import, menu bar quick-entry, Touch Bar |
| **Tier** | Cùng subscription (1 sub = cả 2 platforms) |

### F4.9 — iPadOS Optimization

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Features** | Split view, Pencil annotate receipts, keyboard shortcuts, Stage Manager |
| **Tier** | Cùng subscription |

### F4.10 — Data Import from Other Apps

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Hỗ trợ** | Money Lover, Monefy, Spendee, YNAB, Mint, MoneyWiz (CSV) |
| **Flow** | Upload → detect source → auto-map → preview → import |
| **Tier** | 🆓 Free |

---

## Technical Tasks

- [ ] CloudKit shared database cho shared wallets
- [ ] Invitation system (Apple ID / link)
- [ ] Permission & role management
- [ ] Split bill calculator + settle tracking
- [ ] Smart rules engine + visual builder
- [ ] Bank statement parser (VN bank templates)
- [ ] PDF OCR for bank statements
- [ ] Duplicate transaction detection
- [ ] Auto-savings allocation engine
- [ ] Freelancer: Client/Project data model
- [ ] Tax estimation calculator (VN rules)
- [ ] macOS advanced features (menu bar widget, multi-window)
- [ ] iPadOS adaptive layout + Pencil support
- [ ] Import parsers for major finance apps
