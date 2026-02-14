# Coding Conventions

## Swift Style

### Naming
- **Types** (class, struct, enum, protocol): `PascalCase`
- **Properties, methods, variables**: `camelCase`
- **Constants**: `camelCase` (not SCREAMING_CASE)
- **Acronyms**: Treat as words (`urlString`, `httpResponse`, `userId`)
- **Protocol naming**: Noun cho capabilities (`Repository`, `Service`), `-able/-ible` cho traits (`Sendable`)

### File Organization
- One main type per file
- File name matches type name: `TransactionListView.swift`
- Group by feature, not by file type
- Feature folder structure: View, ViewModel, Models (if needed)

### Access Control
- Default to `internal` (implicit)
- Use `private` for implementation details
- Use `public` only for module API boundaries
- Use `private(set)` for read-only external access

### Error Handling
- Use `throws` or `Result` — never optionals to hide errors
- Define domain-specific error types
- No empty `catch` blocks
- No force unwraps (`!`) except `IBOutlet`

### Concurrency
- Use `async/await` for asynchronous operations
- Use actors for shared mutable state
- All models must be `Sendable`
- No `DispatchQueue` unless interfacing with legacy code

### Documentation
- Tất cả public APIs phải có `///` doc comments
- Include parameter descriptions cho methods phức tạp
- Include usage examples cho utility functions

---

## Architecture Rules

### Views
- No business logic in views
- Only binding to ViewModel properties
- Use environment values for dependency injection where appropriate
- Sử dụng semantic colors từ Design System (không hard-code colors)
- Support Dynamic Type, VoiceOver, Reduce Motion

### ViewModels
- Annotated with `@Observable`
- Dependencies injected via `init`
- Expose state as published properties
- Methods for user actions
- Không import UIKit/AppKit — chỉ Foundation + FinanceCore

### Use Cases
- Protocol + implementation pair
- Single responsibility
- Pure business logic, no UI or data layer imports
- Defined in FinanceCore package

### Repositories
- Protocol-based abstraction (defined in FinanceCore)
- Implementation in FinanceData package
- All operations are `async throws`
- Không expose SwiftData/CoreData types ra ngoài module

---

## Currency & Number Formatting

### VND Rules
- Không hiện decimal places (VND không có xu)
- Dấu chấm phân cách hàng nghìn: `1.000.000 ₫`
- Symbol suffix: `₫` sau số
- Quick input shortcuts: `k` = ×1.000, `tr` = ×1.000.000
  - `150k` → `150.000₫`
  - `1.5tr` → `1.500.000₫`
- Hiển thị gọn khi cần: `1,5tr` thay vì `1.500.000`
- Bàn phím số tùy chỉnh hỗ trợ phép tính nhanh: `150k + 200k`

### Other Currencies
- Sử dụng `NumberFormatter` / `Decimal.FormatStyle` với locale tương ứng
- USD: `$1,234.56`, EUR: `€1.234,56`, JPY: `¥1,234`
- Luôn dùng `Decimal` cho monetary values — KHÔNG BAO GIỜ dùng `Double`

### Multi-Currency Display
- Hiển thị song song: giá trị gốc + quy đổi về đồng tiền chính
- VD: `$100.00 (≈ 2.500.000₫)`

---

## Localization

### String Management
- Sử dụng String Catalogs (`.xcstrings`)
- Key naming: `feature.context.element` (VD: `transaction.input.amountPlaceholder`)
- Không hard-code user-facing strings

### Supported Languages
| Language | Priority | Scope |
|----------|----------|-------|
| Tiếng Việt (`vi`) | P0 | Full app |
| English (`en`) | P0 | Full app |
| 日本語 (`ja`) | P2 | Basic UI |
| 한국어 (`ko`) | P2 | Basic UI |

### Category Localization
- System categories có `localizedNames` dictionary
- UI hiển thị theo locale hiện tại
- Custom categories: tên do user nhập, không localize

---

## Testing Conventions

### Unit Tests
- Test file naming: `{TypeName}Tests.swift`
- Use `@Test` attribute (Swift Testing framework)
- Arrange-Act-Assert pattern
- Mock repositories via protocols
- Test business logic trong FinanceCore package

### Test Coverage Targets
| Module | Target |
|--------|--------|
| FinanceCore (Models, Use Cases) | ≥ 90% |
| FinanceData (Repositories) | ≥ 80% |
| FinanceUI (Components) | ≥ 70% |
| App targets | ≥ 60% |

### Naming Convention
```swift
@Test func fetchTransactions_withDateFilter_returnsFilteredResults() { }
@Test func saveTransaction_withInvalidAmount_throwsValidationError() { }
```

### What to Test
- Business logic và calculations (đặc biệt monetary)
- Data transformations và formatting
- Edge cases: zero amounts, max values, empty states
- VND-specific formatting
- Cross-currency conversions

---

## Accessibility

- Tất cả interactive elements phải có accessibility labels
- VoiceOver: amount đọc đúng format ("một trăm năm mươi nghìn đồng")
- Dynamic Type: support tất cả text sizes
- Color contrast ≥ 4.5:1
- Income/Expense không chỉ phân biệt bằng màu — thêm icon indicators
- Reduce Motion: tắt animations phức tạp
- Bold Text support
- Switch Control compatible

---

## Performance Guidelines

- App launch → interactive: < 1 giây
- Transaction save: < 100ms
- List render 100+ items: sử dụng `LazyVStack` / `List`
- Image (receipts): lazy loading + thumbnail
- Search: debounce 300ms, kết quả < 200ms cho 10K transactions
- AI categorization: < 50ms (on-device)
- Background tasks: dùng `BGTaskScheduler` cho sync/update rates

---

## Git Conventions

### Branch Naming
- `feature/short-description`
- `fix/short-description`
- `refactor/short-description`
- `chore/short-description`

### Commit Messages
Follow conventional commits format:
- `feat: add transaction list view`
- `fix: correct currency formatting for VND`
- `refactor: extract amount formatting logic`
- `test: add unit tests for budget calculations`
- `docs: update architecture documentation`
- `chore: update dependencies`

### PR Requirements
- Description rõ ràng
- Link issue liên quan
- Tests pass
- No SwiftLint warnings
- Screenshot cho UI changes

---

## Security Rules

- API keys LUÔN lưu trong Keychain, KHÔNG hard-code
- Biometric auth (Face ID/Touch ID) + passcode fallback
- Auto-lock timeout: configurable (1/5/15 phút)
- KHÔNG log sensitive data (amounts, account names) ở production
- TLS 1.3 + certificate pinning cho API calls
- Data at rest: SQLCipher encryption
- AI cloud: chỉ gửi aggregated data, KHÔNG gửi PII
- Export data: yêu cầu biometric auth trước khi export
