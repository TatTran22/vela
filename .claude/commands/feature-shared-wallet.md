---
description: "Triển khai Shared Wallets & Split Bills — F4.1 Ví chung gia đình/cặp đôi + F4.2 Chia tiền nhóm"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: Shared Wallets & Split Bills

## Feature Spec References
- F4.1: Shared Wallets (Gia đình/Cặp đôi)
- F4.2: Split Bills

## Đọc Context Trước
1. `CLAUDE.md` — tech stack, architecture rules, code conventions
2. `FinanceApp-Feature-Specification.md` → Section 7.1 (Social & Shared Finance)
3. `docs/DATA-MODEL.md` → SharedWallet, SharedWalletMember, WalletRole enum
4. `docs/ARCHITECTURE.md` — MVVM + Clean Architecture patterns
5. `docs/CONVENTIONS.md` — Swift naming, file organization

## Tasks

### FinanceCore

1. `WalletRole` enum (nếu chưa có):
   ```swift
   enum WalletRole: String, Codable, Sendable {
       case owner    // Full access: CRUD tất cả, quản lý members, xóa wallet
       case editor   // Add/edit transactions, view reports
       case viewer   // Xem only, không thêm/sửa giao dịch
   }
   ```

2. `SharedWallet` model:
   - id: UUID
   - name: String (VD: "Chi tiêu gia đình", "Quỹ vợ chồng")
   - members: [SharedWalletMember]
   - accounts: [Account] — tài khoản chung thuộc wallet này
   - budgets: [Budget] — budget chung
   - inviteCode: String — mã mời 8 ký tự alphanumeric
   - inviteLink: URL? — deep link mời qua iMessage/Zalo
   - currency: CurrencyCode (mặc định VND)
   - createdAt: Date
   - updatedAt: Date
   - deletedAt: Date?

3. `SharedWalletMember` model:
   - id: UUID
   - userIdentifier: String — CloudKit user record ID
   - displayName: String
   - role: WalletRole
   - joinedAt: Date
   - isActive: Bool

4. `WalletActivityType` enum:
   ```swift
   enum WalletActivityType: String, Codable, Sendable {
       case transactionAdded
       case transactionEdited
       case transactionDeleted
       case memberJoined
       case memberLeft
       case memberRoleChanged
       case budgetCreated
       case budgetUpdated
   }
   ```

5. `WalletActivity` model (activity feed):
   - id: UUID
   - walletId: UUID
   - actorId: String — ai thực hiện
   - actorName: String
   - type: WalletActivityType
   - description: String (VD: "Lan đã thêm giao dịch: Đi chợ 350.000₫")
   - relatedTransactionId: UUID?
   - timestamp: Date

6. `SplitType` enum:
   ```swift
   enum SplitType: String, Codable, Sendable {
       case equal        // Chia đều
       case custom       // Nhập số tiền cụ thể cho mỗi người
       case percentage   // Chia theo phần trăm
       case shares       // Chia theo tỷ lệ (VD: 2:1:1)
   }
   ```

7. `SplitBill` model:
   - id: UUID
   - title: String (VD: "Đi nhậu thứ 7", "Du lịch Đà Lạt")
   - totalAmount: Decimal
   - currency: CurrencyCode (mặc định VND)
   - splitType: SplitType
   - paidBy: SplitParticipant — người đã trả tiền
   - participants: [SplitParticipant]
   - date: Date
   - note: String?
   - receiptImageData: Data?
   - isSettled: Bool — đã tất toán hết chưa
   - walletId: UUID? — thuộc shared wallet nào (optional, có thể split ngoài wallet)
   - createdAt: Date
   - updatedAt: Date

8. `SplitParticipant` model:
   - id: UUID
   - name: String
   - userIdentifier: String? — CloudKit ID (nil nếu người ngoài app)
   - amount: Decimal — số tiền phải trả
   - isPaid: Bool — đã trả chưa
   - paidAt: Date?

9. `SettlementSuggestion` model:
   - from: SplitParticipant
   - to: SplitParticipant
   - amount: Decimal
   - paymentMethod: PaymentMethod?

