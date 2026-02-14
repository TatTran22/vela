---
description: "Triển khai Design System — Colors, Typography, Spacing tokens + base components cho FinanceUI"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: Design System

## Đọc Context Trước
1. `CLAUDE.md`
2. `docs/DESIGN-SYSTEM.md`

## Tasks

### Tokens (Packages/FinanceUI/Sources/FinanceUI/Tokens/)
1. `FinanceColors`:
   - Primary, Secondary, Accent colors
   - Semantic: income (green), expense (red), transfer (blue)
   - Background: primary, secondary, grouped
   - Text: primary, secondary, tertiary
   - Status: success, warning, error, info
   - Dark mode variants (Color asset catalog or dynamic)
2. `FinanceTypography`:
   - largeTitle, title1, title2, title3
   - headline, body, callout, subheadline
   - footnote, caption1, caption2
   - Monospaced variant for amounts
   - Custom modifiers: `.financeTitle()`, `.financeBody()`
3. `FinanceSpacing`:
   - xxs: 2, xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32
   - Consistent padding/margin tokens
4. `FinanceRadius`:
   - small: 4, medium: 8, large: 12, pill: 999
5. `FinanceShadow`:
   - card, elevated, floating
   - Dark mode: subtle/none

### Base Components (Packages/FinanceUI/Sources/FinanceUI/Components/)
6. `AmountText`:
   - Display formatted amount with currency
   - Color-coded: income (green), expense (red), transfer (blue), neutral (primary)
   - Size variants: large (dashboard), medium (list), small (detail)
   - Monospaced digits for alignment
7. `CategoryIcon`:
   - SF Symbol in colored circle background
   - Size variants: small (24pt), medium (32pt), large (44pt)
   - Placeholder for unknown category
8. `AccountIcon`:
   - Type-based default icons (cash, bank, credit, ewallet, savings)
   - Custom icon override
   - EWallet provider logos (MoMo pink, ZaloPay blue, VNPay red)
9. `CardView`:
   - Rounded rectangle with shadow
   - Standard padding
   - Optional header + content layout
10. `EmptyStateView`:
    - Illustration/icon + title + subtitle + optional CTA button
    - Variants: no transactions, no accounts, no results
11. `LoadingView`:
    - Skeleton placeholder for lists
    - Progress indicator for operations
12. `BadgeView`:
    - Small colored pill with text
    - For tags, status, premium features
13. `SyncStatusIndicator`:
    - Synced ✓ (green), Syncing ↻ (blue animated), Offline ○ (gray)
14. `PremiumBadge`:
    - Lock icon + "Premium" for gated features
    - Tap → paywall

### Platform Adaptations
15. iOS-specific modifiers:
    - `.adaptiveSheet()` — sheet on iPhone, popover on iPad
    - `.hapticFeedback()` — success, warning, error
16. macOS-specific modifiers:
    - `.toolbarStyle()` — consistent toolbar appearance
    - `.keyboardShortcut()` helpers

### Tests
17. Snapshot tests for all components (light + dark mode)
18. Accessibility: all components have accessibility labels
19. Dynamic Type: components scale correctly
20. Color contrast: meets WCAG AA
