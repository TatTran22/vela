import FinanceCore
import SwiftUI

/// A custom numeric keypad for entering VND amounts with shorthand notation.
///
/// `QuickNumpad` provides a 4x4 grid keypad designed for fast monetary entry.
/// It accepts Vietnamese-style shorthands such as `k` (x1,000) and `tr` (x1,000,000),
/// and supports simple `+` and `-` arithmetic, which are evaluated using
/// `QuickAmountParser` from FinanceCore.
///
/// The expression the user types is stored in `expression` and the evaluated
/// result (if valid) is delivered via the `onCalculate` callback whenever the
/// expression changes. Tapping the done key invokes `onDone`.
///
/// Haptic feedback is triggered on every keypress on iOS. No feedback is
/// produced on macOS (UIKit is unavailable there).
///
/// Example usage:
/// ```swift
/// @State private var expression = ""
/// @State private var amount: Decimal = 0
///
/// QuickNumpad(expression: $expression) { result in
///     amount = result
/// } onDone: {
///     saveTransaction()
/// }
/// ```
public struct QuickNumpad: View {
    /// The raw expression string typed by the user (e.g., "150k + 200k").
    @Binding public var expression: String

    /// Called whenever the expression evaluates to a valid non-negative `Decimal`.
    public var onCalculate: ((Decimal) -> Void)?

    /// Called when the user taps the Done / equals key.
    public var onDone: (() -> Void)?

    @State private var result: Decimal?
    @State private var isInvalid = false

    private let parser = QuickAmountParser()

    /// Creates a quick numpad view.
    ///
    /// - Parameters:
    ///   - expression: Binding to the raw input expression string.
    ///   - onCalculate: Optional callback invoked with the evaluated result
    ///     whenever the expression changes and is valid.
    ///   - onDone: Optional callback invoked when the Done key is tapped.
    public init(
        expression: Binding<String>,
        onCalculate: ((Decimal) -> Void)? = nil,
        onDone: (() -> Void)? = nil
    ) {
        self._expression = expression
        self.onCalculate = onCalculate
        self.onDone = onDone
    }