10. `PaymentMethod` enum (VN context):
    ```swift
    enum PaymentMethod: String, Codable, Sendable {
        case cash           // Tiền mặt
        case bankTransfer   // Chuyển khoản ngân hàng
        case momo           // Ví MoMo
        case zalopay        // ZaloPay
        case vnpay          // VNPay
        case vietqr         // VietQR (quét mã QR ngân hàng)
        case other
    }
    ```

11. `CreateSharedWalletUseCase`:
    - Validate: name not empty, currency hợp lệ
    - Tạo wallet với owner = current user
    - Generate inviteCode unique 8 ký tự
    - Tạo CloudKit shared zone cho wallet

12. `InviteMemberUseCase`:
    - Input: walletId, inviteCode hoặc inviteLink
    - Validate: caller là owner hoặc editor
    - Kiểm tra member chưa tồn tại
    - Thêm member với role mặc định = viewer
    - Tạo WalletActivity (memberJoined)
    - Gửi notification cho các members khác

13. `UpdateMemberRoleUseCase`:
    - Validate: chỉ owner mới đổi được role
    - Không thể hạ role của chính mình
    - Tạo WalletActivity (memberRoleChanged)

14. `GetWalletActivityFeedUseCase`:
    - Lấy activity feed theo walletId, paginated
    - Sắp xếp theo timestamp DESC

15. `CreateSplitBillUseCase`:
    - Validate: totalAmount > 0, ít nhất 2 participants
    - Tính toán split theo splitType:
      - equal: totalAmount / participants.count, làm tròn VND (không có xu)
      - percentage: validate tổng = 100%
      - custom: validate tổng amounts = totalAmount
      - shares: tính theo tỷ lệ
    - Xử lý phần dư khi chia (VD: 100.000₫ / 3 = 33.333₫ × 2 + 33.334₫)

16. `CalculateSettlementsUseCase`:
    - Input: danh sách SplitBill chưa settle trong nhóm
    - Output: optimized list of settlements (minimize số lượng giao dịch)
    - Algorithm: net balance → greedy matching
    - VD: A nợ B 100k, B nợ C 50k → A trả B 50k, A trả C 50k

17. `GenerateVietQRUseCase`:
    - Input: bank account info (bank code, account number), amount
    - Output: VietQR URL string theo chuẩn NAPAS
    - Format: `https://img.vietqr.io/image/{bankCode}-{accountNo}-{template}.png?amount={amount}&addInfo={note}`
    - Hỗ trợ các bank: Vietcombank (VCB), Techcombank (TCB), BIDV, VPBank, MBBank, ACB, TPBank

### FinanceData

18. `SharedWalletEntity` @Model:
    - Indexes: (inviteCode) UNIQUE
    - CloudKit: CKShare cho shared zone
    - Relationship: members → [SharedWalletMemberEntity]

19. `SharedWalletMemberEntity` @Model:
    - Indexes: (walletId, userIdentifier) UNIQUE

20. `WalletActivityEntity` @Model:
    - Indexes: (walletId, timestamp)

21. `SplitBillEntity` @Model:
    - Indexes: (walletId), (date), (isSettled)

22. `SplitParticipantEntity` @Model:
    - Relationship: belongs to SplitBillEntity

23. `SharedWalletRepositoryImpl`:
    - createWallet, getWallet, updateWallet, deleteWallet
    - addMember, removeMember, updateMemberRole
    - getWalletsByUser (tất cả wallets user tham gia)

24. `SplitBillRepositoryImpl`:
    - createSplitBill, getSplitBills(walletId:)
    - updateParticipantPayment (đánh dấu đã trả)
    - getUnsettledBills(walletId:)

25. `WalletActivityRepositoryImpl`:
    - logActivity, getActivities(walletId:, limit:, offset:)

26. CloudKit Sharing setup:
    - CKShare configuration cho SharedWallet zone
    - Handle CKShare acceptance flow
    - Sync shared data giữa các participants

### FinanceUI

