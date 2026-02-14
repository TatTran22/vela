---
description: "Triển khai feature Receipt Scanning — F3.1 OCR + AI extract hóa đơn → auto-fill transaction (Premium)"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: Receipt Scanning

## Feature Spec References
- F3.1: Receipt Scanning (OCR + AI)

## Đọc Context Trước
1. `CLAUDE.md` — tech stack, code rules, module structure
2. `FinanceApp-Feature-Specification.md` → section 6.1 "F3.1 — Receipt Scanning (OCR + AI)"
3. `docs/DATA-MODEL.md` → Transaction entity (receiptImageData field), metadata field
4. `docs/ARCHITECTURE.md` → Clean Architecture layers
5. `docs/CONVENTIONS.md` → Swift naming, error handling

## Tasks

### FinanceCore
1. `ReceiptScanResult` model:
   - id: UUID
   - totalAmount: Decimal?
   - date: Date?
   - merchantName: String?
   - items: [ReceiptItem]
   - rawText: String
   - confidence: Double (0.0...1.0)
   - imageData: Data
   - source: ReceiptSource
   - createdAt: Date

2. `ReceiptItem` model:
   - name: String
   - quantity: Int?
   - unitPrice: Decimal?
   - totalPrice: Decimal?

3. `ReceiptSource` enum:
   - camera
   - photoLibrary
   - fileImport

4. `ReceiptType` enum (loại hóa đơn VN):
   - vatInvoice (hóa đơn VAT)
   - posReceipt (receipt POS)
   - restaurantBill (bill nhà hàng)
   - utilityBill (hóa đơn điện/nước)
   - other

5. `VNDAmountParser` utility:
   - Parse các format VND phổ biến: "1.000.000", "1,000,000", "1000000", "1.000.000₫", "1,000,000 VND"
   - Parse số tiền có chữ: "150k", "1.5tr"
   - Handle decimal separator ambiguity (dấu chấm vs dấu phẩy)
   - Return: Decimal?

6. `ScanReceiptUseCase` (protocol + implementation):
   - Input: imageData: Data
   - Output: ReceiptScanResult
   - Logic: gọi OCR service → parse structured data → return result
   - Validate: amount > 0, date is reasonable (not future > 1 day, not > 1 year ago)

7. `CreateTransactionFromReceiptUseCase` (protocol + implementation):
   - Input: ReceiptScanResult, accountId: UUID, categoryId: UUID
   - Output: Transaction
   - Logic: map receipt data → transaction, attach receipt image
   - Store original image in Transaction.receiptImageData
   - Store scan metadata in Transaction.metadata: ["source": "receipt_scan", "merchant": name, "confidence": score]

8. `ReceiptScanError` enum:
   - imageProcessingFailed
   - noTextDetected
   - amountNotFound
   - lowConfidence(score: Double)
   - cloudProcessingFailed(underlying: Error)
   - scanLimitReached (free tier: 5/tháng)
   - invalidImage

9. `ReceiptScanLimitService` (protocol + implementation):
   - checkCanScan() -> Bool (check free tier limit: 5 scans/tháng)
   - incrementScanCount()
   - remainingScans() -> Int
   - resetDate() -> Date (đầu tháng tiếp theo)

### FinanceData
10. `ReceiptScanHistoryEntity` @Model:
    - id: UUID, imageData: Data, result: ReceiptScanResult (encoded JSON)
    - linkedTransactionId: UUID?, scannedAt: Date
    - Index on: (scannedAt)

11. `ReceiptScanRepositoryImpl`:
    - save(scan: ReceiptScanResult) -> UUID
    - fetchHistory(limit: Int, offset: Int) -> [ReceiptScanResult]
    - linkToTransaction(scanId: UUID, transactionId: UUID)
    - countScansThisMonth() -> Int
    - deleteOldScans(olderThan: Date) — cleanup ảnh cũ > 6 tháng

### FinanceUI
12. `ReceiptCameraView` — camera overlay with guide frame:
    - Hiển thị khung hướng dẫn căn hóa đơn
    - Nút chụp ảnh, nút chọn từ thư viện, nút flash
    - Auto-detect document edges (VisionKit)

