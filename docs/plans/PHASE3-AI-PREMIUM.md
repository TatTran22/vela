# Phase 3 — AI & Premium (Tháng 7-10)

> **Mục tiêu**: AI trở thành core differentiator. Cloud AI cho insights
> nâng cao, receipt scanning, và financial assistant.

## Tổng Quan

| Metric | Target |
|--------|--------|
| Tổng features mới | 8 features |
| AI features | 4 (receipt scan, insights, assistant, forecasting) |
| Timeline | Tháng 7-10 |
| Goal | 15,000 users, 8% paying subscribers |
| Validation | Premium conversion rate, AI engagement rate |

---

## Features

### F3.1 — Receipt Scanning (OCR + AI)

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Cơ chế** | Vision framework (on-device OCR) + Core ML structured extraction |
| **Trích xuất** | Tổng tiền, ngày, tên cửa hàng, items |
| **VN support** | Format VND, hóa đơn VAT VN, bill nhà hàng, hóa đơn điện/nước |
| **Flow** | Chụp → preview extraction → confirm/edit → save |
| **Cloud fallback** | Nếu on-device < 70% accuracy → cloud AI (opt-in) |
| **Tier** | 🆓 Free: 5 scans/tháng · 💎 Premium: unlimited |

### F3.2 — AI Financial Insights

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Types** | Spending anomalies, savings opportunities, pattern detection, subscription alerts, comparative analysis |
| **Delivery** | Weekly digest (push + in-app), Monthly report |
| **On-device** | Pattern detection, anomaly flagging |
| **Cloud** | Natural language insights, comparative (Claude Haiku) |
| **Tier** | 🆓 Free: 1 insight/tuần · 💎 Premium: full weekly + monthly |

### F3.3 — AI Financial Assistant (Chat)

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Ví dụ** | "Tháng này chi bao nhiêu ăn uống?", "Đủ tiền mua iPhone không?", "Nên cắt giảm ở đâu?" |
| **Cơ chế** | Claude Sonnet API, context = aggregated data only |
| **Privacy** | Chỉ gửi tổng theo category, KHÔNG gửi từng giao dịch |
| **Ngôn ngữ** | Tiếng Việt + English |
| **Giới hạn** | Không lời khuyên đầu tư cụ thể, disclaimer rõ ràng |
| **Tier** | 💎 Premium: 20 câu/tháng · 💎💎 Family: 40 câu/tháng |

### F3.4 — Predictive Cash Flow

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Dự đoán** | Số dư cuối tháng, 3 tháng tới, ngày "hết tiền" |
| **Input** | Recurring transactions, spending patterns, seasonal trends |
| **Visualization** | Line chart: quá khứ (thực) → tương lai (dự đoán + confidence interval) |
| **Alert** | "Dựa trên chi tiêu hiện tại, vượt ngân sách ngày 22" |
| **Cơ chế** | Create ML time series, on-device |
| **Tier** | 💎 Premium |

### F3.5 — Debt Tracking

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Thông tin** | Gốc, lãi suất, kỳ hạn, payment schedule |
| **Chiến lược** | Snowball (nhỏ trước), Avalanche (lãi cao trước), tùy chỉnh |
| **Tính toán** | Tổng lãi, ngày hết nợ, tiết kiệm nếu trả thêm |
| **VN** | Lãi suất thả nổi, tính lãi giảm dần |
| **Tier** | 💎 Premium |

### F3.6 — Cho Vay/Mượn Cá Nhân

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Thông tin** | Ai, bao nhiêu, ngày vay, deadline, ghi chú |
| **Nhắc nhở** | Nhắc đòi tiền hoặc trả tiền |
| **VN context** | Rất phổ biến — cho bạn mượn, biếu rồi trả lại |
| **Tier** | 🆓 Free: 3 records · 💎 Premium: unlimited |

### F3.7 — Custom Reports

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Loại** | Income vs Expense, Category breakdown, Trend, Net worth, Cash flow, Tax summary |
| **Export** | PDF đẹp, CSV raw, share image |
| **Schedule** | Auto gửi email hàng tuần/tháng |
| **Tier** | 💎 Premium |

### F3.8 — Net Worth Tracker

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Assets** | Tiền mặt, ngân hàng, đầu tư, BĐS (thủ công), vàng, crypto |
| **Liabilities** | Nợ vay, thẻ tín dụng, nợ cá nhân |
| **VN** | Giá vàng SJC auto-update, giá đất/nhà ước tính |
| **Visualization** | Stacked area chart: tài sản vs nợ theo thời gian |
| **Tier** | 💎 Premium |

---

## Technical Tasks

- [ ] Vision framework OCR integration
- [ ] Core ML receipt extraction model (VN-trained)
- [ ] Cloud AI backend proxy (relay to Claude API)
- [ ] AI chat interface + conversation management
- [ ] Insights generation pipeline (on-device + cloud)
- [ ] Cash flow forecasting (Create ML time series)
- [ ] Debt data model + payoff calculators
- [ ] Personal lending tracker
- [ ] Custom report builder + PDF generation
- [ ] Net worth tracking UI + asset management
- [ ] Privacy controls for cloud AI (opt-in/out)
- [ ] Premium subscription (StoreKit 2)