    // MARK: - Layout

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            displayArea
            keypadGrid
        }
        .onChange(of: expression) { _, newValue in
            evaluate(newValue)
        }
    }

    // MARK: - Display Area

    private var displayArea: some View {
        VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xxs) {
            // Raw expression
            Text(expression.isEmpty ? "0" : expression)
                .font(.title3)
                .fontWeight(.medium)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(isInvalid ? .red : .primary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityLabel("Expression: \(expression.isEmpty ? "0" : expression)")

            // Evaluated result
            if let result, !expression.isEmpty {
                Text(CurrencyFormatter(currencyCode: .VND).format(result))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityLabel("Result: \(CurrencyFormatter(currencyCode: .VND).format(result))")
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.top, DesignTokens.Spacing.sm)
    }

    // MARK: - Keypad Grid

    /// Row definitions: each inner array contains a sequence of NumpadKey values.
    private var keypadRows: [[NumpadKey]] {
        [
            [.digit("7"), .digit("8"), .digit("9"), .backspace],
            [.digit("4"), .digit("5"), .digit("6"), .operator_("+")],
            [.digit("1"), .digit("2"), .digit("3"), .operator_("-")],
            [.shorthand("k", multiplier: 1_000), .digit("0"), .shorthand("tr", multiplier: 1_000_000), .done],
        ]
    }

    private var keypadGrid: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(keypadRows.indices, id: \.self) { rowIndex in
                HStack(spacing: DesignTokens.Spacing.xs) {
                    ForEach(keypadRows[rowIndex].indices, id: \.self) { colIndex in
                        let key = keypadRows[rowIndex][colIndex]
                        NumpadButton(key: key) {
                            handleKey(key)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.bottom, DesignTokens.Spacing.sm)
    }

    // MARK: - Key Handling

    private func handleKey(_ key: NumpadKey) {
        triggerHaptic()
        switch key {
        case .digit(let char):
            expression.append(char)

        case .operator_(let op):
            // Avoid leading operator or double operator
            guard !expression.isEmpty else { return }
            let lastChar = expression.last.map(String.init) ?? ""
            let operators = ["+", "-", "*"]
            if operators.contains(lastChar) {
                expression.removeLast()
            }
            expression.append(" \(op) ")

        case .shorthand(let label, _):
            // Append shorthand suffix to current token
            // Only valid after digits; prevent stacking suffixes
            let trimmed = expression.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, let last = trimmed.last, last.isNumber else { return }
            expression.append(label)

        case .backspace:
            guard !expression.isEmpty else { return }
            // Remove trailing whitespace-padded operator (e.g., " + ")
            if expression.hasSuffix(" ") {
                // Remove " op " (3 chars)
                let stripped = expression.trimmingCharacters(in: .whitespaces)
                if stripped.last.map({ ["+", "-", "*"].contains(String($0)) }) == true {
                    expression = String(stripped.dropLast())
                    expression = expression.trimmingCharacters(in: .whitespaces)
                } else {
                    expression = String(expression.dropLast())
                }
            } else {
                expression = String(expression.dropLast())
            }

        case .done:
            if let result {
                onCalculate?(result)
            }
            onDone?()
        }
    }

    // MARK: - Evaluation

    private func evaluate(_ input: String) {
        guard !input.trimmingCharacters(in: .whitespaces).isEmpty else {
            result = nil
            isInvalid = false
            return
        }
        do {
            let value = try parser.parse(input)
            result = value
            isInvalid = false
            onCalculate?(value)
        } catch {
            result = nil
            isInvalid = true
        }
    }

    // MARK: - Haptic Feedback

    private func triggerHaptic() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}

// MARK: - Supporting Types

/// Describes a single key on the numpad.
private enum NumpadKey {
    case digit(String)
    case operator_(String)
    case shorthand(String, multiplier: Decimal)
    case backspace
    case done
}

/// A single button on the numpad.
private struct NumpadButton: View {
    let key: NumpadKey
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(font)
                .fontWeight(fontWeight)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(backgroundColor)
                .foregroundStyle(foregroundColor)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .buttonStyle(.plain)
    }

    private var label: String {
        switch key {
        case .digit(let char): return char
        case .operator_(let op): return op
        case .shorthand(let text, _): return text
        case .backspace: return "⌫"
        case .done: return "="
        }
    }

    private var font: Font {
        switch key {
        case .digit, .operator_, .backspace, .done:
            return .title3
        case .shorthand:
            return .callout
        }
    }

    private var fontWeight: Font.Weight {
        switch key {
        case .operator_, .done:
            return .semibold
        default:
            return .regular
        }
    }

    private var backgroundColor: Color {
        switch key {
        case .done:
            return .blue
        case .operator_:
            return colorScheme == .dark
                ? Color.white.opacity(0.15)
                : Color.black.opacity(0.08)
        case .backspace:
            return colorScheme == .dark
                ? Color.white.opacity(0.1)
                : Color.black.opacity(0.06)
        case .shorthand:
            return colorScheme == .dark
                ? Color.white.opacity(0.12)
                : Color.black.opacity(0.07)
        case .digit:
            return colorScheme == .dark
                ? Color.white.opacity(0.08)
                : Color.black.opacity(0.04)
        }
    }

    private var foregroundColor: Color {
        switch key {
        case .done:
            return .white
        default:
            return .primary
        }
    }

    private var accessibilityLabel: String {
        switch key {
        case .digit(let char): return char
        case .operator_(let op): return op == "+" ? "Plus" : "Minus"
        case .shorthand(let text, let multiplier):
            let mult = multiplier == 1_000 ? "thousand" : "million"
            return "\(text), multiply by \(mult)"
        case .backspace: return "Delete"
        case .done: return "Done"
        }
    }

    private var accessibilityHint: String {
        switch key {
        case .digit: return "Appends digit to expression."
        case .operator_: return "Appends arithmetic operator."
        case .shorthand(_, let multiplier):
            let mult = multiplier == 1_000 ? "1,000" : "1,000,000"
            return "Multiplies last number by \(mult)."
        case .backspace: return "Deletes last character."
        case .done: return "Confirms the entered amount."
        }
    }
}

// MARK: - Previews

#Preview("Default") {
    @Previewable @State var expression = ""
    @Previewable @State var result: Decimal?

    VStack(spacing: DesignTokens.Spacing.lg) {
        QuickNumpad(expression: $expression) { value in
            result = value
        }
    }
    .background(Color.secondary.opacity(0.1))
}

#Preview("With Result") {
    @Previewable @State var expression = "150k + 200k"

    QuickNumpad(expression: $expression) { _ in }
        .background(Color.secondary.opacity(0.1))
}

#Preview("Dark Mode") {
    @Previewable @State var expression = "1tr - 50k"

    QuickNumpad(expression: $expression)
        .background(Color.secondary.opacity(0.1))
        .preferredColorScheme(.dark)
}
