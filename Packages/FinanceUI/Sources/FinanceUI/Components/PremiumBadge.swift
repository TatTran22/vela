import SwiftUI

/// A badge indicating a premium/gated feature, with an optional tap-to-paywall action.
///
/// Displays a lock icon and "Premium" label. Tapping triggers the `onTap`
/// closure, typically used to present a paywall sheet.
///
/// Example usage:
/// ```swift
/// PremiumBadge {
///     showPaywall = true
/// }
/// ```
public struct PremiumBadge: View {
    private let onTap: (() -> Void)?

    /// Creates a premium badge.
    ///
    /// - Parameter onTap: Optional closure invoked when the badge is tapped.
    ///   When `nil`, the badge is non-interactive.
    public init(onTap: (() -> Void)? = nil) {
        self.onTap = onTap
    }

    public var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) {
                    content
                }
                .buttonStyle(.plain)
            } else {
                content
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(UIStrings.premiumAccessibility)
        .accessibilityHint(onTap != nil ? UIStrings.premiumAccessibilityHint : "")
    }

    private var content: some View {
        HStack(spacing: DesignTokens.Spacing.xxs) {
            Image(systemName: "lock.fill")
                .font(.system(size: 9, weight: .bold))
            Text(UIStrings.premiumLabel)
                .font(.system(size: 11, weight: .bold))
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xxs + 1)
        .foregroundStyle(.white)
        .background(
            LinearGradient(
                colors: [.purple, .blue],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
    }
}

// MARK: - Previews

#Preview("Default") {
    PremiumBadge()
        .padding()
}

#Preview("Tappable") {
    PremiumBadge {
        print("Show paywall")
    }
    .padding()
}

#Preview("In Context") {
    HStack {
        Text("AI Insights")
            .font(DesignTokens.Typography.subheading)
        PremiumBadge()
        Spacer()
    }
    .padding()
}

#Preview("Dark Mode") {
    HStack {
        Text("AI Insights")
            .font(DesignTokens.Typography.subheading)
        PremiumBadge()
        Spacer()
    }
    .padding()
    .background(.background)
    .preferredColorScheme(.dark)
}
