import Foundation

/// Parses VND shorthand amount expressions into `Decimal` values.
///
/// `QuickAmountParser` understands Vietnamese-style suffixes for large numbers
/// and supports simple arithmetic so users can enter amounts quickly on both
/// iOS and macOS without a separate calculator.
///
/// ## Supported suffixes
/// | Suffix | Multiplier | Example input | Result |
/// |--------|-----------|---------------|--------|
/// | `k`    | 1,000     | `150k`        | 150,000 |
/// | `tr`   | 1,000,000 | `1.5tr`       | 1,500,000 |
/// | `m`    | 1,000,000 | `2m`          | 2,000,000 |
///
/// Spaces between a number and its suffix are allowed (`150 k` → 150,000).
///
/// ## Supported operators
/// `+`, `-`, and `*` are evaluated left-to-right (no operator precedence).
///
/// ## Examples
/// ```swift
/// let parser = QuickAmountParser()
/// try parser.parse("150k")          // 150_000
/// try parser.parse("1.5tr")         // 1_500_000
/// try parser.parse("150k + 200k")   // 350_000
/// try parser.parse("1tr - 200k")    // 800_000
/// try parser.parse("50k * 3")       // 150_000
/// try parser.parse("150000")        // 150_000
/// try parser.parse("0k")            // 0
/// ```
public struct QuickAmountParser: Sendable {
    /// Creates a new `QuickAmountParser`.
    public init() {}

    /// Parses a VND shorthand expression and returns the resulting `Decimal` amount.
    ///
    /// Evaluation proceeds left-to-right. Operator precedence is not respected;
    /// `2 + 3 * 4` evaluates as `(2 + 3) * 4 = 20`, not `2 + 12 = 14`.
    ///
    /// - Parameter input: The expression string to parse.
    /// - Returns: The computed non-negative `Decimal` amount.
    /// - Throws: `TransactionError.invalidExpression` when the input is empty,
    ///   contains unrecognised characters, or results in a negative value.
    public func parse(_ input: String) throws -> Decimal {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw TransactionError.invalidExpression(input)
        }

        // Tokenise by splitting on operators while keeping the operators.
        // We walk character-by-character to preserve signs embedded in tokens.
        let tokens = try tokenise(trimmed, originalInput: input)

        guard !tokens.isEmpty else {
            throw TransactionError.invalidExpression(input)
        }

        // The first token must be a numeric value (possibly with a suffix).
        var result = try parseToken(tokens[0], originalInput: input)

        var index = 1
        while index < tokens.count {
            // Expect an operator token followed by a value token.
            guard index + 1 < tokens.count else {
                throw TransactionError.invalidExpression(input)
            }
            let operatorToken = tokens[index]
            let valueToken = tokens[index + 1]
            let value = try parseToken(valueToken, originalInput: input)

            switch operatorToken {
            case "+":
                result += value
            case "-":
                result -= value
            case "*":
                result *= value
            default:
                throw TransactionError.invalidExpression(input)
            }

            index += 2
        }

        guard result >= 0 else {
            throw TransactionError.invalidExpression(input)
        }

        return result
    }

    // MARK: - Private Helpers

    /// Splits the expression into alternating value/operator tokens.
    ///
    /// Operators recognised at the top level are `+`, `-`, and `*`.
    /// Whitespace surrounding operators is consumed.
    private func tokenise(_ expression: String, originalInput: String) throws -> [String] {
        var tokens: [String] = []
        var current = ""

        for char in expression {
            if char == "+" || char == "*" {
                let trimmedCurrent = current.trimmingCharacters(in: .whitespaces)
                guard !trimmedCurrent.isEmpty else {
                    throw TransactionError.invalidExpression(originalInput)
                }
                tokens.append(trimmedCurrent)
                tokens.append(String(char))
                current = ""
            } else if char == "-" {
                // A "-" is an operator only when `current` (stripped) is non-empty,
                // meaning a value token precedes it. Otherwise it might be a negative
                // number literal — which we reject as a negative result anyway.
                let trimmedCurrent = current.trimmingCharacters(in: .whitespaces)
                if !trimmedCurrent.isEmpty {
                    tokens.append(trimmedCurrent)
                    tokens.append("-")
                    current = ""
                } else {
                    // Accumulate as part of the current token (leading minus).
                    current.append(char)
                }
            } else {
                current.append(char)
            }
        }

        let trimmedCurrent = current.trimmingCharacters(in: .whitespaces)
        if !trimmedCurrent.isEmpty {
            tokens.append(trimmedCurrent)
        }

        return tokens
    }

    /// Converts a single value token (number + optional suffix) into a `Decimal`.
    ///
    /// Tokens may have leading/trailing whitespace; this is stripped before parsing.
    /// The suffix is matched case-insensitively and may be separated from the
    /// numeric part by a single space (e.g., `"150 k"`).
    private func parseToken(_ token: String, originalInput: String) throws -> Decimal {
        // Collapse internal whitespace between number and suffix (e.g., "150 k" → "150k").
        let collapsed = token
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "")

        guard !collapsed.isEmpty else {
            throw TransactionError.invalidExpression(originalInput)
        }

        // Attempt suffix match (longest suffix first to avoid "tr" matching before "t").
        let suffixes: [(suffix: String, multiplier: Decimal)] = [
            ("tr", 1_000_000),
            ("m",  1_000_000),
            ("k",  1_000),
        ]

        for (suffix, multiplier) in suffixes {
            let lower = collapsed.lowercased()
            if lower.hasSuffix(suffix) {
                let numericPart = String(collapsed.dropLast(suffix.count))
                guard let base = Decimal(string: numericPart), numericPart != "" else {
                    throw TransactionError.invalidExpression(originalInput)
                }
                return base * multiplier
            }
        }

        // No suffix: parse as a plain number.
        guard let value = Decimal(string: collapsed) else {
            throw TransactionError.invalidExpression(originalInput)
        }
        return value
    }
}