27. `WalletMemberAvatar` — avatar circle với initials/photo, role badge
28. `MemberRoleBadge` — tag hiển thị role (Owner/Editor/Viewer) với color
29. `ActivityFeedRow` — icon + actor + description + timestamp
30. `SplitAmountInput` — input cho số tiền mỗi người, có nút "Chia đều"
31. `SplitProgressBar` — hiển thị ai đã trả / chưa trả, progress tổng
32. `SettlementCard` — card hiển thị "A → B: 150.000₫" với nút "Đã trả" và QR
33. `VietQRImage` — AsyncImage load QR code từ VietQR API
34. `ParticipantPicker` — chọn participants từ contacts hoặc shared wallet members

### iOS

35. `SharedWalletListView`:
    - Danh sách các shared wallets user tham gia
    - Card hiển thị: tên wallet, số members, tổng chi tiêu tháng
    - FAB button "Tạo ví chung mới"
    - Pull-to-refresh sync

36. `SharedWalletListViewModel`:
    - @Observable, inject SharedWalletRepository
    - wallets: [SharedWallet], isLoading: Bool
    - Fetch wallets on appear, handle refresh

37. `SharedWalletDetailView`:
    - Tab bar: Giao dịch | Ngân sách | Hoạt động | Thành viên
    - Header: tên wallet, tổng số dư, số thành viên
    - Transaction list filtered cho wallet này

38. `SharedWalletDetailViewModel`:
    - Manage wallet data, activity feed
    - Handle member management actions

39. `InviteMemberView`:
    - Hiển thị invite code + invite link
    - Share sheet: iMessage, Zalo, copy link
    - QR code cho invite link

40. `WalletSettingsView`:
    - Đổi tên wallet, manage members, role assignments
    - Rời wallet, xóa wallet (chỉ owner)

41. `SplitBillListView`:
    - Danh sách các bills đã split
    - Filter: Tất cả | Chưa tất toán | Đã tất toán
    - Tổng "Bạn nợ" / "Người khác nợ bạn"

42. `CreateSplitBillView`:
    - Step 1: Nhập tổng tiền + tiêu đề
    - Step 2: Chọn participants (từ wallet members hoặc nhập tay)
    - Step 3: Chọn cách chia (đều/custom/phần trăm)
    - Step 4: Review + chỉnh sửa từng người
    - Step 5: Xác nhận, attach receipt (optional)

43. `CreateSplitBillViewModel`:
    - Manage multi-step flow state
    - Calculate splits real-time khi user thay đổi
    - Validate total matches

44. `SettleUpView`:
    - Danh sách settlements suggested
    - Mỗi settlement: người trả → người nhận, số tiền
    - Nút "Gửi QR" → generate VietQR
    - Nút "Đã trả" → mark as settled
    - Payment method picker

45. `SplitBillDetailView`:
    - Chi tiết bill: ai trả, ai nợ bao nhiêu
    - Timeline: ai đã settle, ai chưa
    - Receipt image (nếu có)

### macOS

46. `SharedWalletSidebarView`:
    - Sidebar item cho mỗi shared wallet
    - Expand → sub-items: Giao dịch, Ngân sách, Thành viên

47. `SharedWalletDashboardView`:
    - NavigationSplitView: sidebar wallets | detail
    - Table view cho transactions, sortable columns
    - Activity feed sidebar panel

48. `SplitBillTableView`:
    - Table: Date | Title | Amount | Participants | Status
    - Sortable, filterable
    - Double-click → detail

49. `macOS Keyboard shortcuts`:
    - ⌘⇧W → Tạo shared wallet mới
    - ⌘⇧S → Tạo split bill mới

### Tests

50. CreateSharedWallet — tạo wallet, generate invite code unique
51. InviteMember — invite flow, duplicate check, role assignment
52. UpdateMemberRole — permission checks (chỉ owner)
53. CreateSplitBill equal — chia đều, xử lý dư khi chia VND
54. CreateSplitBill custom — validate tổng = totalAmount
55. CreateSplitBill percentage — validate tổng = 100%
56. CalculateSettlements — net balance optimization, minimize transactions
57. VietQR generation — format URL đúng chuẩn NAPAS cho các bank VN
58. WalletActivity — log activity đúng khi có actions
59. Permission checks — viewer không thể add transaction, editor không thể manage members
60. CloudKit sharing — CKShare create/accept flow
