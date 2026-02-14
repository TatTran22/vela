---
description: "Triển khai Localization — Vietnamese (primary) + English, String Catalogs, locale-aware formatting"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: Localization

## Đọc Context Trước
1. `CLAUDE.md`
2. `docs/DESIGN-SYSTEM.md`
3. `docs/CONVENTIONS.md`

## Tasks

### String Catalogs Setup
1. Create `Localizable.xcstrings` in both iOS and macOS targets
2. Supported languages: Vietnamese (vi) — primary, English (en)
3. Use String Catalogs (Xcode 15+) for all user-facing strings
4. Key naming convention: `feature.screen.element`
   - Example: `dashboard.balance.title`, `transaction.input.amount`

### FinanceCore Localization
5. Category default names — locale-aware:
   - vi: "Ăn uống", "Nhà ở", "Di chuyển", etc.
   - en: "Food & Drink", "Housing", "Transportation", etc.
6. Currency display names:
   - vi: "Đồng Việt Nam", "Đô la Mỹ"
   - en: "Vietnamese Dong", "US Dollar"
7. Error messages — localized
8. Date formatting:
   - vi: "Thứ Hai, 10/02/2026", "Hôm nay", "Hôm qua"
   - en: "Monday, Feb 10, 2026", "Today", "Yesterday"

### Number & Currency Formatting
9. `LocaleFormatter`:
   - VND: "1.000.000 ₫" (dot separator, no decimal, suffix ₫)
   - USD: "$1,000.00" (comma separator, 2 decimals, prefix $)
   - Compact: "1,5tr" (vi) / "1.5M" (en)
   - Respect system locale for number grouping

### UI Strings
10. All labels, buttons, placeholders, empty states — localized
11. Pluralization rules:
    - vi: no plural forms (simpler)
    - en: singular/plural ("1 transaction" / "5 transactions")
12. Accessibility labels — localized for VoiceOver
13. Widget display names — localized

### Date & Time
14. Relative dates: "Hôm nay", "Hôm qua", "3 ngày trước"
15. Month names: "Tháng 1" (vi) / "January" (en)
16. Week start: Monday (vi default)

### Testing
17. All strings have both vi and en translations
18. No hardcoded strings in Views (scan with SwiftLint rule)
19. Currency formatting matches locale expectations
20. Date formatting correct for both locales
21. RTL not needed (vi and en are both LTR)
