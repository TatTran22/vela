# Phase 1 — MVP (Tháng 1-3)

> **Mục tiêu**: App hoạt động được, giải quyết bài toán cơ bản nhất —
> "Tiền tôi đi đâu?" Tập trung iOS trước, macOS companion.

## Tổng Quan

| Metric | Target |
|--------|--------|
| Tổng features | 12 features cốt lõi |
| Platforms | iOS (primary) + macOS (companion) |
| Timeline | 3 tháng |
| Goal | 1,000 users, 50% D7 retention |
| Validation | Người dùng có quay lại nhập giao dịch mỗi ngày không? |

---

## Features

### F1.1 — Tạo & Quản Lý Tài Khoản

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Tạo tài khoản đại diện cho nơi giữ tiền thực tế |
| **Loại** | Tiền mặt, Ngân hàng, Thẻ tín dụng, Ví điện tử (MoMo, ZaloPay, VNPay), Tiết kiệm |
| **Thuộc tính** | Tên, loại, số dư ban đầu, đồng tiền (mặc định VND), icon/màu, ghi chú |
| **Tính năng** | Sắp xếp thứ tự, ẩn/hiện, archive tài khoản cũ |
| **Hiển thị** | Tổng số dư tất cả tài khoản, group theo loại |
| **Tier** | 🆓 Free: 5 tài khoản · 💎 Premium: không giới hạn |

### F1.2 — Multi-Currency Cơ Bản

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Mỗi tài khoản gắn một loại tiền tệ |
| **Hỗ trợ** | VND (mặc định), USD, EUR, JPY, KRW, THB, SGD, AUD, GBP, CNY |
| **Tỷ giá** | Tự động cập nhật hàng ngày (free), real-time (premium) |
| **Quy đổi** | Hiển thị song song: giá trị gốc + quy đổi về đồng tiền chính |
| **VND** | Không decimal, format 1.000.000 ₫ |
| **Tier** | 🆓 Free: 1 đồng tiền · 💎 Premium: không giới hạn + real-time |

### F1.3 — Nhập Giao Dịch Thủ Công

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Mô tả** | Ghi nhận thu/chi/chuyển khoản nhanh nhất có thể |
| **Loại** | Income, Expense, Transfer |
| **Bắt buộc** | Số tiền, tài khoản, danh mục |
| **Tùy chọn** | Ghi chú, ngày, ảnh/receipt, tags, địa điểm |
| **Quick Input** | Mở app → nhập số → chọn danh mục → Done (< 5 giây) |
| **Số tiền** | Bàn phím tùy chỉnh: `k` (×1.000), `tr` (×1.000.000), calculator |
| **Lặp lại** | Đánh dấu "lặp lại" → tạo recurring template |
| **Tier** | 🆓 Free |

### F1.4 — Danh Sách & Tìm Kiếm Giao Dịch

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Hiển thị** | Nhóm theo ngày, tổng thu/chi mỗi ngày |
| **Tìm kiếm** | Full-text: ghi chú, danh mục, số tiền, tags |
| **Bộ lọc** | Tài khoản, danh mục, thời gian, số tiền, tags |
| **Hành động** | Swipe-to-delete, edit, duplicate, đổi danh mục |
| **macOS** | Table view với columns sortable, multi-select, bulk edit |
| **Tier** | 🆓 Free |

### F1.5 — Chuyển Khoản Giữa Tài Khoản

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Logic** | 1 giao dịch → trừ nguồn + cộng đích |
| **Cross-currency** | Nhập cả 2 số tiền hoặc tỷ giá |
| **Báo cáo** | Transfer KHÔNG tính income/expense |
| **Tier** | 🆓 Free |

### F1.6 — Hệ Thống Danh Mục

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Cấu trúc** | 2 cấp: Category → Sub-category |
| **Expense** | Ăn uống, Nhà ở, Di chuyển, Mua sắm, Giải trí, Sức khỏe, Giáo dục, Gia đình, Tài chính, Khác |
| **Income** | Lương, Thưởng, Freelance, Đầu tư, Cho thuê, Quà/biếu, Hoàn tiền, Khác |
| **Tùy chỉnh** | Thêm/sửa/xóa, chọn icon (SF Symbols), chọn màu |
| **VN-specific** | "Biếu bố mẹ", "Café/trà sữa", "Grab/taxi", "Gửi xe" |
| **Tier** | 🆓 Free |

### F1.7 — Dashboard (Home Screen)

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Thành phần** | Tổng số dư, Thu nhập tháng, Chi tiêu tháng, Còn lại, Mini chart 7 ngày, 3-5 giao dịch gần nhất |
| **iOS** | Scroll vertical, card-based |
| **macOS** | Sidebar + main content, dense |
| **Interaction** | Tap section → drill down |
| **Tier** | 🆓 Free |

### F1.8 — Báo Cáo Chi Tiêu Cơ Bản

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Biểu đồ** | Pie chart (danh mục), Bar chart (thu/chi theo thời gian), Trend line (6 tháng) |
| **Tương tác** | Tap slice → xem transactions |
| **Kỳ** | Tuần, tháng, tháng trước, tùy chỉnh |
| **Tier** | 🆓 Free: tháng hiện tại · 💎 Premium: full history + export |

### F1.9 — iCloud Sync

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Cơ chế** | CloudKit private database |
| **Conflict** | Last-write-wins (simple), merge (transactions) |
| **Offline** | Hoàn toàn offline, sync khi có mạng |
| **Status** | UI: synced ✓, syncing ↻, offline ○ |
| **Tier** | 🆓 Free |

### F1.10 — iOS Widget

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Small** | Tổng số dư hoặc chi tiêu hôm nay |
| **Medium** | Chi tiêu tuần + mini chart |
| **Large** | Top categories + giao dịch gần nhất |
| **Interactive** | Tap → mở app đúng section |
| **Tier** | 🆓 Free |

### F1.11 — Onboarding Flow

| Bước | Nội dung | Skip? |
|------|----------|-------|
| 1 | Chọn đồng tiền chính (detect locale → VND) | ✗ |
| 2 | Tạo tài khoản đầu tiên | ✗ |
| 3 | Nhập số dư hiện tại | ✓ |
| 4 | Nhập 1 giao dịch thử | ✓ |
| 5 | Feature highlights (3 slides) | ✓ |

**Target:** < 2 phút hoàn thành.

### F1.12 — Settings

| Thuộc tính | Chi tiết |
|-----------|---------|
| **Giao diện** | Dark/Light/System, App icon alternatives |
| **Đồng tiền** | Đồng tiền chính, format hiển thị |
| **Ngôn ngữ** | Tiếng Việt, English |
| **Bảo mật** | Face ID/Touch ID, auto-lock timeout |
| **Data** | Export CSV/JSON, backup iCloud manual |
| **Ngày bắt đầu tháng** | Mặc định 1, cho chỉnh (VD: 25 nếu lương ngày 25) |
| **Tier** | 🆓 Free |

---

## Technical Tasks

- [ ] Setup Xcode project + Swift Packages
- [ ] SwiftData models + CloudKit integration
- [ ] Core UI components (FinanceUI package)
- [ ] Transaction CRUD + search/filter
- [ ] Account management
- [ ] Category system with VN defaults
- [ ] Dashboard views (iOS + macOS)
- [ ] Basic reports (Swift Charts)
- [ ] iCloud sync + conflict resolution
- [ ] WidgetKit implementation
- [ ] Onboarding flow
- [ ] Settings screen
- [ ] Localization (vi + en)
- [ ] Biometric auth (Face ID/Touch ID)
- [ ] Testing (unit + UI)
