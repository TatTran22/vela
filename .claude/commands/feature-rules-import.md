---
description: "Triển khai Smart Rules, Bank Import & Auto-savings — F4.3 Rules Engine + F4.4 Import sao kê ngân hàng VN + F4.5 Tiết kiệm tự động"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: Smart Rules, Bank Import & Auto-savings

## Feature Spec References
- F4.3: Smart Rules Engine
- F4.4: Bank Statement Import
- F4.5: Auto-savings Rules

## Đọc Context Trước
1. `CLAUDE.md` — tech stack, architecture rules, code conventions
2. `FinanceApp-Feature-Specification.md` → Section 7.2 (Advanced Automation)
3. `docs/DATA-MODEL.md` → Transaction, Category, Tag, Goal, AutoContributeRule
4. `docs/ARCHITECTURE.md` — MVVM + Clean Architecture patterns
5. `docs/CONVENTIONS.md` — Swift naming, file organization

## Tasks

### FinanceCore

1. `RuleConditionField` enum:
   ```swift
   enum RuleConditionField: String, Codable, Sendable {
       case note              // Ghi chú giao dịch
       case amount            // Số tiền
       case category          // Danh mục hiện tại
       case account           // Tài khoản
       case dayOfWeek         // Thứ trong tuần (2-8, CN=1)
       case timeOfDay         // Giờ trong ngày (0-23)
       case dayOfMonth        // Ngày trong tháng (1-31)
       case transactionType   // income/expense/transfer
       case merchantName      // Tên merchant (extracted from note)
   }
   ```

2. `RuleConditionOperator` enum:
   ```swift
   enum RuleConditionOperator: String, Codable, Sendable {
       case equals            // Bằng
       case notEquals         // Không bằng
       case contains          // Chứa (text)
       case notContains       // Không chứa
       case matchesRegex      // Khớp regex (VD: "Grab.*")
       case greaterThan       // Lớn hơn (amount)
       case lessThan          // Nhỏ hơn
       case between           // Trong khoảng
       case isAny             // Thuộc danh sách
   }
   ```

3. `RuleCondition` model:
   - id: UUID
   - field: RuleConditionField
   - operator: RuleConditionOperator
   - value: String — giá trị so sánh (serialized)
   - secondaryValue: String? — cho operator `between` (VD: amount between 100k AND 500k)

4. `RuleActionType` enum:
   ```swift
   enum RuleActionType: String, Codable, Sendable {
       case setCategory       // Đặt danh mục
       case addTag            // Thêm tag
       case removeTag         // Xóa tag
       case setNote           // Ghi đè / append ghi chú
       case flagTransaction   // Đánh dấu "cần review"
       case sendNotification  // Gửi notification
       case autoApprove       // Tự động approve (cho recurring)
   }
   ```

5. `RuleAction` model:
   - id: UUID
   - type: RuleActionType
   - value: String — giá trị action (categoryId, tagId, note text...)

6. `SmartRule` model:
   - id: UUID
   - name: String (VD: "Grab → Di chuyển", "Chi lớn → Thông báo")
   - conditions: [RuleCondition] — ALL conditions phải match (AND logic)
   - actions: [RuleAction] — tất cả actions thực thi khi match
   - isEnabled: Bool
   - priority: Int — thứ tự ưu tiên (rule priority cao chạy trước)
   - matchCount: Int — số lần rule đã match (stats)
   - lastMatchedAt: Date?
   - createdAt: Date
   - updatedAt: Date

7. Preset rules (VN context):
   ```
   - "Grab" → note contains "Grab" → category = Di chuyển/Grab
   - "Café" → note matches "(?i)(highland|phúc long|starbucks|café|coffee|trà sữa)" → category = Ăn uống/Café
   - "Chi lớn" → amount > 5.000.000₫ → tag "Chi lớn" + notification
   - "Weekend" → dayOfWeek IN [7, 1] AND category = Ăn ngoài → tag "Weekend treats"
   - "Siêu thị" → note matches "(?i)(coopmart|vinmart|bách hóa xanh|lotte|mega market)" → category = Ăn uống/Đi chợ
   - "Xăng" → note matches "(?i)(xăng|petrolimex|pvoil)" → category = Di chuyển/Xăng
   ```

