import SwiftUI

/// A placeholder view shown when a list or section has no content.
///
/// `EmptyStateView` provides consistent empty-state messaging with an icon,
/// title, optional subtitle, and an optional call-to-action button.
///
/// Example usage:
/// ```swift
/// EmptyStateView(
///     icon: "list.bullet",
///     title: "No Transactions",
///     subtitle: "Add your first transaction to get started.",
///     actionTitle: "Add Transaction"
/// ) {
///     showAddTransaction = true
/// }
/// ```
public struct EmptyStateView: View {
    private let icon: String
    private let title: String
    private let subtitle: String?
    private let actionTitle: String?
    private let action: (() -> Void)?

    /// Creates an empty state view.
    ///
    /// - Parameters:
    ///   - icon: SF Symbol name for the illustration icon.
    ///   - title: Primary message (e.g., "No Transactions").
    ///   - subtitle: Optional secondary explanation text.
    ///   - actionTitle: Optional button title. When provided, a CTA button is shown.
    ///   - action: Closure invoked when the CTA button is tapped.
    public init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)

            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(title)
                    .font(DesignTokens.Typography.subheading)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                if let subtitle {
                    Text(subtitle)
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(DesignTokens.Typography.body)
                        .fontWeight(.semibold)
                        .padding(.horizontal, DesignTokens.Spacing.xl)
                        .padding(.vertical, DesignTokens.Spacing.md)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(actionTitle)
            }
        }
        .padding(DesignTokens.Spacing.xxl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Common Presets

extension EmptyStateView {
    /// Preset for an empty transaction list.
    public static func noTransactions(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "list.bullet",
            title: UIStrings.noTransactionsTitle,
            subtitle: UIStrings.noTransactionsSubtitle,
            actionTitle: UIStrings.noTransactionsAction,
            action: action
        )
    }

    /// Preset for an empty account list.
    public static func noAccounts(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "creditcard",
            title: UIStrings.noAccountsTitle,
            subtitle: UIStrings.noAccountsSubtitle,
            actionTitle: UIStrings.noAccountsAction,
            action: action
        )
    }

    /// Preset for no search results.
    public static var noResults: EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: UIStrings.noResultsTitle,
            subtitle: UIStrings.noResultsSubtitle
        )
    }
}

// MARK: - Previews

#Preview("With Action") {
    EmptyStateView(
        icon: "list.bullet",
        title: "No Transactions",
        subtitle: "Add your first transaction to start tracking.",
        actionTitle: "Add Transaction"
    ) {}
}

#Preview("Without Action") {
    EmptyStateView(
        icon: "magnifyingglass",
        title: "No Results",
        subtitle: "Try a different search term."
    )
}

#Preview("Presets") {
    ScrollView {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            EmptyStateView.noTransactions {}
            Divider()
            EmptyStateView.noAccounts {}
            Divider()
            EmptyStateView.noResults
        }
    }
}

#Preview("Dark Mode") {
    EmptyStateView.noTransactions {}
        .preferredColorScheme(.dark)
}
