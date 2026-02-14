# FinanceUI Module Context

## Purpose
Shared SwiftUI components and design system used by both iOS and macOS targets. Provides consistent visual language across platforms.

## Key Rules
- **Platform-adaptive** — components must work on both iOS and macOS
- **Accessibility first** — all components must support VoiceOver, Dynamic Type
- **No business logic** — only presentation, no data fetching or state mutation
- **Design tokens** — use centralized colors, fonts, spacing values

## Design Tokens
```swift
enum FinanceSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum FinanceCornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
}

extension Color {
    static let financeGreen = Color("IncomeGreen")    // Income, positive
    static let financeRed = Color("ExpenseRed")       // Expense, negative
    static let financeBlue = Color("PrimaryBlue")     // Primary accent
    static let financeGray = Color("NeutralGray")     // Neutral, transfers
}

extension Font {
    static let financeTitle = Font.system(.title2, weight: .bold)
    static let financeAmount = Font.system(.title3, weight: .semibold).monospacedDigit()
    static let financeBody = Font.system(.body)
    static let financeCaption = Font.system(.caption, weight: .medium)
}
```

## Component Pattern
```swift
/// All components follow this pattern:
/// 1. Clear, descriptive name
/// 2. Documented public API
/// 3. Preview with multiple states
/// 4. Accessibility labels

/// Displays a monetary amount with color based on transaction type.
struct AmountView: View {
    let amount: Decimal
    let type: TransactionType
    let style: AmountStyle

    var body: some View {
        Text(amount, format: .currency(code: currencyCode))
            .font(style.font)
            .foregroundStyle(type.color)
            .accessibilityLabel(accessibilityText)
    }
}

#Preview {
    VStack {
        AmountView(amount: 1_000_000, type: .income, style: .large)
        AmountView(amount: -500_000, type: .expense, style: .medium)
        AmountView(amount: 0, type: .transfer, style: .small)
    }
}
```

## Accessibility Requirements
- All interactive elements need `.accessibilityLabel()`
- Amount displays need `.accessibilityValue()` with full currency text
- Charts need `.accessibilityElement(children: .combine)` with summary
- Support `.accessibilityAction()` for custom VoiceOver actions
- Test with Accessibility Inspector

## Cross-Platform Adaptations
```swift
// Use ViewModifier for platform differences
struct PlatformCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(FinanceSpacing.md)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: FinanceCornerRadius.md))
            #if os(macOS)
            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            #endif
    }
}
```

## Testing
- Preview all components in light/dark mode
- Test Dynamic Type sizes (accessibility sizes included)
- Verify platform rendering on both iOS and macOS
- Run: `swift test --package-path Packages/FinanceUI`
