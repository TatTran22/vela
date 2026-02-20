import SwiftUI

/// A styled container with rounded corners and shadow.
///
/// `CardView` wraps arbitrary content in a consistent card surface used
/// throughout the app for dashboard cards, account summaries, and detail panels.
/// An optional header can be provided to display a title bar above the content.
///
/// Example usage:
/// ```swift
/// CardView {
///     Text("Hello")
/// }
///
/// CardView(header: { Text("Section Title") }) {
///     Text("Content goes here")
/// }
/// ```
public struct CardView<Header: View, Content: View>: View {
    private let header: Header?
    private let content: Content

    @Environment(\.colorScheme) private var colorScheme

    /// Creates a card with an optional header and content.
    ///
    /// - Parameters:
    ///   - header: An optional view displayed above the content. Pass `nil` or
    ///     use the convenience initializer that omits this parameter.
    ///   - content: The main content of the card.
    public init(
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header()
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let header {
                header
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.top, DesignTokens.Spacing.lg)
                    .padding(.bottom, DesignTokens.Spacing.sm)
            }

            content
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.vertical, header == nil ? DesignTokens.Spacing.lg : DesignTokens.Spacing.sm)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
        .shadow(DesignTokens.Shadow.card(colorScheme))
    }
}

// MARK: - Convenience (no header)

extension CardView where Header == EmptyView {
    /// Creates a card with content only (no header).
    ///
    /// - Parameter content: The main content of the card.
    public init(@ViewBuilder content: () -> Content) {
        self.header = nil
        self.content = content()
    }
}

// MARK: - Previews

#Preview("Simple Card") {
    CardView {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Total Balance")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(.secondary)
            Text("15,200,000 ₫")
                .font(DesignTokens.Typography.largeAmount)
        }
    }
    .padding()
}

#Preview("Card with Header") {
    CardView {
        Text("This Month")
            .font(DesignTokens.Typography.subheading)
    } content: {
        HStack {
            VStack(alignment: .leading) {
                Text("Income")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("+30,000,000 ₫")
                    .foregroundStyle(.green)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("Expense")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("-22,000,000 ₫")
                    .foregroundStyle(.red)
            }
        }
    }
    .padding()
}

#Preview("Dark Mode") {
    CardView {
        Text("Card in dark mode")
    }
    .padding()
    .background(Color(uiColorCompat: "systemGroupedBackground"))
    .preferredColorScheme(.dark)
}
