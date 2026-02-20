import SwiftUI

/// A small colored pill with text, used for tags, status indicators, and labels.
///
/// Example usage:
/// ```swift
/// BadgeView(text: "New", color: .blue)
/// BadgeView(text: "Premium", icon: "lock.fill", color: .purple)
/// ```
public struct BadgeView: View {
    private let text: String
    private let icon: String?
    private let color: Color

    /// Creates a badge with text and an optional leading icon.
    ///
    /// - Parameters:
    ///   - text: The badge label.
    ///   - icon: Optional SF Symbol name shown before the text.
    ///   - color: The badge tint color. Defaults to `.blue`.
    public init(text: String, icon: String? = nil, color: Color = .blue) {
        self.text = text
        self.icon = icon
        self.color = color
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.xxs) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xxs + 1)
        .foregroundStyle(color)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

// MARK: - Previews

#Preview("Variants") {
    HStack(spacing: DesignTokens.Spacing.sm) {
        BadgeView(text: "New", color: .blue)
        BadgeView(text: "Premium", icon: "lock.fill", color: .purple)
        BadgeView(text: "Overdue", color: .red)
        BadgeView(text: "Synced", icon: "checkmark", color: .green)
    }
    .padding()
}

#Preview("Dark Mode") {
    HStack(spacing: DesignTokens.Spacing.sm) {
        BadgeView(text: "New", color: .blue)
        BadgeView(text: "Premium", icon: "lock.fill", color: .purple)
    }
    .padding()
    .preferredColorScheme(.dark)
}
