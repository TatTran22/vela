---
description: "Triển khai Phase 3 — Receipt Scanning, AI Insights, AI Assistant, Predictive Cash Flow, Debt Tracking, Net Worth, Custom Reports."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Phase 3 — AI & Premium Implementation

Triển khai Phase 3 theo FinanceApp-Feature-Specification.md.

## Đọc Context
1. `CLAUDE.md`
2. `FinanceApp-Feature-Specification.md` → Phần "Phase 3 — AI & Premium" + "AI Architecture"
3. Scan existing AI code từ Phase 2 (Core ML categorizer)

## Thứ Tự Triển Khai

### Sprint 10: Receipt Scanning (Tuần 25-27)
Spawn **shared-core** agent:
1. **F3.1 Receipt Scanner Architecture**
   - ReceiptData model: totalAmount, date, merchantName, items[], currency
   - ReceiptScannerProtocol
   - ReceiptToTransactionMapper

Spawn subagent cho AI/Vision:
2. **On-device OCR Pipeline (Vision framework)**
   - VNRecognizeTextRequest cho text extraction
   - Vietnamese text recognition optimization
   - VND amount parsing: handle "1.000.000", "1,000,000", "1000000", "150k", "1.5tr"
   - Date parsing: DD/MM/YYYY (VN format), multiple formats
   - Merchant name extraction heuristics

3. **Structured Data Extraction (Core ML)**
   - Train/use model để extract fields từ raw OCR text
   - Handle hóa đơn VAT VN format
   - Handle receipt POS format
   - Handle bill nhà hàng format

4. **Cloud Fallback Pipeline**
   - Khi on-device confidence < 70% → gửi image lên cloud
   - Claude Vision API integration (premium only)
   - Privacy: user opt-in, image không lưu trên server

Spawn **ios-engineer** agent:
5. **Camera Capture UI** — Custom camera overlay với receipt guide frame
6. **Processing Screen** — "Đang phân tích hóa đơn..." animation
7. **Extracted Data Preview** — Editable fields (amount, date, merchant, category)
8. **Receipt Gallery** — Xem lại receipts đã scan, link với transactions
9. **Photo Library Import** — Chọn ảnh từ Photos app

Spawn **macos-engineer** agent:
10. macOS receipt import (drag & drop image, paste from clipboard)

### Sprint 11: AI Insights & Forecasting (Tuần 28-30)
Spawn **shared-core** agent:
11. **F3.2 AI Financial Insights Engine**
    - InsightType enum: spending_anomaly, savings_opportunity, pattern, subscription_alert, comparative
    - On-device insights (rule-based + statistical):
      * Spending anomaly: category spend > 1.5x average → flag
      * Savings opportunity: high-frequency small spends → calculate annual total
      * Pattern detection: time-of-day, day-of-week spending patterns
      * Subscription detection: same amount + monthly frequency → flag
    - Cloud AI insights (premium):
      * Natural language insight generation (Claude Haiku API)
      * Input: aggregated category totals, trends, ratios
      * Output: personalized Vietnamese/English insight text
      * Weekly digest + Monthly report generation

12. **F3.4 Predictive Cash Flow**
    - Time series forecasting model (Create ML TabularRegressor)
    - Input features: historical daily balances, recurring patterns, seasonal trends
    - Output: predicted balance for next 30/60/90 days
    - Confidence intervals
    - "Danger day" detection: ngày dự kiến số dư xuống dưới threshold
    - Trigger training: weekly retrain on-device

Spawn **ios-engineer** agent:
13. **Insights Feed** — Card-based insights on dashboard
14. **Weekly Digest View** — Summary of week's insights
15. **Monthly Report View** — Comprehensive monthly review (PDF exportable)
16. **Cash Flow Chart** — Historical (solid line) + Predicted (dashed + confidence band)
17. **Push Notifications** — Insight alerts, weekly digest reminder

### Sprint 12: AI Financial Assistant (Tuần 31-33)
Spawn subagent cho AI Chat:
18. **F3.3 AI Assistant Backend**
    - ChatMessage model: role, content, timestamp
    - ConversationManager: manage chat history
    - Claude Sonnet API integration
    - System prompt engineering:
      * Role: Vietnamese financial advisor (không phải investment advisor)
      * Context injection: user's aggregated financial data
      * Safety: disclaimer về không phải lời khuyên đầu tư
      * Language: auto-detect Vietnamese/English
    - Privacy layer: chỉ gửi aggregated data (category totals, ratios), KHÔNG gửi individual transactions
    - Rate limiting: 20 questions/month (Premium), unlimited (Premium+)
    - Response caching cho common questions

Spawn **ios-engineer** agent:
19. **Chat UI** — Bubble-style chat interface
20. **Quick Questions** — Suggested questions chips
    - "Tháng này tôi chi bao nhiêu cho ăn uống?"
    - "So sánh chi tiêu tháng này vs tháng trước"
    - "Tôi có thể tiết kiệm thêm ở đâu?"
    - "Dự kiến cuối tháng còn bao nhiêu?"
21. **Context Cards** — In-chat charts/data cards khi assistant trả lời

Spawn **macos-engineer** agent:
22. macOS chat panel (sidebar hoặc floating window)

### Sprint 13: Debt & Net Worth (Tuần 34-36)
Spawn **shared-core** agent:
23. **F3.5 Debt Tracking**
    - Debt model: principal, remainingAmount, interestRate, term, paymentSchedule
    - DebtType: mortgage, credit_card, personal_loan, student_loan, other
    - PayoffStrategy enum: snowball (nhỏ trước), avalanche (lãi cao trước), custom
    - CalculatePayoffPlanUseCase
    - CalculateInterestSavingsUseCase (nếu trả thêm X/tháng)
    - VN-specific: lãi suất thả nổi, lãi giảm dần

24. **F3.6 Lend/Borrow (Cho vay/Mượn)**
    - LendBorrow model: personName, amount, type (lent/borrowed), dueDate
    - Reminders: nhắc đòi tiền / nhắc trả tiền

25. **F3.8 Net Worth Tracker**
    - Asset tracking: tài khoản + manual entries (bất động sản, vàng, crypto)
    - VN-specific: Vàng SJC (auto-update giá), giá trị đất/nhà
    - Liability tracking: debts + credit card balances
    - Net Worth = Assets - Liabilities
    - Historical tracking: snapshot monthly

26. **F3.7 Custom Reports**
    - ReportType: income_expense, category_breakdown, trend, net_worth, cash_flow, tax_summary
    - ReportPeriod: custom date range
    - Export: PDF (formatted), CSV (raw data)
    - Share: image for social
    - Scheduled reports: email weekly/monthly

Spawn **ios-engineer** + **macos-engineer** agents:
27. Debt dashboard, payoff progress, strategy comparison
28. Lend/Borrow list với contact integration
29. Net Worth dashboard với stacked area chart
30. Report builder UI (select type, period, export)

Spawn **test-engineer** agent:
31. Receipt OCR accuracy tests (VN receipts dataset)
32. AI insights relevance tests
33. Cash flow prediction accuracy tests
34. Debt calculation accuracy (compound interest)
35. Net worth calculation tests

## Definition of Done — Phase 3
- [ ] Receipt scanning VN receipts > 80% accuracy
- [ ] AI insights generating relevant weekly digests
- [ ] AI assistant answering questions accurately
- [ ] Cash flow predictions within 10% accuracy
- [ ] Debt payoff calculations verified correct
- [ ] Net worth tracking with VN-specific assets
- [ ] All premium features gated properly
- [ ] Cloud AI requests respect privacy guidelines