8. `EvaluateRulesUseCase`:
   - Input: Transaction (mới tạo hoặc mới import)
   - Process: iterate rules theo priority, match conditions
   - Output: list of actions to apply
   - Áp dụng actions lên transaction
   - Update matchCount, lastMatchedAt

9. `CreateSmartRuleUseCase`:
   - Validate: ít nhất 1 condition + 1 action
   - Validate regex syntax nếu operator = matchesRegex
   - Set priority mặc định = max existing + 1

10. `BankTemplate` model:
    ```swift
    struct BankTemplate: Codable, Sendable, Identifiable {
        let id: String              // VD: "vietcombank_csv"
        let bankName: String        // "Vietcombank"
        let bankCode: String        // "VCB" — mã NAPAS
        let format: ImportFormat    // csv, ofx, excel
        let encoding: String        // "UTF-8" hoặc "Windows-1252"
        let dateFormat: String      // "dd/MM/yyyy"
        let decimalSeparator: String // "," hoặc "."
        let columnMapping: BankColumnMapping
        let skipHeaderRows: Int     // Số hàng header cần bỏ qua
        let notes: String?          // Hướng dẫn export từ bank
    }
    ```

11. `ImportFormat` enum:
    ```swift
    enum ImportFormat: String, Codable, Sendable {
        case csv
        case ofx       // Open Financial Exchange
        case excel     // .xlsx
        case pdf       // Sao kê PDF (OCR)
    }
    ```

12. `BankColumnMapping` model:
    ```swift
    struct BankColumnMapping: Codable, Sendable {
        var dateColumn: Int         // Index cột ngày giao dịch
        var descriptionColumn: Int  // Index cột mô tả
        var amountColumn: Int?      // Cột số tiền (nếu 1 cột +/-)
        var debitColumn: Int?       // Cột ghi nợ (chi)
        var creditColumn: Int?      // Cột ghi có (thu)
        var balanceColumn: Int?     // Cột số dư
        var referenceColumn: Int?   // Cột số tham chiếu (dùng cho duplicate detection)
    }
    ```

13. Vietnamese bank templates (built-in):
    ```
    Vietcombank (VCB):
      - CSV: UTF-8, date="dd/MM/yyyy", skip=1, cols: [0=date, 1=ref, 2=debit, 3=credit, 4=balance, 5=desc]

    Techcombank (TCB):
      - CSV: UTF-8, date="dd/MM/yyyy HH:mm:ss", skip=2, cols: [0=date, 1=desc, 2=debit, 3=credit, 4=balance]

    BIDV:
      - CSV: Windows-1252, date="dd/MM/yyyy", skip=1, cols: [0=date, 1=ref, 2=desc, 3=debit, 4=credit, 5=balance]

    VPBank:
      - CSV: UTF-8, date="dd-MM-yyyy", skip=1, cols: [0=date, 1=desc, 2=debit, 3=credit]

    MBBank:
      - CSV: UTF-8, date="dd/MM/yyyy", skip=1, cols: [0=date, 1=ref, 2=desc, 3=amount, 4=balance]

    ACB:
      - CSV: UTF-8, date="dd/MM/yyyy", skip=1, cols: [0=date, 1=desc, 2=debit, 3=credit, 4=balance]

    TPBank:
      - CSV: UTF-8, date="dd/MM/yyyy", skip=2, cols: [0=date, 1=ref, 2=desc, 3=debit, 4=credit]
    ```