13. `ReceiptPreviewCard` — hiển thị kết quả extract:
    - Ảnh receipt thumbnail bên trái
    - Extracted fields bên phải: amount (editable), date (editable), merchant (editable)
    - Confidence indicator (color-coded: green > 80%, yellow 50-80%, red < 50%)
    - Items list nếu có

14. `ReceiptItemRow` — row cho mỗi item trong hóa đơn:
    - Item name, quantity, unit price, total price

15. `ScanLimitBanner` — banner hiển thị số scans còn lại (free tier):
    - "Còn 3/5 lượt scan tháng này"
    - Nút upgrade Premium khi hết lượt

### iOS
16. `ReceiptScanView` — main scanning screen:
    - Camera preview (VisionKit DocumentCameraViewController wrapped in UIViewControllerRepresentable)
    - Hoặc chọn ảnh từ PhotosPicker
    - Processing overlay: "Đang phân tích hóa đơn..." với progress indicator
    - Error handling UI cho các ReceiptScanError cases

17. `ReceiptScanViewModel` (@Observable):
    - Dependencies: ScanReceiptUseCase, CreateTransactionFromReceiptUseCase, ReceiptScanLimitService
    - State: scanState (idle, scanning, processing, result, error)
    - scanResult: ReceiptScanResult?
    - editableAmount: Decimal (user có thể sửa)
    - editableDate: Date
    - editableMerchant: String
    - selectedAccount: Account?
    - selectedCategory: Category? (AI suggested)
    - Methods: captureImage(), processImage(Data), saveAsTransaction(), retake()

18. `ReceiptResultView` — màn hình review kết quả:
    - Ảnh hóa đơn gốc (zoomable)
    - Extracted data: Amount ✏️, Date ✏️, Merchant ✏️ — tất cả editable
    - Items list (nếu detected)
    - Category picker (AI gợi ý highlight)
    - Account picker
    - Buttons: [Lưu giao dịch] [Chụp lại] [Hủy]

19. `ReceiptHistoryView` — lịch sử scan:
    - List các lần scan gần đây
    - Thumbnail + amount + date + linked transaction status
    - Tap → xem chi tiết / link lại với transaction

20. Navigation integration:
    - Thêm nút camera icon vào TransactionListView toolbar
    - Thêm option "Scan hóa đơn" vào QuickInputView "Thêm chi tiết" section
    - Deep link từ Widget "Quick Scan"

### macOS
21. `ReceiptScanMacView`:
    - Drag & drop image file vào vùng scan
    - Hoặc paste image từ clipboard (⌘V)
    - Hoặc chọn file qua NSOpenPanel
    - Keyboard: ⌘⇧S → open receipt scan

22. `ReceiptDetailMacView`:
    - Split view: ảnh gốc bên trái (zoomable), extracted data bên phải
    - Inline editing cho tất cả fields
    - Tab navigation giữa fields

### Tests
23. `ScanReceiptUseCaseTests`:
    - Scan hóa đơn VAT VN → extract amount, date, merchant correctly
    - Scan POS receipt → extract amount
    - Scan bill nhà hàng với items → extract items list
    - Image không phải hóa đơn → error noTextDetected
    - Image bị mờ → low confidence warning

24. `VNDAmountParserTests`:
    - "1.000.000" → 1_000_000
    - "1,000,000" → 1_000_000
    - "1000000" → 1_000_000
    - "385.000₫" → 385_000
    - "2,500,000 VND" → 2_500_000
    - "150k" → 150_000
    - "1.5tr" → 1_500_000
    - Empty string → nil
    - "abc" → nil

25. `CreateTransactionFromReceiptUseCaseTests`:
    - Receipt result → transaction created with correct amount, date, category
    - Receipt image attached to transaction.receiptImageData
    - Metadata contains source: "receipt_scan", merchant, confidence

26. `ReceiptScanLimitServiceTests`:
    - Free tier: scan count increments correctly
    - 5th scan succeeds, 6th scan returns scanLimitReached
    - Premium tier: no limit
    - Count resets at start of new month

27. `ReceiptScanViewModelTests`:
    - Full flow: capture → process → review → save
    - Edit extracted data before saving
    - Error states: processing failed, low confidence
    - Retake flow: result → retake → new capture
