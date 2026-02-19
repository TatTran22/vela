import Testing
import Foundation

@testable import FinanceCore

// MARK: - T24: QuickAmountParser Tests

@Suite("QuickAmountParser Tests")
struct QuickAmountParserTests {
    private let parser = QuickAmountParser()

    // MARK: - Plain Numbers

    @Test("Plain integer parses correctly")
    func plainNumber() throws {
        #expect(try parser.parse("150000") == 150_000)
    }

    @Test("Plain decimal parses correctly")
    func plainDecimal() throws {
        #expect(try parser.parse("99.5") == Decimal(string: "99.5"))
    }

    @Test("Single digit parses correctly")
    func singleDigit() throws {
        #expect(try parser.parse("5") == 5)
    }

    @Test("Zero parses correctly")
    func plainZero() throws {
        #expect(try parser.parse("0") == 0)
    }

    // MARK: - k Suffix (×1,000)

    @Test("k suffix multiplies by 1000")
    func kSuffix() throws {
        #expect(try parser.parse("150k") == 150_000)
    }

    @Test("k suffix with decimal base")
    func kSuffixDecimal() throws {
        #expect(try parser.parse("1.5k") == 1_500)
    }

    @Test("k suffix with space between number and suffix")
    func kSuffixWithSpace() throws {
        #expect(try parser.parse("150 k") == 150_000)
    }

    @Test("K suffix (uppercase) multiplies by 1000")
    func kSuffixUppercase() throws {
        #expect(try parser.parse("200K") == 200_000)
    }

    @Test("0k parses to zero")
    func zeroK() throws {
        #expect(try parser.parse("0k") == 0)
    }

    // MARK: - tr Suffix (×1,000,000)

    @Test("tr suffix multiplies by 1000000")
    func trSuffix() throws {
        #expect(try parser.parse("1tr") == 1_000_000)
    }

    @Test("tr suffix with decimal base")
    func trSuffixDecimal() throws {
        #expect(try parser.parse("1.5tr") == 1_500_000)
    }

    @Test("tr suffix with space between number and suffix")
    func trSuffixWithSpace() throws {
        #expect(try parser.parse("2 tr") == 2_000_000)
    }

    // MARK: - m Suffix (×1,000,000)

    @Test("m suffix multiplies by 1000000")
    func mSuffix() throws {
        #expect(try parser.parse("2m") == 2_000_000)
    }

    @Test("m suffix with decimal base")
    func mSuffixDecimal() throws {
        #expect(try parser.parse("1.5m") == 1_500_000)
    }

    @Test("M suffix (uppercase) multiplies by 1000000")
    func mSuffixUppercase() throws {
        #expect(try parser.parse("3M") == 3_000_000)
    }

    // MARK: - Expressions: Addition

    @Test("Addition of two k-suffixed values")
    func additionKSuffix() throws {
        #expect(try parser.parse("150k + 200k") == 350_000)
    }

    @Test("Addition of plain numbers")
    func additionPlainNumbers() throws {
        #expect(try parser.parse("100 + 200") == 300)
    }

    @Test("Addition with mixed suffixes")
    func additionMixedSuffixes() throws {
        #expect(try parser.parse("1tr + 500k") == 1_500_000)
    }

    // MARK: - Expressions: Subtraction

    @Test("Subtraction of two k-suffixed values")
    func subtractionKSuffix() throws {
        #expect(try parser.parse("1tr - 200k") == 800_000)
    }

    @Test("Subtraction resulting in zero")
    func subtractionResultZero() throws {
        #expect(try parser.parse("100k - 100k") == 0)
    }

    // MARK: - Expressions: Multiplication

    @Test("Multiplication of k-suffixed value by plain number")
    func multiplicationKSuffix() throws {
        #expect(try parser.parse("50k * 3") == 150_000)
    }

    @Test("Multiplication of plain numbers")
    func multiplicationPlainNumbers() throws {
        #expect(try parser.parse("100 * 5") == 500)
    }

    // MARK: - Complex Multi-Operator Expressions

    @Test("Complex expression evaluated left-to-right")
    func complexExpression() throws {
        // Left-to-right: (100k + 50k) * 2 = 300k
        #expect(try parser.parse("100k + 50k * 2") == 300_000)
    }

    @Test("Three operands are evaluated left-to-right")
    func threeOperands() throws {
        // Left-to-right: (1tr - 200k) + 50k = 850k
        #expect(try parser.parse("1tr - 200k + 50k") == 850_000)
    }

    // MARK: - Whitespace Handling

    @Test("Leading and trailing whitespace is trimmed")
    func leadingTrailingWhitespace() throws {
        #expect(try parser.parse("  150k  ") == 150_000)
    }

    @Test("Whitespace around operator is handled")
    func whitespaceAroundOperator() throws {
        #expect(try parser.parse("100k   +   50k") == 150_000)
    }

    // MARK: - Edge Cases: Error Paths

    @Test("Empty string throws invalidExpression")
    func emptyStringThrows() {
        #expect(throws: TransactionError.invalidExpression("")) {
            try parser.parse("")
        }
    }

    @Test("Whitespace-only string throws invalidExpression")
    func whitespaceOnlyThrows() {
        #expect(throws: TransactionError.self) {
            try parser.parse("   ")
        }
    }

    @Test("Alphabetic-only input throws invalidExpression")
    func invalidAlphabeticInputThrows() {
        #expect(throws: TransactionError.invalidExpression("abc")) {
            try parser.parse("abc")
        }
    }

    @Test("Subtraction that produces negative result throws invalidExpression")
    func negativeResultThrows() {
        #expect(throws: TransactionError.invalidExpression("100k - 200k")) {
            try parser.parse("100k - 200k")
        }
    }

    @Test("Expression with trailing operator throws invalidExpression")
    func trailingOperatorThrows() {
        #expect(throws: TransactionError.self) {
            try parser.parse("100k +")
        }
    }

    @Test("Purely alphabetic token (no numeric prefix) throws invalidExpression")
    func purelyAlphabeticThrows() {
        // Tokens with no numeric prefix at all, such as "xyz", cannot be converted
        // to a Decimal and therefore throw invalidExpression.
        #expect(throws: TransactionError.self) {
            try parser.parse("xyz")
        }
    }
}