14. `ImportedTransaction` model (intermediate — trước khi save):
    - sourceRow: Int — hàng trong file gốc
    - date: Date
    - description: String
    - amount: Decimal
    - type: TransactionType (income/expense, inferred from debit/credit)
    - referenceNumber: String? — số tham chiếu bank
    - suggestedCategory: Category? — AI/rules suggested
    - isDuplicate: Bool — trùng với transaction đã có
    - duplicateOf: UUID? — ID transaction trùng
    - isSelected: Bool — user chọn import hay skip

15. `ImportBankStatementUseCase`:
    - Input: file URL, BankTemplate (hoặc auto-detect)
    - Parse file theo template mapping
    - Detect encoding (UTF-8 / Windows-1252)
    - Return [ImportedTransaction] cho user review

16. `DetectDuplicatesUseCase`:
    - So sánh imported transactions với existing:
      - Match 1: cùng referenceNumber → chắc chắn trùng
      - Match 2: cùng date + cùng amount + note tương tự → khả năng cao trùng
      - Match 3: cùng date + cùng amount → có thể trùng (flag to review)
    - Output: đánh dấu isDuplicate + duplicateOf trên ImportedTransaction

17. `AutoDetectBankUseCase`:
    - Input: first 5 rows of file
    - Heuristic: match column count, header text, date format
    - Output: BankTemplate? (nil nếu không detect được → user chọn manual)

18. `ConfirmImportUseCase`:
    - Input: [ImportedTransaction] đã review (isSelected = true)
    - Batch insert vào Transaction table
    - Chạy EvaluateRulesUseCase cho mỗi transaction
    - Update account balances
    - Return: ImportResult (imported: Int, skipped: Int, duplicates: Int)

19. `RoundUpType` enum:
    ```swift
    enum RoundUpType: String, Codable, Sendable {
        case nearest1K      // Làm tròn lên 1.000₫ gần nhất
        case nearest5K      // Làm tròn lên 5.000₫
        case nearest10K     // Làm tròn lên 10.000₫
        case nearest50K     // Làm tròn lên 50.000₫
        case nearest100K    // Làm tròn lên 100.000₫
    }
    ```

20. `AutoSavingsRuleType` enum:
    ```swift
    enum AutoSavingsRuleType: String, Codable, Sendable {
        case roundUp        // Làm tròn lên → phần dư vào savings
        case fixedAmount    // Số tiền cố định theo lịch
        case percentage     // % từ mỗi income
        case challenge52w   // 52-week challenge (tuần 1: 10k, tuần 2: 20k...)
        case dailyChallenge // Tiết kiệm mỗi ngày tăng dần
    }
    ```

21. `AutoSavingsRule` model:
    - id: UUID
    - name: String (VD: "Làm tròn tiết kiệm", "10% lương")
    - type: AutoSavingsRuleType
    - targetGoal: Goal — goal nhận tiền tiết kiệm
    - isEnabled: Bool
    - config: AutoSavingsConfig (varies by type)
    - totalSaved: Decimal — tổng đã tiết kiệm từ rule này
    - lastTriggeredAt: Date?
    - createdAt: Date
    - updatedAt: Date

22. `AutoSavingsConfig` enum (associated values):
    ```swift
    enum AutoSavingsConfig: Codable, Sendable {
        case roundUp(type: RoundUpType, minRoundUp: Decimal?)
            // minRoundUp: chỉ round up nếu phần dư >= minRoundUp (tránh save 100₫)
        case fixedAmount(amount: Decimal, frequency: RecurringFrequency)
            // VD: 50.000₫ mỗi ngày
        case percentage(percent: Decimal, ofType: TransactionType)
            // VD: 10% của mỗi income
        case challenge52w(baseAmount: Decimal, increment: Decimal)
            // VD: base 10.000₫, increment 10.000₫ → tuần 1: 10k, tuần 2: 20k...
        case dailyChallenge(startAmount: Decimal, increment: Decimal, maxAmount: Decimal?)
    }
    ```

