import Testing

@testable import FinanceCore

@Suite("CurrencyFormatter Tests")
struct CurrencyFormatterTests {
    @Test("Format VND amount")
    func formatVND() {
        let formatter = CurrencyFormatter(currencyCode: "VND")
        let result = formatter.format(1_500_000)
        #expect(result.contains("1.500.000") || result.contains("1,500,000"))
    }
}
