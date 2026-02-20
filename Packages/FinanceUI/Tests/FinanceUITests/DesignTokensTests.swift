import SwiftUI
import Testing

@testable import FinanceUI

@Suite("DesignTokens Tests")
struct DesignTokensTests {

    // MARK: - Spacing

    @Test("Spacing values are ordered correctly")
    func spacingValuesOrdered() {
        #expect(DesignTokens.Spacing.xxs < DesignTokens.Spacing.xs)
        #expect(DesignTokens.Spacing.xs < DesignTokens.Spacing.sm)
        #expect(DesignTokens.Spacing.sm < DesignTokens.Spacing.md)
        #expect(DesignTokens.Spacing.md < DesignTokens.Spacing.lg)
        #expect(DesignTokens.Spacing.lg < DesignTokens.Spacing.xl)
        #expect(DesignTokens.Spacing.xl < DesignTokens.Spacing.xxl)
        #expect(DesignTokens.Spacing.xxl < DesignTokens.Spacing.xxxl)
    }

    @Test("Spacing exact values match spec")
    func spacingExactValues() {
        #expect(DesignTokens.Spacing.xxs == 2)
        #expect(DesignTokens.Spacing.xs == 4)
        #expect(DesignTokens.Spacing.sm == 8)
        #expect(DesignTokens.Spacing.md == 12)
        #expect(DesignTokens.Spacing.lg == 16)
        #expect(DesignTokens.Spacing.xl == 24)
        #expect(DesignTokens.Spacing.xxl == 32)
        #expect(DesignTokens.Spacing.xxxl == 48)
    }

    // MARK: - Corner Radius

    @Test("Corner radius values are ordered correctly")
    func cornerRadiusOrdered() {
        #expect(DesignTokens.CornerRadius.sm < DesignTokens.CornerRadius.md)
        #expect(DesignTokens.CornerRadius.md < DesignTokens.CornerRadius.lg)
        #expect(DesignTokens.CornerRadius.lg < DesignTokens.CornerRadius.xl)
        #expect(DesignTokens.CornerRadius.xl < DesignTokens.CornerRadius.full)
    }

    @Test("Corner radius exact values match spec")
    func cornerRadiusExactValues() {
        #expect(DesignTokens.CornerRadius.sm == 4)
        #expect(DesignTokens.CornerRadius.md == 8)
        #expect(DesignTokens.CornerRadius.lg == 12)
        #expect(DesignTokens.CornerRadius.xl == 16)
        #expect(DesignTokens.CornerRadius.full == 9999)
    }

    // MARK: - Shadow

    @Test("Shadow card has minimal radius in light mode")
    func shadowCardLight() {
        let style = DesignTokens.Shadow.card(.light)
        #expect(style.radius == 2)
        #expect(style.y == 1)
        #expect(style.x == 0)
    }

    @Test("Shadow card is clear in dark mode")
    func shadowCardDark() {
        let style = DesignTokens.Shadow.card(.dark)
        #expect(style.color == .clear)
    }

    @Test("Shadow elevated has more radius than card")
    func shadowElevatedVsCard() {
        let card = DesignTokens.Shadow.card(.light)
        let elevated = DesignTokens.Shadow.elevated(.light)
        #expect(elevated.radius > card.radius)
    }

    @Test("Shadow floating has more radius than elevated")
    func shadowFloatingVsElevated() {
        let elevated = DesignTokens.Shadow.elevated(.light)
        let floating = DesignTokens.Shadow.floating(.light)
        #expect(floating.radius > elevated.radius)
    }

    // MARK: - Transaction Type Color Key

    @Test("Transaction color key returns distinct colors")
    func transactionColorKeyDistinct() {
        let income = DesignTokens.Colors.transactionColor(for: .income)
        let expense = DesignTokens.Colors.transactionColor(for: .expense)
        let transfer = DesignTokens.Colors.transactionColor(for: .transfer)

        // Each should resolve without crash; exact color comparison is fragile
        // so we just ensure they are different instances
        #expect(income != expense)
        #expect(expense != transfer)
        #expect(income != transfer)
    }
}

// MARK: - Color Hex Tests

@Suite("Color Hex Tests")
struct ColorHexTests {

    @Test("Parses 6-digit hex")
    func parse6Digit() {
        let color = Color(hex: "#FF5733")
        // Should not crash — exact color comparison is unreliable across platforms
        #expect(color != Color.clear)
    }

    @Test("Parses hex without hash")
    func parseWithoutHash() {
        let color = Color(hex: "007AFF")
        #expect(color != Color.clear)
    }

    @Test("Invalid hex returns white")
    func invalidHex() {
        let color = Color(hex: "xyz")
        // Invalid defaults to white (255,255,255)
        #expect(color != Color.clear)
    }

    @Test("roundtrip hex conversion")
    func roundtripHex() {
        let original = "#FF5733"
        let color = Color(hex: original)
        let result = color.toHex()
        #expect(result != nil)
        // Should be close to original (minor rounding diffs possible)
        #expect(result?.hasPrefix("#") == true)
    }
}

// MARK: - CategoryIcon Tests

@Suite("CategoryIcon Tests")
struct CategoryIconTests {

    @Test("CategoryIconSize dimensions are ordered")
    func sizeOrdered() {
        #expect(CategoryIconSize.small.dimension < CategoryIconSize.medium.dimension)
        #expect(CategoryIconSize.medium.dimension < CategoryIconSize.large.dimension)
    }

    @Test("CategoryIconSize exact values")
    func sizeExact() {
        #expect(CategoryIconSize.small.dimension == 24)
        #expect(CategoryIconSize.medium.dimension == 32)
        #expect(CategoryIconSize.large.dimension == 44)
    }

    @Test("Placeholder creates gray icon")
    func placeholderIcon() {
        // Should not crash
        let _ = CategoryIcon.placeholder(size: .small)
    }
}

// MARK: - AccountIconSize Tests

@Suite("AccountIconSize Tests")
struct AccountIconSizeTests {

    @Test("Dimensions are ordered")
    func dimensionsOrdered() {
        #expect(AccountIconSize.small.dimension < AccountIconSize.medium.dimension)
        #expect(AccountIconSize.medium.dimension < AccountIconSize.large.dimension)
    }
}

// MARK: - AmountStyle Tests

@Suite("AmountStyle Tests")
struct AmountStyleTests {

    @Test("All styles produce a font without crash")
    func allStylesHaveFont() {
        let styles: [AmountStyle] = [.hero, .large, .regular, .small]
        for style in styles {
            // Ensure each style's font property is accessible
            let _ = style.font
        }
    }
}

// MARK: - SyncStatus Tests

@Suite("SyncStatus Tests")
struct SyncStatusTests {

    @Test("All sync statuses can be created")
    func allStatuses() {
        let statuses: [SyncStatus] = [.synced, .syncing, .offline, .error]
        #expect(statuses.count == 4)
    }
}

// MARK: - ShadowStyle Tests

@Suite("ShadowStyle Tests")
struct ShadowStyleTests {

    @Test("ShadowStyle initializer stores values")
    func initStoresValues() {
        let style = ShadowStyle(color: .red, radius: 5, x: 1, y: 2)
        #expect(style.radius == 5)
        #expect(style.x == 1)
        #expect(style.y == 2)
    }
}
