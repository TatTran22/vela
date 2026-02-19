import Testing
import Foundation

@testable import FinanceCore

@Suite("CurrencyFormatter Tests")
struct CurrencyFormatterTests {
    @Test("Format VND amount")
    func formatVND() {
        let formatter = CurrencyFormatter(currencyCode: .VND)
        let result = formatter.format(1_500_000)
        #expect(result.contains("1.500.000") || result.contains("1,500,000"))
    }

    @Test("Format USD amount")
    func formatUSD() {
        let formatter = CurrencyFormatter(currencyCode: .USD)
        let result = formatter.format(1_500.50)
        #expect(result.contains("1,500.50"))
    }

    @Test("Format compact VND million")
    func formatCompactVNDMillion() {
        let formatter = CurrencyFormatter(currencyCode: .VND)
        let result = formatter.formatCompact(1_500_000)
        #expect(result.contains("1") && result.contains("tr"))
    }

    @Test("Format compact VND billion")
    func formatCompactVNDBillion() {
        let formatter = CurrencyFormatter(currencyCode: .VND)
        let result = formatter.formatCompact(1_500_000_000)
        #expect(result.contains("1") && result.contains("tỷ"))
    }

    @Test("Format compact USD million")
    func formatCompactUSDMillion() {
        let formatter = CurrencyFormatter(currencyCode: .USD)
        let result = formatter.formatCompact(1_500_000)
        #expect(result.contains("1") && result.contains("M"))
    }

    @Test("Format without symbol")
    func formatWithoutSymbol() {
        let formatter = CurrencyFormatter(currencyCode: .VND)
        let result = formatter.formatWithoutSymbol(1_500_000)
        #expect(result.contains("1.500.000") || result.contains("1,500,000"))
        #expect(!result.contains("₫"))
    }

    @Test("Format currency pair")
    func formatPair() {
        let formatter = CurrencyFormatter(currencyCode: .VND)
        let result = formatter.formatPair(amount: 1000, from: .USD, to: .VND, rate: 25000)
        #expect(result.contains("$"))
        #expect(result.contains("₫"))
        #expect(result.contains("≈"))
    }

    @Test("Backwards compatible string initializer")
    func backwardsCompatibleInit() {
        let formatter = CurrencyFormatter(currencyCodeString: "USD", locale: Locale(identifier: "en_US"))
        let result = formatter.format(100)
        #expect(result.contains("100"))
    }

    // MARK: - Additional Edge Cases

    @Test("Format zero amount")
    func formatZero() {
        let formatter = CurrencyFormatter(currencyCode: .VND)
        let result = formatter.format(0)
        #expect(result.contains("0"))
    }

    @Test("Format negative VND amount")
    func formatNegativeVND() {
        let formatter = CurrencyFormatter(currencyCode: .VND)
        let result = formatter.format(-1_500_000)
        #expect(result.contains("-") || result.contains("("))
        #expect(result.contains("1.500.000") || result.contains("1,500,000"))
    }

    @Test("Format negative USD amount")
    func formatNegativeUSD() {
        let formatter = CurrencyFormatter(currencyCode: .USD)
        let result = formatter.format(-1234.56)
        #expect(result.contains("-") || result.contains("("))
        #expect(result.contains("1,234.56"))
    }

    @Test("Format very large VND amount")
    func formatVeryLargeVND() {
        let formatter = CurrencyFormatter(currencyCode: .VND)
        let result = formatter.format(999_999_999_999)
        #expect(!result.isEmpty)
    }

    @Test("Format very large USD amount")
    func formatVeryLargeUSD() {
        let formatter = CurrencyFormatter(currencyCode: .USD)
        let result = formatter.format(999_999_999.99)
        #expect(!result.isEmpty)
        #expect(result.contains("999"))
    }

    @Test("Format compact VND zero")
    func formatCompactVNDZero() {
        let formatter = CurrencyFormatter(currencyCode: .VND)
        let result = formatter.formatCompact(0)
        #expect(result.contains("0"))
    }

    @Test("Format compact negative amount")
    func formatCompactNegative() {
        let formatter = CurrencyFormatter(currencyCode: .USD)
        let result = formatter.formatCompact(-1_500_000)
        #expect(result.contains("-") || result.contains("("))
    }

    @Test("Format VND with decimal places (should round)")
    func formatVNDWithDecimals() {
        let formatter = CurrencyFormatter(currencyCode: .VND)
        // VND has 0 decimal places, should round
        let result = formatter.format(1_500_000.99)
        #expect(!result.contains(".99"))
    }

    @Test("Format USD with precise decimal")
    func formatUSDWithPreciseDecimal() {
        let formatter = CurrencyFormatter(currencyCode: .USD)
        let result = formatter.format(1234.56)
        #expect(result.contains("1,234.56"))
    }

    @Test("Format small USD amount")
    func formatSmallUSD() {
        let formatter = CurrencyFormatter(currencyCode: .USD)
        let result = formatter.format(0.01)
        #expect(result.contains("0.01"))
    }

    @Test("Format EUR amount")
    func formatEUR() {
        let formatter = CurrencyFormatter(currencyCode: .EUR)
        let result = formatter.format(1234.56)
        #expect(!result.isEmpty)
        #expect(result.contains("1") && result.contains("234"))
    }
}
