---
description: "Triển khai toàn bộ AI pipeline — On-device Core ML models + Cloud Claude API integration"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# AI Pipeline

Triển khai AI architecture hybrid theo FinanceApp-Feature-Specification.md phần "AI Architecture".

## Đọc Context
1. `FinanceApp-Feature-Specification.md` → Phần 9: AI Architecture + F2.5, F2.6, F3.1-F3.4
2. Apple Core ML / Create ML documentation
3. Anthropic Claude API documentation

## Layer 1: On-Device AI (Core ML)

### 1.1 Transaction Categorizer
```
Framework: Create ML Text Classifier
Input:    transaction note + amount + time_of_day + day_of_week
Output:   top 3 categories + confidence scores
Training: Pre-trained VN spending data → shipped with app
Updating: On-device fine-tuning từ user corrections
Size:     < 5MB model
Latency:  < 50ms inference
```

**Training Data Preparation:**
```
Tạo dataset VN transactions (1000+ examples):
- "grab đi làm"           → Di chuyển/Grab
- "highland coffee"        → Ăn uống/Café
- "shopee đồ điện tử"     → Mua sắm/Điện tử
- "tiền nhà tháng 3"      → Nhà ở/Tiền thuê
- "phở bò"                → Ăn uống/Ăn ngoài
- "xăng xe"               → Di chuyển/Xăng
- "gửi xe máy"            → Di chuyển/Gửi xe
- "netflix"               → Giải trí/Subscription
- "gym california"        → Sức khỏe/Gym
- "biếu ba mẹ"            → Gia đình/Biếu bố mẹ
- "học phí tiếng anh"     → Giáo dục/Khóa học
- "bảo hiểm xe"           → Tài chính/Bảo hiểm
```

**On-device Learning Pipeline:**
```swift
// 1. User nhập transaction → model predict category
// 2. User accepts hoặc corrects → store feedback
// 3. After N corrections → retrain model on-device
// 4. New model replaces old → better predictions
// 5. Old training data: keep 90 days rolling window
```

### 1.2 Receipt OCR
```
Framework: Vision (VNRecognizeTextRequest) + Core ML
Pipeline:
  1. Camera → UIImage
  2. VNRecognizeTextRequest → raw text blocks with bounding boxes
  3. Core ML classifier → categorize text blocks (amount, date, merchant, item)
  4. Post-processing → structured ReceiptData

VN-Specific Parsing:
  - Amount patterns: "1.000.000", "1,000,000", "150k", "1.5tr", "Tổng: 385.000đ"
  - Date patterns: "12/02/2026", "12-02-2026", "Ngày 12 tháng 2"
  - VAT detection: "Thuế GTGT", "VAT 10%"
  - Merchant: typically first line or after "Cửa hàng:", "Đơn vị:"
```

### 1.3 Pattern Detection
```
Framework: Foundation (statistical) — no ML needed
Algorithms:
  - Time-of-day clustering: group transactions by hour → detect habits
  - Day-of-week analysis: weekly spending patterns
  - Amount frequency: detect recurring same-amount transactions
  - Anomaly: z-score on category monthly totals (> 1.5σ = anomaly)
  - Trend: simple moving average on monthly category totals
```

### 1.4 Cash Flow Forecasting
```
Framework: Create ML TabularRegressor
Input features:
  - Day of month
  - Day of week
  - Month (seasonality)
  - Known upcoming recurring transactions
  - Historical daily income/expense averages
  - Rolling 7/14/30 day averages
Output: predicted daily balance for next 30/60/90 days
Training: per-user, on-device, retrain weekly
Min data: 60 days of history before enabling predictions
```

## Layer 2: Cloud AI (Claude API — Premium only)

