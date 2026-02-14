# FinanceApp — Feature Specification Document
## Ứng Dụng Quản Lý Tài Chính Cá Nhân · macOS & iOS

---

## Mục Lục

1. [Tầm Nhìn Sản Phẩm](#1-tầm-nhìn-sản-phẩm)
2. [Phân Tích Đối Tượng Người Dùng](#2-phân-tích-đối-tượng-người-dùng)
3. [Feature Map Tổng Quan](#3-feature-map-tổng-quan)
4. [Phase 1 — MVP (Tháng 1-3)](#4-phase-1--mvp-tháng-1-3)
5. [Phase 2 — Core Growth (Tháng 4-6)](#5-phase-2--core-growth-tháng-4-6)
6. [Phase 3 — AI & Premium (Tháng 7-10)](#6-phase-3--ai--premium-tháng-7-10)
7. [Phase 4 — Ecosystem & Scale (Tháng 11-14)](#7-phase-4--ecosystem--scale-tháng-11-14)
8. [Mô Hình Freemium Chi Tiết](#8-mô-hình-freemium-chi-tiết)
9. [AI Architecture — Hybrid Strategy](#9-ai-architecture--hybrid-strategy)
10. [Data Model Overview](#10-data-model-overview)
11. [UX Flow Chính](#11-ux-flow-chính)
12. [Phân Tích Cạnh Tranh & Khác Biệt](#12-phân-tích-cạnh-tranh--khác-biệt)
13. [Technical Considerations](#13-technical-considerations)
14. [KPIs & Success Metrics](#14-kpis--success-metrics)

---

## 1. Tầm Nhìn Sản Phẩm

### One-liner
> Ứng dụng quản lý tài chính cá nhân native Apple, AI-powered, offline-first,
> phục vụ người Việt Nam và cộng đồng đa quốc gia với trải nghiệm vượt trội
> mà không app nào trên thị trường đang cung cấp.

### Giá Trị Cốt Lõi

| Trụ cột | Mô tả |
|---------|-------|
| **Privacy-first** | Dữ liệu tài chính được mã hóa, xử lý AI trên thiết bị khi có thể, không bán data |
| **Apple-native** | Tận dụng toàn bộ ecosystem: iCloud sync, Widgets, Shortcuts, Apple Watch, Handoff |
| **Vietnam-ready** | VND formatting, ngân hàng VN, thói quen tài chính người Việt (tiền mặt, vàng, đất) |
| **Globally capable** | Multi-currency, đa ngôn ngữ, phục vụ expat và diaspora Việt Nam |
| **Intelligently simple** | AI làm nặng phía sau, người dùng thấy đơn giản phía trước |

### Thị Trường Mục Tiêu Ban Đầu
- **Primary**: Người Việt sử dụng iPhone/Mac, 25-45 tuổi, thu nhập trung bình-cao
- **Secondary**: Expat tại Việt Nam, Việt kiều, digital nomad tại VN
- **Tertiary**: Freelancer/solopreneur cần tách biệt chi tiêu cá nhân vs công việc

---

## 2. Phân Tích Đối Tượng Người Dùng

### Persona 1: Minh — Nhân viên văn phòng (Primary)
- **Tuổi**: 28, sống tại TP.HCM
- **Thu nhập**: 25-40 triệu VND/tháng
- **Pain points**: Chi tiêu không kiểm soát, không biết tiền đi đâu cuối tháng, muốn tiết kiệm mua nhà
- **Hành vi**: Dùng iPhone + MacBook, thanh toán qua MoMo/ZaloPay + tiền mặt, lương chuyển khoản ngân hàng
- **Kỳ vọng**: Nhập nhanh, tự động phân loại, nhìn tổng quan tài chính trong 5 giây
- **Sẵn sàng trả**: 49-99K VND/tháng nếu app thực sự hữu ích

### Persona 2: Sarah — Expat (Secondary)
- **Tuổi**: 34, người Mỹ sống tại Hà Nội
- **Thu nhập**: $3,000 USD + side projects (VND + USD)
- **Pain points**: Quản lý 2 đồng tiền, gửi tiền về Mỹ, không hiểu hệ thống tài chính VN
- **Hành vi**: Dùng full Apple ecosystem, có tài khoản tại Techcombank + Chase
- **Kỳ vọng**: Multi-currency tự động quy đổi, báo cáo theo cả VND và USD
- **Sẵn sàng trả**: $5-10/month

### Persona 3: Lan & Tuấn — Vợ chồng trẻ (Secondary)
- **Tuổi**: 30-33, TP.HCM
- **Thu nhập gộp**: 60-80 triệu VND/tháng
- **Pain points**: Ai chi gì không rõ, tranh cãi về tiền, chưa có kế hoạch tài chính chung
- **Hành vi**: Cả hai dùng iPhone, Tuấn có Mac
- **Kỳ vọng**: Shared wallet, mỗi người vẫn có chi tiêu riêng, budget chung cho gia đình
- **Sẵn sàng trả**: 99-149K VND/tháng cho cả 2

### Persona 4: Hùng — Freelance Designer (Tertiary)
- **Tuổi**: 27, Đà Nẵng
- **Thu nhập**: 15-60 triệu VND/tháng (không đều)
- **Pain points**: Thu nhập biến động, khó budget, cần tách chi tiêu cá nhân vs dự án
- **Hành vi**: MacBook Pro là công cụ chính, nhận payment qua nhiều kênh
- **Kỳ vọng**: Theo dõi income theo project/client, dự đoán cash flow
- **Sẵn sàng trả**: 79-99K VND/tháng

---

## 3. Feature Map Tổng Quan

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FINANCEAPP FEATURE MAP                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │   TRACKING   │  │   PLANNING   │  │  INSIGHTS    │             │
│  ├──────────────┤  ├──────────────┤  ├──────────────┤             │
│  │ Transactions │  │ Budgets      │  │ AI Reports   │             │
│  │ Accounts     │  │ Goals        │  │ Trends       │             │
│  │ Categories   │  │ Bills        │  │ Forecasting  │             │
│  │ Receipt Scan │  │ Recurring    │  │ Net Worth    │             │
│  │ Multi-curr.  │  │ Debt Payoff  │  │ AI Assistant │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │   SOCIAL     │  │  PLATFORM    │  │  AUTOMATION  │             │
│  ├──────────────┤  ├──────────────┤  ├──────────────┤             │
│  │ Shared Wallet│  │ iOS App      │  │ Auto-categorize│           │
│  │ Split Bills  │  │ macOS App    │  │ Smart Rules  │             │
│  │ Family View  │  │ Widgets      │  │ Reminders    │             │
│  │ Permissions  │  │ Watch App    │  │ Auto-savings │             │
│  │              │  │ Shortcuts    │  │ Bank Import  │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 4. Phase 1 — MVP (Tháng 1-3)

> **Mục tiêu**: App hoạt động được, giải quyết bài toán cơ bản nhất — 
> "Tiền tôi đi đâu?" Tập trung iOS trước, macOS companion.

### 4.1 Quản Lý Tài Khoản (Accounts)

#### F1.1 — Tạo & quản lý tài khoản
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Người dùng tạo các tài khoản đại diện cho nơi giữ tiền thực tế |
| **Loại tài khoản** | Tiền mặt, Ngân hàng (checking/savings), Thẻ tín dụng, Ví điện tử (MoMo, ZaloPay, VNPay), Tiết kiệm |
| **Thuộc tính** | Tên, loại, số dư ban đầu, đồng tiền (mặc định VND), icon/màu, ghi chú |
| **Tính năng** | Sắp xếp thứ tự, ẩn/hiện, archive tài khoản cũ |
| **Hiển thị** | Tổng số dư tất cả tài khoản, group theo loại |
| **Tier** | 🆓 Free: 5 tài khoản · 💎 Premium: không giới hạn |

#### F1.2 — Multi-currency cơ bản
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Mỗi tài khoản có thể gắn một loại tiền tệ |
| **Hỗ trợ** | VND (mặc định), USD, EUR, JPY, KRW, THB, SGD, AUD, GBP, CNY + thêm theo nhu cầu |
| **Tỷ giá** | Tự động cập nhật hàng ngày (free), real-time (premium) |
| **Quy đổi** | Hiển thị song song: giá trị gốc + quy đổi về đồng tiền chính |
| **VND đặc thù** | Không hiện decimal (VND không có xu), format 1.000.000 ₫ |
| **Tier** | 🆓 Free: 1 đồng tiền · 💎 Premium: không giới hạn + real-time rate |

### 4.2 Giao Dịch (Transactions)

#### F1.3 — Nhập giao dịch thủ công
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Ghi nhận thu/chi/chuyển khoản nhanh nhất có thể |
| **Loại** | Thu nhập (Income), Chi tiêu (Expense), Chuyển khoản (Transfer) |
| **Trường bắt buộc** | Số tiền, tài khoản, danh mục |
| **Trường tùy chọn** | Ghi chú, ngày (mặc định hôm nay), ảnh/receipt, tags, địa điểm |
| **Quick Input** | Mở app → nhập số → chọn danh mục → Done (< 5 giây) |
| **Số tiền** | Bàn phím số tùy chỉnh với phép tính nhanh (VD: 150k + 200k) |
| **Lặp lại** | Đánh dấu "giao dịch lặp lại" → tạo recurring template |
| **Tier** | 🆓 Free |

#### F1.4 — Danh sách & tìm kiếm giao dịch
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Xem, tìm kiếm, lọc tất cả giao dịch |
| **Hiển thị** | Nhóm theo ngày, tổng thu/chi mỗi ngày |
| **Tìm kiếm** | Full-text search (ghi chú, danh mục, số tiền, tags) |
| **Bộ lọc** | Theo tài khoản, danh mục, khoảng thời gian, khoảng số tiền, tags |
| **Hành động** | Swipe-to-delete, edit, duplicate, thay đổi danh mục |
| **macOS** | Table view với columns có thể sort, multi-select, bulk edit |
| **Tier** | 🆓 Free |

#### F1.5 — Chuyển khoản giữa tài khoản (Transfer)
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Ghi nhận di chuyển tiền giữa các tài khoản của mình |
| **Logic** | Tạo 1 giao dịch duy nhất, tự động trừ tài khoản nguồn + cộng tài khoản đích |
| **Cross-currency** | Nếu 2 tài khoản khác đồng tiền → nhập cả 2 số tiền hoặc tỷ giá |
| **Lưu ý** | Transfer KHÔNG tính là thu nhập hay chi tiêu trong báo cáo |
| **Tier** | 🆓 Free |

### 4.3 Danh Mục (Categories)

#### F1.6 — Hệ thống danh mục
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Phân loại giao dịch để biết tiền đi đâu |
| **Cấu trúc** | 2 cấp: Category → Sub-category |
| **Mặc định (Expense)** | Ăn uống (Ăn ngoài, Đi chợ/nấu, Café/trà sữa), Nhà ở (Tiền thuê, Điện nước, Internet, Đồ gia dụng), Di chuyển (Xăng, Grab/taxi, Gửi xe, Bảo trì xe), Mua sắm (Quần áo, Điện tử, Gia dụng), Giải trí (Phim/show, Game, Du lịch, Sở thích), Sức khỏe (Khám bệnh, Thuốc, Gym, Bảo hiểm), Giáo dục (Khóa học, Sách, Học phí), Gia đình (Con cái, Biếu bố mẹ, Quà tặng), Tài chính (Trả nợ, Lãi vay, Phí ngân hàng, Bảo hiểm nhân thọ), Khác |
| **Mặc định (Income)** | Lương, Thưởng, Freelance, Đầu tư, Cho thuê, Quà/biếu, Hoàn tiền, Khác |
| **Tùy chỉnh** | Thêm/sửa/xóa category, chọn icon (SF Symbols), chọn màu |
| **Đặc thù VN** | "Biếu bố mẹ", "Café/trà sữa", "Grab/taxi", "Gửi xe" — phản ánh thói quen chi tiêu Việt Nam |
| **Tier** | 🆓 Free |

### 4.4 Dashboard

#### F1.7 — Tổng quan tài chính (Home Screen)
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Nhìn một cái biết tình hình tài chính |
| **Thành phần** | Tổng số dư (tất cả tài khoản), Thu nhập tháng này, Chi tiêu tháng này, Còn lại (thu - chi), Mini chart chi tiêu 7 ngày gần nhất, Giao dịch gần nhất (3-5 giao dịch) |
| **iOS layout** | Scroll vertical, card-based |
| **macOS layout** | Sidebar + main content, dense information |
| **Interaction** | Tap vào bất kỳ section → drill down chi tiết |
| **Tier** | 🆓 Free |

#### F1.8 — Báo cáo chi tiêu cơ bản
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Biểu đồ trực quan về chi tiêu |
| **Biểu đồ** | Pie chart theo danh mục, Bar chart thu/chi theo thời gian (tuần/tháng), Trend line chi tiêu 6 tháng |
| **Tương tác** | Tap vào slice → xem danh sách giao dịch thuộc category đó |
| **Kỳ báo cáo** | Tuần này, tháng này, tháng trước, tùy chỉnh khoảng thời gian |
| **Tier** | 🆓 Free: tháng hiện tại · 💎 Premium: lịch sử không giới hạn + export |

### 4.5 Nền Tảng & Đồng Bộ

#### F1.9 — iCloud Sync
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Đồng bộ dữ liệu giữa iPhone và Mac của cùng Apple ID |
| **Cơ chế** | CloudKit private database |
| **Conflict resolution** | Last-write-wins cho đơn giản, merge cho transactions |
| **Offline-first** | Hoạt động hoàn toàn offline, sync khi có mạng |
| **Trạng thái** | Hiển thị sync status (synced ✓, syncing ↻, offline ○) |
| **Tier** | 🆓 Free |

#### F1.10 — iOS Widget
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Xem nhanh thông tin tài chính trên Home Screen |
| **Small widget** | Tổng số dư hoặc chi tiêu hôm nay |
| **Medium widget** | Chi tiêu tuần này + mini chart |
| **Large widget** | Top categories + giao dịch gần nhất |
| **Interactive** | Tap widget → mở app đúng section |
| **Tier** | 🆓 Free |

### 4.6 Cài Đặt & Onboarding

#### F1.11 — Onboarding flow
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Bước 1** | Chọn đồng tiền chính (detect locale → suggest VND) |
| **Bước 2** | Tạo tài khoản đầu tiên (gợi ý: Ví tiền mặt + Tài khoản ngân hàng chính) |
| **Bước 3** | Nhập số dư hiện tại |
| **Bước 4** | Giới thiệu quick input (cho nhập 1 giao dịch thử) |
| **Bước 5** | Giới thiệu tính năng chính (carousel 3 slides) |
| **Nguyên tắc** | Xong onboarding trong < 2 phút, có thể skip mọi bước |

#### F1.12 — Settings
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Giao diện** | Dark/Light/System, App icon alternatives |
| **Đồng tiền** | Đồng tiền chính, format hiển thị |
| **Ngôn ngữ** | Tiếng Việt, English (app tự detect, cho đổi thủ công) |
| **Bảo mật** | Face ID/Touch ID lock, auto-lock timeout |
| **Data** | Export CSV/JSON, backup iCloud manual |
| **Ngày bắt đầu tháng** | Mặc định 1, cho phép chỉnh (VD: 25 nếu nhận lương ngày 25) |
| **Tier** | 🆓 Free |

### MVP Summary

| Metric | Target |
|--------|--------|
| **Tổng features** | 12 features cốt lõi |
| **Platforms** | iOS (primary) + macOS (companion) |
| **Timeline** | 3 tháng |
| **Goal** | 1,000 users, 50% D7 retention |
| **Validation** | Người dùng có quay lại nhập giao dịch mỗi ngày không? |

---

## 5. Phase 2 — Core Growth (Tháng 4-6)

> **Mục tiêu**: Biến tracking thành planning. Thêm budget, goals, 
> recurring, và on-device AI cơ bản.

### 5.1 Ngân Sách (Budgeting)

#### F2.1 — Budget theo danh mục
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Đặt giới hạn chi tiêu cho từng danh mục mỗi tháng |
| **Tạo budget** | Chọn category → nhập số tiền → chọn kỳ (tháng/tuần) |
| **Tracking** | Progress bar: đã chi / ngân sách, % đã dùng |
| **Alerts** | Thông báo khi đạt 80%, 100%, vượt ngân sách |
| **Rollover** | Premium: Tiền chưa chi tháng này → cộng vào tháng sau |
| **Hiển thị** | Tổng budget vs tổng đã chi, color-coded (xanh/vàng/đỏ) |
| **Smart suggest** | Gợi ý budget dựa trên trung bình chi tiêu 3 tháng trước |
| **Tier** | 🆓 Free: 3 budgets · 💎 Premium: không giới hạn + rollover + smart suggest |

#### F2.2 — Budget tổng (Envelope Method)
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Phân bổ thu nhập vào các "phong bì" chi tiêu (YNAB-style) |
| **Concept** | "Mỗi đồng đều có việc": Thu nhập → phân bổ vào categories → chi tiêu từ phong bì |
| **Flow** | Khi có thu nhập → app hỏi "Phân bổ vào đâu?" → kéo thả hoặc quick assign |
| **Ưu tiên** | Thiết yếu trước (nhà, ăn, xe) → Muốn có (giải trí, mua sắm) → Tiết kiệm/Đầu tư |
| **Tier** | 💎 Premium |

### 5.2 Giao Dịch Lặp Lại (Recurring)

#### F2.3 — Recurring transactions
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Tự động tạo giao dịch cho chi phí/thu nhập định kỳ |
| **Tần suất** | Hàng ngày, hàng tuần, 2 tuần, hàng tháng, hàng quý, hàng năm, tùy chỉnh |
| **Ví dụ** | Tiền thuê nhà (1/tháng), Lương (25/tháng), Netflix (hàng tháng), Bảo hiểm (hàng năm) |
| **Hành vi** | Tạo giao dịch tự động vào ngày hẹn, cho phép skip/edit trước khi confirm |
| **Nhắc nhở** | Push notification trước 1-3 ngày: "Tiền thuê nhà 8.000.000₫ sẽ đến hạn ngày 1/3" |
| **Calendar view** | Xem tất cả recurring trên lịch tháng |
| **Quản lý subscription** | Gom nhóm các recurring subscription → tổng chi phí subscription/tháng |
| **Tier** | 🆓 Free: 5 recurring · 💎 Premium: không giới hạn + subscription tracking |

### 5.3 Mục Tiêu Tài Chính (Goals)

#### F2.4 — Savings Goals
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Đặt mục tiêu tiết kiệm và theo dõi tiến độ |
| **Tạo goal** | Tên (VD: "Mua iPhone 16"), số tiền mục tiêu, ngày deadline, icon/ảnh |
| **Tracking** | Progress ring/bar, số tiền còn thiếu, dự kiến hoàn thành |
| **Đóng góp** | Thêm tiền vào goal thủ công hoặc tự động (link tài khoản tiết kiệm) |
| **Smart nudge** | "Bạn cần tiết kiệm 500.000₫/tuần để đạt mục tiêu đúng hạn" |
| **Milestones** | Celebration animation khi đạt 25%, 50%, 75%, 100% |
| **Tier** | 🆓 Free: 2 goals · 💎 Premium: không giới hạn + auto-contribute |

### 5.4 On-Device AI — Cơ Bản

#### F2.5 — Auto-categorization (Core ML)
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | AI tự động gợi ý danh mục cho giao dịch mới |
| **Cơ chế** | On-device Core ML model, học từ lịch sử giao dịch của người dùng |
| **Input** | Ghi chú giao dịch, số tiền, thời gian, tần suất |
| **Output** | Gợi ý top 3 categories với confidence score |
| **Learning** | Khi user chọn category khác → model update locally |
| **Accuracy target** | 70% sau 50 giao dịch, 85% sau 200 giao dịch |
| **Privacy** | 100% on-device, không gửi data lên server |
| **Tier** | 🆓 Free |

#### F2.6 — Smart transaction suggestion
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Gợi ý giao dịch dựa trên pattern |
| **Ví dụ** | "Bạn thường mua café vào sáng thứ Hai. Nhập giao dịch 35.000₫ Café?" |
| **Cơ chế** | Pattern matching: cùng thời gian + cùng category + số tiền tương tự |
| **UX** | Notification hoặc card trên dashboard, 1-tap confirm |
| **Tier** | 💎 Premium |

### 5.5 Hóa Đơn & Nhắc Nhở

#### F2.7 — Bill reminders
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Nhắc nhở thanh toán hóa đơn |
| **Tạo bill** | Tên, số tiền (cố định/ước lượng), ngày đến hạn, tần suất |
| **Mặc định VN** | Tiền điện (cuối tháng), Tiền nước (cuối tháng), Internet (đầu tháng), Tiền nhà (đầu tháng) |
| **Thông báo** | Push notification: 3 ngày trước, 1 ngày trước, ngày đến hạn |
| **Đánh dấu** | "Đã thanh toán" → tự động tạo giao dịch expense |
| **Calendar** | Xem tất cả bills trên calendar view |
| **Tier** | 🆓 Free: 5 bills · 💎 Premium: không giới hạn |

### 5.6 Apple Ecosystem Integration

#### F2.8 — Apple Watch App
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Quick input và glance trên Watch |
| **Complication** | Hiển thị chi tiêu hôm nay hoặc số dư |
| **Quick input** | Nhập nhanh số tiền + chọn category phổ biến |
| **Glance** | Tổng chi tiêu hôm nay, budget remaining |
| **Tier** | 💎 Premium |

#### F2.9 — Siri Shortcuts & App Intents
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Điều khiển bằng giọng nói và Shortcuts |
| **Intents** | "Ghi chi tiêu [số tiền] cho [danh mục]", "Hôm nay chi bao nhiêu?", "Còn bao nhiêu budget ăn uống?" |
| **Shortcuts** | Tạo workflow tùy chỉnh (VD: mỗi sáng → show dashboard summary) |
| **Tier** | 🆓 Free (basic) · 💎 Premium (custom shortcuts) |

### Phase 2 Summary

| Metric | Target |
|--------|--------|
| **Tổng features mới** | 9 features |
| **Platforms** | iOS + macOS + watchOS (basic) |
| **Timeline** | Tháng 4-6 |
| **Goal** | 5,000 users, 10% conversion to Premium trial |
| **Validation** | Users có set budget và quay lại check không? |

---

## 6. Phase 3 — AI & Premium (Tháng 7-10)

> **Mục tiêu**: AI trở thành core differentiator. Cloud AI cho insights 
> nâng cao, receipt scanning, và financial assistant.

### 6.1 AI-Powered Features

#### F3.1 — Receipt Scanning (OCR + AI)
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Chụp hóa đơn → AI tự động trích xuất thông tin |
| **Cơ chế** | Vision framework (on-device OCR) + Core ML cho structured extraction |
| **Trích xuất** | Tổng tiền, ngày, tên cửa hàng, danh sách items (nếu có) |
| **Hỗ trợ** | Hóa đơn VAT VN, receipt POS, bill nhà hàng, hóa đơn điện/nước |
| **Đặc thù VN** | Nhận diện format VND (1.000.000, 1,000,000, 1000000), hóa đơn tiếng Việt |
| **Flow** | Chụp ảnh → preview extraction → confirm/edit → save giao dịch |
| **Lưu trữ** | Lưu ảnh gốc, link với giao dịch |
| **Cloud fallback** | Nếu on-device OCR accuracy < 70% → gửi lên cloud AI xử lý |
| **Tier** | 🆓 Free: 5 scans/tháng · 💎 Premium: không giới hạn |

#### F3.2 — AI Financial Insights
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Phân tích chi tiêu và đưa ra insights có giá trị |
| **Insights types** | Spending anomalies: "Chi tiêu ăn uống tháng này tăng 40% so với trung bình" |
| | Savings opportunities: "Bạn chi 2.5 triệu/tháng cho café — giảm 50% = tiết kiệm 15 triệu/năm" |
| | Pattern detection: "Bạn thường chi tiêu nhiều hơn vào cuối tuần" |
| | Subscription alerts: "Bạn có 3 subscription ít dùng, tổng 450K/tháng" |
| | Comparative: "Chi phí ăn uống của bạn chiếm 35% thu nhập, trung bình người cùng mức thu nhập là 25%" |
| **Delivery** | Weekly digest (push notification + in-app), Monthly report |
| **Cơ chế** | On-device: pattern detection, anomaly flagging · Cloud AI: natural language insights, comparative analysis |
| **Tier** | 🆓 Free: 1 insight/tuần · 💎 Premium: full weekly + monthly report |

#### F3.3 — AI Financial Assistant (Chat)
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Chatbot hỏi đáp về tài chính cá nhân |
| **Ví dụ câu hỏi** | "Tháng này tôi chi bao nhiêu cho ăn uống?", "Tôi có đủ tiền mua iPhone không?", "Nên cắt giảm chi tiêu ở đâu?", "So sánh chi tiêu tháng này vs tháng trước" |
| **Cơ chế** | Cloud AI (Claude API) với context = dữ liệu tài chính người dùng |
| **Privacy** | Chỉ gửi aggregated data (tổng theo category, không gửi từng giao dịch), option opt-out |
| **Ngôn ngữ** | Tiếng Việt + English |
| **Giới hạn** | Không đưa lời khuyên đầu tư cụ thể, disclaimer rõ ràng |
| **Tier** | 💎 Premium (20 questions/tháng) · 💎💎 Premium+: không giới hạn |

#### F3.4 — Predictive Cash Flow
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Dự đoán số dư tương lai dựa trên pattern thu/chi |
| **Dự đoán** | Số dư cuối tháng, Số dư 3 tháng tới, Ngày "hết tiền" nếu chi tiêu như hiện tại |
| **Input** | Recurring transactions, spending patterns, seasonal trends |
| **Visualization** | Line chart: quá khứ (thực) → tương lai (dự đoán, với khoảng tin cậy) |
| **Alert** | "Dựa trên chi tiêu hiện tại, bạn sẽ vượt ngân sách vào ngày 22" |
| **Cơ chế** | On-device ML: time series forecasting với Create ML |
| **Tier** | 💎 Premium |

### 6.2 Nợ & Cho Vay

#### F3.5 — Debt Tracking
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Quản lý nợ (vay ngân hàng, thẻ tín dụng, vay cá nhân) |
| **Thông tin** | Số tiền gốc, lãi suất, kỳ hạn, payment schedule |
| **Chiến lược** | Snowball (nhỏ trước), Avalanche (lãi cao trước), tùy chỉnh |
| **Tính toán** | Tổng lãi phải trả, ngày hết nợ, tiết kiệm được bao nhiêu nếu trả thêm |
| **Đặc thù VN** | Hỗ trợ lãi suất thả nổi (phổ biến ở VN), tính theo lãi giảm dần |
| **Tier** | 💎 Premium |

#### F3.6 — Cho vay/mượn cá nhân (Lend/Borrow)
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Theo dõi tiền cho vay/mượn bạn bè, người thân |
| **Thông tin** | Ai, bao nhiêu, ngày vay, deadline trả, ghi chú |
| **Nhắc nhở** | Nhắc mình đòi tiền hoặc nhắc trả tiền |
| **Đặc thù VN** | Rất phổ biến ở VN — cho bạn mượn, biếu người thân rồi được trả lại |
| **Tier** | 🆓 Free: 3 records · 💎 Premium: không giới hạn |

### 6.3 Báo Cáo Nâng Cao

#### F3.7 — Custom Reports
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Báo cáo tùy chỉnh theo nhu cầu |
| **Loại** | Income vs Expense (theo thời gian), Category breakdown (pie, bar, treemap), Trend analysis (6-12 tháng), Net worth over time, Cash flow statement, Tax summary (cho freelancer) |
| **Export** | PDF report đẹp, CSV raw data, share image (for social/accountability) |
| **Schedule** | Tự động gửi report qua email hàng tuần/tháng |
| **Tier** | 💎 Premium |

#### F3.8 — Net Worth Tracker
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Theo dõi tổng tài sản ròng theo thời gian |
| **Assets** | Tiền mặt, ngân hàng, đầu tư, bất động sản (nhập thủ công), vàng, crypto |
| **Liabilities** | Nợ vay, thẻ tín dụng, nợ cá nhân |
| **Đặc thù VN** | Hỗ trợ nhập giá trị vàng SJC (auto-update giá), giá trị đất/nhà ước tính |
| **Visualization** | Stacked area chart: tài sản vs nợ theo thời gian |
| **Tier** | 💎 Premium |

### Phase 3 Summary

| Metric | Target |
|--------|--------|
| **Tổng features mới** | 8 features |
| **AI features** | 4 (receipt scan, insights, assistant, forecasting) |
| **Timeline** | Tháng 7-10 |
| **Goal** | 15,000 users, 8% paying subscribers |
| **Validation** | Premium conversion rate, AI engagement rate |

---

## 7. Phase 4 — Ecosystem & Scale (Tháng 11-14)

> **Mục tiêu**: Social features, advanced automation, bank integration path,
> và mở rộng ecosystem.

### 7.1 Social & Shared Finance

#### F4.1 — Shared Wallets (Gia đình/Cặp đôi)
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Quản lý tài chính chung giữa 2+ người |
| **Mời thành viên** | Qua Apple ID / link mời |
| **Cấu trúc** | Mỗi người có: Tài khoản riêng (chỉ mình thấy) + Tài khoản chung (cả 2 thấy) |
| **Tính năng** | Budget chung, giao dịch tagged "ai chi", báo cáo cá nhân vs chung |
| **Permissions** | Owner (full access), Member (add transactions, view reports), Viewer (xem only) |
| **Privacy** | Tài khoản riêng luôn private, chỉ shared wallet mới hiện cho người kia |
| **Tier** | 💎 Premium (share với 1 người) · 💎💎 Family plan: 5 người |

#### F4.2 — Split Bills
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Chia tiền khi đi ăn/du lịch nhóm |
| **Flow** | Nhập tổng bill → chọn người tham gia → chia đều hoặc custom amount |
| **Tracking** | Ai nợ ai bao nhiêu, settle up |
| **Integration** | Suggest banking/MoMo transfer link để trả tiền |
| **Đặc thù VN** | "Đi nhậu" culture — chia tiền rất phổ biến |
| **Tier** | 🆓 Free: basic split · 💎 Premium: groups, history, settle tracking |

### 7.2 Advanced Automation

#### F4.3 — Smart Rules Engine
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Tạo rules tự động cho giao dịch |
| **Ví dụ rules** | IF ghi chú chứa "Grab" → category = Di chuyển/Grab |
| | IF số tiền > 5.000.000₫ → tag "Chi lớn" + thông báo |
| | IF category = Ăn ngoài AND ngày = weekend → tag "Weekend treats" |
| **Builder** | Visual rule builder (WHEN → IF → THEN) |
| **Tier** | 💎 Premium |

#### F4.4 — Bank Statement Import
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Import giao dịch từ sao kê ngân hàng |
| **Format** | CSV, Excel, PDF (OCR for VN bank statements) |
| **Hỗ trợ ngân hàng VN** | Template cho: Vietcombank, Techcombank, BIDV, VPBank, MBBank, ACB, TPBank |
| **Duplicate detection** | AI detect giao dịch trùng (đã nhập thủ công) |
| **Mapping** | Auto-map columns, cho user confirm mapping lần đầu |
| **Tier** | 💎 Premium |

#### F4.5 — Auto-savings Rules
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Tự động "để dành" tiền vào goals |
| **Rules** | Round-up: Mỗi giao dịch làm tròn lên → phần dư vào savings |
| | Fixed: Tự động chuyển X đồng/ngày hoặc /tuần |
| | Percentage: Mỗi khi có income → auto allocate % vào goal |
| | Challenge: 52-week challenge, daily savings challenge |
| **Lưu ý** | Đây là tracking/allocation, không phải chuyển tiền thật (app không access bank) |
| **Tier** | 💎 Premium |

### 7.3 Freelancer/Business Features

#### F4.6 — Income by Client/Project
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Theo dõi thu nhập theo khách hàng hoặc dự án |
| **Tạo** | Client profile (tên, thông tin liên hệ), Project (tên, client, budget) |
| **Tracking** | Thu nhập từ mỗi client/project, pending invoices |
| **Report** | Top clients by revenue, project profitability |
| **Thuế** | Ước tính thuế thu nhập cá nhân (cho freelancer VN: thuế 2% doanh thu < 100tr/năm) |
| **Tier** | 💎 Premium |

#### F4.7 — Business vs Personal separation
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Toggle view giữa chi tiêu cá nhân và công việc |
| **Cơ chế** | Tag-based: mỗi giao dịch tag "personal" hoặc "business" |
| **Report** | Báo cáo riêng cho mỗi context |
| **Tax** | Export chi phí business cho kê khai thuế |
| **Tier** | 💎 Premium |

### 7.4 Platform Expansion

#### F4.8 — macOS Full Experience
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | macOS app với trải nghiệm desktop đầy đủ |
| **Exclusive features** | Keyboard shortcuts cho mọi action, Table view với sort/filter mạnh, Multi-window (dashboard + transaction entry cùng lúc), Drag & drop CSV import, Menu bar quick-entry widget, Touch Bar support (nếu còn) |
| **Tier** | Cùng tier với iOS (1 subscription = cả 2 platforms) |

#### F4.9 — iPadOS Optimization
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Tận dụng màn hình lớn iPad |
| **Features** | Split view: list + detail cùng lúc, Pencil support: annotate receipts, Keyboard shortcuts, Stage Manager support |
| **Tier** | Cùng subscription |

#### F4.10 — Data Import from Other Apps
| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Import dữ liệu từ app tài chính khác |
| **Hỗ trợ** | Money Lover (CSV export), Monefy, Spendee, YNAB, Mint (CSV), MoneyWiz |
| **Flow** | Upload file → detect app source → auto-map → preview → import |
| **Tier** | 🆓 Free |

### Phase 4 Summary

| Metric | Target |
|--------|--------|
| **Tổng features mới** | 10 features |
| **Timeline** | Tháng 11-14 |
| **Goal** | 50,000 users, 12% paying, 4.7★ App Store |
| **Validation** | Shared wallet adoption, freelancer segment growth |

---

## 8. Mô Hình Freemium Chi Tiết

### Tier Structure

| | 🆓 Free | 💎 Premium | 💎💎 Family |
|---|---------|-----------|------------|
| **Giá** | $0 | 49.000₫/tháng hoặc 399.000₫/năm (~$3.99/m hoặc $29.99/y) | 79.000₫/tháng hoặc 649.000₫/năm |
| **Tài khoản** | 5 | Không giới hạn | Không giới hạn |
| **Đồng tiền** | 1 (VND) | Không giới hạn + real-time rates | Không giới hạn |
| **Budgets** | 3 | Không giới hạn + rollover | Không giới hạn |
| **Goals** | 2 | Không giới hạn | Không giới hạn |
| **Recurring** | 5 | Không giới hạn | Không giới hạn |
| **Receipt scan** | 5/tháng | Không giới hạn | Không giới hạn |
| **Reports** | Cơ bản (tháng hiện tại) | Full history + export + custom | Full + family combined |
| **AI Insights** | 1/tuần | Full weekly + monthly | Full + family insights |
| **AI Assistant** | ✗ | 20 questions/tháng | 40 questions/tháng |
| **Cash flow forecast** | ✗ | ✓ | ✓ |
| **Net worth** | ✗ | ✓ | ✓ |
| **Debt management** | ✗ | ✓ | ✓ |
| **Smart Rules** | ✗ | ✓ | ✓ |
| **Bank import** | ✗ | ✓ | ✓ |
| **Shared wallet** | ✗ | 1 partner | 5 thành viên |
| **Sync** | iCloud | iCloud | iCloud |
| **Apple Watch** | ✗ | ✓ | ✓ |
| **Platforms** | iOS + macOS | iOS + macOS + watchOS + iPad | iOS + macOS + watchOS + iPad |
| **Freelancer tools** | ✗ | ✓ | ✓ |

### Conversion Strategy

| Trigger | Mechanism |
|---------|-----------|
| **Soft paywall** | Khi user chạm giới hạn (VD: tạo account thứ 6) → show upgrade screen |
| **Value preview** | Show insight bị blur + "Unlock with Premium" |
| **Trial** | 14 ngày free Premium khi mới cài app |
| **Annual nudge** | Khi renew monthly → suggest annual (tiết kiệm 30%) |
| **Referral** | Mời bạn → cả 2 được 1 tháng free Premium |

---

## 9. AI Architecture — Hybrid Strategy

### Layer 1: On-Device (Core ML / Create ML)

```
┌─────────────────────────────────────────────────┐
│              ON-DEVICE AI (Free tier)            │
├─────────────────────────────────────────────────┤
│                                                  │
│  ┌──────────────────┐  ┌─────────────────────┐  │
│  │ Auto-categorize  │  │ Receipt OCR         │  │
│  │ (Text Classifier)│  │ (Vision + Core ML)  │  │
│  ├──────────────────┤  ├─────────────────────┤  │
│  │ Input: note,     │  │ Input: camera image │  │
│  │ amount, time     │  │ Output: amount,     │  │
│  │ Output: top 3    │  │ date, merchant,     │  │
│  │ categories       │  │ items               │  │
│  └──────────────────┘  └─────────────────────┘  │
│                                                  │
│  ┌──────────────────┐  ┌─────────────────────┐  │
│  │ Pattern Detection│  │ Anomaly Detection   │  │
│  │ (Tabular ML)     │  │ (Statistical)       │  │
│  ├──────────────────┤  ├─────────────────────┤  │
│  │ Detect recurring │  │ Flag unusual spend  │  │
│  │ patterns, time-  │  │ vs historical avg   │  │
│  │ of-day habits    │  │                     │  │
│  └──────────────────┘  └─────────────────────┘  │
│                                                  │
│  ┌──────────────────┐                           │
│  │ Cash Flow        │                           │
│  │ Forecasting      │                           │
│  │ (Time Series)    │                           │
│  └──────────────────┘                           │
│                                                  │
│  Privacy: ✓ 100% on-device                     │
│  Latency: < 100ms                               │
│  Requires: iOS 17+ / macOS 14+                  │
└─────────────────────────────────────────────────┘
```

### Layer 2: Cloud AI (Premium tier)

```
┌─────────────────────────────────────────────────┐
│              CLOUD AI (Premium only)             │
├─────────────────────────────────────────────────┤
│                                                  │
│  ┌──────────────────┐  ┌─────────────────────┐  │
│  │ AI Financial     │  │ Natural Language     │  │
│  │ Assistant (Chat) │  │ Insights Generator  │  │
│  ├──────────────────┤  ├─────────────────────┤  │
│  │ Claude Sonnet API│  │ Claude Haiku API    │  │
│  │ Context: user's  │  │ Input: aggregated   │  │
│  │ aggregated data  │  │ spending data       │  │
│  │ Conversational   │  │ Output: weekly/     │  │
│  │ Q&A about finance│  │ monthly digest NL   │  │
│  └──────────────────┘  └─────────────────────┘  │
│                                                  │
│  ┌──────────────────┐  ┌─────────────────────┐  │
│  │ Advanced Receipt │  │ Comparative         │  │
│  │ Processing       │  │ Analysis            │  │
│  ├──────────────────┤  ├─────────────────────┤  │
│  │ Fallback khi     │  │ Anonymous benchmark │  │
│  │ on-device OCR    │  │ vs peers cùng mức   │  │
│  │ không đủ tốt     │  │ thu nhập (opt-in)   │  │
│  └──────────────────┘  └─────────────────────┘  │
│                                                  │
│  Privacy: Aggregated data only, no PII          │
│  Latency: 1-3 seconds                           │
│  Cost: ~$0.002-0.01 per request                 │
└─────────────────────────────────────────────────┘
```

### AI Data Flow & Privacy

```
User Data (on device)
    │
    ├─ Raw transactions ──→ NEVER leaves device
    ├─ Receipt images ──→ Processed on-device first
    │                      └─→ Cloud only if on-device fails (opt-in)
    │
    ├─ Aggregated summaries ──→ Cloud AI (Premium)
    │   (category totals, trends, no individual transactions)
    │
    └─ Anonymous benchmarks ──→ Cloud (opt-in only)
        (income bracket, spending ratios, no identity)
```

### Model Training Pipeline

| Model | Training Approach | Update Frequency |
|-------|------------------|-----------------|
| **Categorizer** | Pre-trained trên VN spending data + federated fine-tuning on-device | Continuous (on-device) |
| **Receipt OCR** | Pre-trained Vision model + fine-tuned trên VN receipts/invoices | Quarterly (model update via app update) |
| **Forecasting** | Create ML TabularRegressor, trained per-user on-device | Weekly (on-device) |
| **Anomaly** | Statistical (z-score, IQR) — không cần ML model | Real-time |
| **NL Insights** | Claude API with prompt engineering | Prompt updates via server config |

---

## 10. Data Model Overview

### Core Entities

```
Account
├── id: UUID
├── name: String
├── type: AccountType (cash, bank, credit, ewallet, savings, investment, loan)
├── currency: CurrencyCode (VND, USD, EUR...)
├── balance: Decimal
├── icon: String (SF Symbol name)
├── color: String (hex)
├── isArchived: Bool
├── sortOrder: Int
├── createdAt: Date
├── updatedAt: Date
└── deletedAt: Date?

Transaction
├── id: UUID
├── amount: Decimal (always positive)
├── type: TransactionType (income, expense, transfer)
├── note: String?
├── date: Date
├── account: Account
├── toAccount: Account? (for transfers)
├── category: Category
├── tags: [Tag]
├── receiptImage: Data?
├── location: CLLocation?
├── isRecurring: Bool
├── recurringRule: RecurringRule?
├── createdAt: Date
├── updatedAt: Date
├── deletedAt: Date?
└── metadata: [String: String]? (for AI data, source, etc.)

Category
├── id: UUID
├── name: String
├── localizedName: [Locale: String]
├── type: TransactionType (income, expense)
├── parent: Category? (for sub-categories)
├── icon: String (SF Symbol)
├── color: String (hex)
├── sortOrder: Int
├── isSystem: Bool (default categories)
└── isHidden: Bool

Budget
├── id: UUID
├── category: Category
├── amount: Decimal
├── period: BudgetPeriod (weekly, monthly, yearly)
├── startDate: Date
├── rollover: Bool
├── rolledAmount: Decimal
└── alerts: [BudgetAlert] (at 50%, 80%, 100%)

Goal
├── id: UUID
├── name: String
├── targetAmount: Decimal
├── currentAmount: Decimal
├── deadline: Date?
├── icon: String
├── linkedAccount: Account?
└── autoContribute: AutoContributeRule?

RecurringRule
├── id: UUID
├── frequency: Frequency (daily, weekly, biweekly, monthly, quarterly, yearly)
├── nextDate: Date
├── endDate: Date?
├── template: Transaction (template data)
├── isAutoConfirm: Bool
└── reminderDaysBefore: Int

SharedWallet
├── id: UUID
├── name: String
├── members: [Member] (userId, role, joinedAt)
├── accounts: [Account]
├── budgets: [Budget]
└── inviteCode: String

Debt
├── id: UUID
├── name: String
├── type: DebtType (owed_by_me, owed_to_me)
├── principalAmount: Decimal
├── remainingAmount: Decimal
├── interestRate: Decimal?
├── personName: String?
├── dueDate: Date?
├── payments: [Transaction]
└── notes: String?

ExchangeRate
├── baseCurrency: CurrencyCode
├── targetCurrency: CurrencyCode
├── rate: Decimal
├── date: Date
└── source: String
```

---

## 11. UX Flow Chính

### Quick Transaction Input (iOS)

```
[Home Screen]
    │
    ├─ Tap "+" FAB button
    │
    ▼
[Amount Input Screen]
    │  Custom numpad with calculator
    │  Type: 150k → auto-expand to 150.000
    │  Quick buttons: k (×1.000), tr (×1.000.000)
    │
    ├─ Enter amount → auto-suggest category (AI)
    │
    ▼
[Category Picker]
    │  Grid of recent categories (top 6)
    │  "See all" → full category list
    │  AI suggested category highlighted
    │
    ├─ Select category
    │
    ▼
[Quick Review]
    │  Amount: 150.000₫
    │  Category: Café/Trà sữa ☕
    │  Account: Ví tiền mặt
    │  Date: Hôm nay
    │  [Save] [Add note] [More options]
    │
    ├─ Tap Save → Done! (< 5 seconds total)
    │
    └─ Tap More → [Note] [Tags] [Receipt] [Date] [Location]
```

### macOS Quick Entry

```
[Menu Bar Widget] or [⌘+N keyboard shortcut]
    │
    ▼
[Floating Quick Entry Window]
    │  Compact form: Amount | Category | Account | Note
    │  Keyboard-driven: Tab between fields
    │  Auto-complete category names as you type
    │  Enter → Save → Window closes
    │
    └─ Total time: < 3 seconds
```

### Receipt Scanning Flow

```
[Camera / Photo Library]
    │
    ├─ Capture receipt image
    │
    ▼
[Processing Screen]
    │  "Đang phân tích hóa đơn..."
    │  On-device OCR → extract data
    │
    ▼
[Extracted Data Preview]
    │  Total: 385.000₫ ✏️ (editable)
    │  Date: 12/02/2026 ✏️
    │  Merchant: Highland Coffee ✏️
    │  Category: Café/Trà sữa (AI suggested)
    │  Items (if detected):
    │    - Phin Sữa Đá: 45.000₫
    │    - Bánh Mì: 35.000₫
    │  Account: [Select]
    │
    ├─ Confirm → Save transaction + receipt image
    │
    └─ Edit → Modify any field → Save
```

---

## 12. Phân Tích Cạnh Tranh & Khác Biệt

### So Sánh Với Đối Thủ

| Feature | FinanceApp (Ours) | Money Lover | Copilot | YNAB | MoneyWiz |
|---------|-------------------|-------------|---------|------|----------|
| **Native macOS** | ✓ Full | ✗ Web only | ✓ | ✗ Web | ✓ |
| **VND optimized** | ✓✓ Best | ✓ Good | ✗ | ✗ | △ Basic |
| **On-device AI** | ✓ Core ML | ✗ | ✓ | ✗ | △ |
| **AI Assistant** | ✓ Claude | ✗ | ✗ | ✗ | ✗ |
| **Receipt scan VN** | ✓ VN focused | △ Basic | ✓ US focused | ✗ | △ |
| **Shared wallet** | ✓ | ✓ | ✗ | ✗ | ✗ |
| **Multi-currency** | ✓ | ✓ | ✗ USD only | ✓ | ✓ |
| **Offline-first** | ✓ | △ | ✓ | ✗ | ✓ |
| **Apple Watch** | ✓ | ✗ | ✓ | ✗ | ✓ |
| **VN bank import** | ✓ Templates | ✗ | ✗ | ✗ | ✗ |
| **Freelancer mode** | ✓ | ✗ | ✗ | ✗ | △ |
| **Vàng/BĐS tracking** | ✓ VN specific | ✗ | ✗ | ✗ | ✗ |
| **Giá** | 49K VND/m | 55K VND/m | $10/m | $14.99/m | $35/y |
| **Nền tảng** | Apple only | All | Apple only | All | All |

### Unique Selling Points (USP)

1. **"App tài chính Việt Nam đầu tiên với AI thực sự thông minh"**
   - Không app VN nào có on-device AI categorization + AI assistant
   - Copilot có AI nhưng không hỗ trợ VND/tiếng Việt

2. **"Native Apple, không phải web bọc app"**
   - SwiftUI native = smooth, fast, đúng chuẩn Apple HIG
   - Tận dụng Widget, Shortcuts, Watch, Handoff mà web app không thể

3. **"Hiểu người Việt"**
   - Categories phản ánh thói quen VN (café, xe máy, biếu bố mẹ)
   - Format VND đúng cách, ví MoMo/ZaloPay
   - Import sao kê ngân hàng VN
   - Theo dõi vàng SJC, đất đai

4. **"Privacy-first, dữ liệu của bạn là của bạn"**
   - AI chạy trên thiết bị, không gửi giao dịch lên cloud
   - iCloud sync (Apple encrypted), không phải server riêng
   - Không bán data, không ads

---

## 13. Technical Considerations

### Performance Targets

| Metric | Target |
|--------|--------|
| App launch → interactive | < 1 second |
| Transaction input → save | < 100ms |
| Receipt scan → result | < 3 seconds |
| AI categorization | < 50ms |
| Search 10K transactions | < 200ms |
| Sync conflict resolution | < 500ms |
| App size | < 50MB |

### Localization

| Language | Priority | Scope |
|----------|----------|-------|
| Tiếng Việt | P0 | Full app |
| English | P0 | Full app |
| 日本語 (Japanese) | P2 | Basic UI |
| 한국어 (Korean) | P2 | Basic UI |

### Accessibility

- VoiceOver support 100%
- Dynamic Type (all text sizes)
- Color contrast ≥ 4.5:1
- Reduce Motion support
- Bold Text support
- Switch Control compatible

### Security

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

## 14. KPIs & Success Metrics

### North Star Metric
> **Monthly Active Users who input ≥ 10 transactions/month**
> (This means they're actually using the app meaningfully)

### Phase-by-Phase KPIs

| Phase | KPI | Target |
|-------|-----|--------|
| MVP | Downloads | 1,000 |
| MVP | D7 Retention | 50% |
| MVP | Avg transactions/user/week | 5+ |
| Phase 2 | MAU | 5,000 |
| Phase 2 | Premium trial starts | 10% of MAU |
| Phase 2 | Budget feature adoption | 30% of MAU |
| Phase 3 | MAU | 15,000 |
| Phase 3 | Paying subscribers | 8% of MAU |
| Phase 3 | AI feature engagement | 60% of Premium users |
| Phase 3 | App Store rating | 4.5★+ |
| Phase 4 | MAU | 50,000 |
| Phase 4 | Paying subscribers | 12% of MAU |
| Phase 4 | Shared wallet adoption | 20% of Premium |
| Phase 4 | MRR | 100M VND (~$4,000) |
| Phase 4 | App Store rating | 4.7★+ |

### User Engagement Metrics

| Metric | Good | Great | Amazing |
|--------|------|-------|---------|
| DAU/MAU ratio | 30% | 45% | 60%+ |
| Session frequency | 1x/day | 2x/day | 3x+/day |
| Session duration | 30s | 1min | 2min+ |
| Transactions/user/month | 10 | 30 | 50+ |
| Budget check frequency | 1x/week | 3x/week | Daily |

---

*Document version 1.0 — February 2026*
*Tài liệu này nên được review và cập nhật sau mỗi phase.*