23. `ProcessRoundUpUseCase`:
    - Trigger: sau mỗi expense transaction
    - Tính round-up amount (VD: chi 47.000₫, round to 50.000₫ → save 3.000₫)
    - Allocate vào target Goal
    - Tạo internal transfer record (tracking only, không phải chuyển tiền thật)
    - LƯU Ý: Đây chỉ là tracking/allocation trong app, KHÔNG access bank account

24. `ProcessIncomePercentageUseCase`:
    - Trigger: khi có income transaction mới
    - Tính percentage amount
    - Allocate vào target Goal

25. `Process52WeekChallengeUseCase`:
    - Trigger: mỗi tuần (weekly check)
    - Tính tuần hiện tại → amount = base + (weekNumber - 1) × increment
    - Nhắc nhở user "Tuần 15: Tiết kiệm 150.000₫!"
    - Track completion

26. `GetAutoSavingsSummaryUseCase`:
    - Tổng đã tiết kiệm từ tất cả rules
    - Breakdown theo từng rule
    - Progress toward goal

### FinanceData

27. `SmartRuleEntity` @Model:
    - Indexes: (isEnabled, priority)
    - Relationship: conditions → [RuleConditionEntity], actions → [RuleActionEntity]

28. `RuleConditionEntity` @Model
29. `RuleActionEntity` @Model

30. `SmartRuleRepositoryImpl`:
    - CRUD rules
    - getEnabledRules(sortedByPriority:)
    - incrementMatchCount(ruleId:)

31. `ImportSessionEntity` @Model — lưu lại lịch sử import:
    - id: UUID, fileName: String, bankTemplate: String
    - importedCount: Int, skippedCount: Int, duplicateCount: Int
    - importedAt: Date

32. `ImportSessionRepositoryImpl`:
    - saveSession, getImportHistory

33. `AutoSavingsRuleEntity` @Model:
    - Indexes: (isEnabled), (targetGoalId)

34. `AutoSavingsRepositoryImpl`:
    - CRUD rules
    - getEnabledRules
    - updateTotalSaved(ruleId:, amount:)

### FinanceUI

35. `RuleConditionRow` — hiển thị 1 condition: [Field] [Operator] [Value] với pickers
36. `RuleActionRow` — hiển thị 1 action: [ActionType] [Value]
37. `RuleBuilderView` — visual WHEN → IF → THEN builder, drag-to-reorder conditions
38. `RulePresetCard` — card cho preset rules (Grab, Café, Chi lớn...) với 1-tap enable
39. `ImportPreviewTable` — table hiển thị imported transactions, highlight duplicates (vàng), toggleable selection
40. `BankPickerGrid` — grid chọn bank với logo: VCB, TCB, BIDV, VPBank, MBBank, ACB, TPBank
41. `ColumnMappingView` — drag columns từ file CSV vào fields (date, amount, description...)
42. `RoundUpVisualizer` — animation hiển thị "47.000₫ → 50.000₫, tiết kiệm 3.000₫"
43. `SavingsChallengeProgress` — 52-week grid/calendar view, đánh dấu tuần đã hoàn thành
44. `AutoSavingsRuleCard` — card hiển thị rule + tổng đã tiết kiệm + toggle on/off

### iOS

45. `SmartRulesListView`:
    - Danh sách rules, toggle enable/disable
    - Section: "Rules của bạn" + "Gợi ý" (presets chưa enable)
    - Swipe-to-delete
    - Stats: "X rules đã khớp Y giao dịch"

46. `SmartRulesListViewModel`:
    - @Observable, inject SmartRuleRepository
    - rules: [SmartRule], presetRules: [SmartRule]
    - Toggle, delete, reorder priority

47. `CreateSmartRuleView`:
    - Rule name input
    - Add conditions (+ button, picker cho field/operator/value)
    - Add actions (+ button)
    - Preview: "Khi ghi chú chứa 'Grab' → Đặt danh mục Di chuyển/Grab"
    - Test rule: chạy thử trên 10 giao dịch gần nhất → show matches

