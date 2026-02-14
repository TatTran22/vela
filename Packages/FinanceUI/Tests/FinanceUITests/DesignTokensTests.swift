import Testing

@testable import FinanceUI

@Suite("DesignTokens Tests")
struct DesignTokensTests {
    @Test("Spacing values are ordered")
    func spacingValuesOrdered() {
        #expect(DesignTokens.Spacing.xs < DesignTokens.Spacing.sm)
        #expect(DesignTokens.Spacing.sm < DesignTokens.Spacing.md)
        #expect(DesignTokens.Spacing.md < DesignTokens.Spacing.lg)
        #expect(DesignTokens.Spacing.lg < DesignTokens.Spacing.xl)
    }
}