### 2.1 AI Financial Assistant
```
API:     Claude Sonnet (via Anthropic API)
System:  Financial advisor persona, Vietnamese/English bilingual
Context: Injected aggregated user data (NOT individual transactions)

System Prompt Template:
---
Bạn là trợ lý tài chính cá nhân thông minh trong app FinanceApp.
Ngôn ngữ: {user_language}
Đồng tiền chính: {primary_currency}

CONTEXT TÀI CHÍNH NGƯỜI DÙNG:
- Thu nhập tháng này: {monthly_income}
- Chi tiêu tháng này: {monthly_expense}
- Chi tiêu theo danh mục: {category_breakdown}
- So sánh vs tháng trước: {month_comparison}
- Budget status: {budget_status}
- Goals progress: {goals_status}
- Recurring upcoming: {upcoming_bills}
- Dự đoán cuối tháng: {forecast_eom_balance}

RULES:
- KHÔNG đưa lời khuyên đầu tư cụ thể (cổ phiếu, crypto, etc.)
- KHÔNG claim là chuyên gia tài chính
- Trả lời ngắn gọn, actionable
- Sử dụng format tiền tệ đúng ({currency_format})
- Nếu không chắc → nói rõ và khuyên tham khảo chuyên gia
---

Privacy Layer:
- Chỉ gửi aggregated numbers, KHÔNG gửi:
  * Tên cửa hàng/merchant
  * Ghi chú giao dịch
  * Tên tài khoản cụ thể
  * Thông tin cá nhân
- User opt-in required trước khi dùng cloud AI
- Option "Xóa lịch sử chat" bất cứ lúc nào
```

### 2.2 Natural Language Insights Generator
```
API:     Claude Haiku (cheaper, faster)
Input:   Aggregated weekly/monthly spending data
Output:  3-5 insights bằng ngôn ngữ tự nhiên

Prompt Template:
---
Dựa trên dữ liệu chi tiêu tuần này, hãy tạo 3-5 insights hữu ích:

Data: {weekly_summary_json}

Format mỗi insight:
- Type: [anomaly|savings|pattern|achievement|warning]
- Icon suggestion: [SF Symbol name]
- Title: [Ngắn gọn, < 10 từ]
- Body: [1-2 câu, actionable]
- Severity: [info|attention|urgent]
---
```

### 2.3 Advanced Receipt Processing (Fallback)
```
API:     Claude Sonnet with Vision
Input:   Receipt image (base64)
Trigger: Khi on-device OCR confidence < 70%
Output:  Structured receipt data JSON
Note:    User opt-in, image KHÔNG lưu trên server
```

## Privacy Architecture
```
┌──────────────────────────────────────────────┐
│                 USER DEVICE                   │
│                                               │
│  Raw Transactions ──→ NEVER leaves device     │
│  Receipt Images ──→ On-device first           │
│  User Corrections ──→ On-device learning      │
│                                               │
│  ┌─────────────────────────────────────────┐ │
│  │         PRIVACY GATE                     │ │
│  │  Aggregation + Anonymization             │ │
│  │  Remove PII, merchant names, notes       │ │
│  │  Only send: category totals, ratios,     │ │
│  │  trends, budget percentages              │ │
│  └────────────────┬────────────────────────┘ │
│                   │ (Premium + User Opt-in)   │
└───────────────────┼──────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────┐
│              CLOUD AI (Anthropic)              │
│  - No data stored after response              │
│  - No training on user data                   │
│  - Encrypted in transit (TLS 1.3)             │
└──────────────────────────────────────────────┘
```

## API Cost Management
```
Per-user estimated monthly costs (Premium):
- AI Assistant: ~20 queries × $0.005 = $0.10
- Weekly insights: 4 × $0.002 = $0.008
- Monthly report: 1 × $0.01 = $0.01
- Receipt fallback: ~5 × $0.008 = $0.04
- Total: ~$0.16/user/month

At 1000 Premium users: ~$160/month
At 10000 Premium users: ~$1600/month

Optimization:
- Cache common insight patterns
- Batch insight generation (nightly)
- Use Haiku for simple queries, Sonnet for complex
- Rate limiting per user per feature
```

## Testing
- Categorizer accuracy benchmark (labeled VN dataset)
- Receipt OCR accuracy (VN receipt photos dataset)
- Cash flow prediction accuracy vs actual (backtest)
- Cloud AI response quality evaluation
- Privacy audit: verify no PII leaves device
- Cost monitoring: per-request cost tracking
- Latency: on-device < 100ms, cloud < 3s
- Offline: all on-device features work without internet