48. `BankImportView`:
    - Step 1: Chọn bank (grid) hoặc "Tải file" (document picker)
    - Step 2: Hướng dẫn export từ bank (screenshot/text guide cho mỗi bank VN)
    - Step 3: Chọn file (CSV/OFX) từ Files app
    - Step 4: Preview imported transactions (table)
    - Step 5: Review duplicates (highlighted), toggle select/deselect
    - Step 6: Confirm import → progress bar → result summary

49. `BankImportViewModel`:
    - @Observable
    - selectedBank: BankTemplate?
    - importedTransactions: [ImportedTransaction]
    - importResult: ImportResult?
    - Handle file parsing, duplicate detection, confirm import

50. `ColumnMappingSheet`:
    - Hiển thị khi bank không có template hoặc auto-detect fail
    - Preview 3-5 rows đầu tiên
    - Cho user map: cột nào = date, amount, description...
    - Save mapping cho lần sau

51. `AutoSavingsListView`:
    - Danh sách auto-savings rules
    - Summary card: "Tổng đã tiết kiệm: 2.450.000₫"
    - Per-goal breakdown
    - Toggle rules on/off

52. `CreateAutoSavingsRuleView`:
    - Chọn type: Round-up | Số tiền cố định | % thu nhập | 52-week Challenge
    - Config tùy theo type:
      - Round-up: chọn mức (1K/5K/10K/50K/100K)
      - Fixed: nhập amount + frequency
      - Percentage: nhập %, chọn áp dụng cho income nào
      - 52-week: nhập base amount
    - Chọn Goal đích
    - Preview: "Ước tính tiết kiệm X/tháng, Y/năm"

53. `AutoSavingsViewModel`:
    - @Observable
    - rules: [AutoSavingsRule]
    - totalSaved: Decimal
    - monthlySavingsEstimate: Decimal

### macOS

54. `SmartRulesTableView`:
    - Table: Priority | Name | Conditions | Actions | Matches | Enabled
    - Sortable columns
    - Drag-to-reorder priority
    - Double-click → edit rule

55. `BankImportWindow`:
    - Drag-and-drop file vào window
    - Split view: file preview (left) | mapping + preview (right)
    - Keyboard shortcut ⌘I → open import

56. `AutoSavingsDashboardView`:
    - Overview card: tổng tiết kiệm, breakdown theo rules
    - Chart: monthly auto-savings trend
    - Quick toggle rules

57. `macOS Keyboard shortcuts`:
    - ⌘R → Smart Rules list
    - ⌘I → Bank Import
    - ⌘⇧R → Create new rule

### Tests

58. RuleCondition matching — text contains, regex, amount range, dayOfWeek
59. EvaluateRules — multiple rules with priority, first-match vs all-match
60. SmartRule presets — VN presets match expected transactions (Grab, Highland, CoopMart)
61. BankImport Vietcombank — parse CSV đúng format VCB, date/amount extraction
62. BankImport Techcombank — parse CSV format TCB, handle datetime format
63. BankImport BIDV — parse Windows-1252 encoding, handle Vietnamese characters
64. DuplicateDetection — exact match (reference), fuzzy match (date+amount), no false positive
65. AutoDetectBank — detect VCB/TCB/BIDV from header patterns
66. ColumnMapping — custom mapping works for unknown bank format
67. RoundUp calculation — 47.000 → 50.000 (save 3k), 150.000 → 150.000 (save 0), edge cases
68. PercentageSavings — 10% of 25.000.000₫ = 2.500.000₫, rounding VND
69. 52WeekChallenge — week 1=10k, week 52=520k, total = 13.780.000₫
70. AutoSavings toggle — disable rule stops future triggers, doesn't affect past
71. Import + Rules combo — imported transactions get rules applied automatically
