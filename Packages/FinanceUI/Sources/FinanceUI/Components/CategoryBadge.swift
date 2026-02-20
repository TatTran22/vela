import FinanceCore
import SwiftUI

// MARK: - Style

/// Display style variants for ``CategoryBadge``.
public enum CategoryBadgeStyle: Sendable {
    /// A smaller rendering using a caption-sized font. Suited for dense lists and
    /// inline annotations where space is limited.
    case compact
    /// The default rendering using a body-sized font. Suited for standard transaction
    /// rows and report summaries.
    case regular
}

// MARK: - Component

/// A compact, horizontal component that pairs a small category icon with the
/// category's display name.
///
/// `CategoryBadge` is the canonical way to identify a category inline — in
/// transaction list rows, report breakdowns, filter chips, and anywhere else a
/// single-line category label is required.
///
/// The component delegates icon rendering to ``CategoryIcon`` (at the `.small`
/// size), so color, SF Symbol, and circular background all follow the same rules
/// as standalone icon usage.
///
/// The label text is drawn from `category.localizedName` and is capped at a
/// single line with a tail truncation so the badge stays compact at any width.
///
/// Accessibility: the icon is hidden from VoiceOver and the entire badge is
/// surfaced as a single combined element labelled with the category name.
///
/// Example usage:
/// ```swift
/// CategoryBadge(category: myCategory)
/// CategoryBadge(category: myCategory, style: .compact)
/// ```
public struct CategoryBadge: View {

    // MARK: Private state

    private let category: FinanceCore.Category
    private let style: CategoryBadgeStyle

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // MARK: Init

    /// Creates a category badge.
    ///
    /// - Parameters:
    ///   - category: The category whose icon and name are displayed.
    ///   - style: The size variant. Defaults to `.regular`.
    public init(category: FinanceCore.Category, style: CategoryBadgeStyle = .regular) {
        self.category = category
        self.style = style
    }

    // MARK: Body

    public var body: some View {
        HStack(spacing: iconTextSpacing) {
            CategoryIcon(
                iconName: category.iconName,
                colorHex: category.colorHex,
                size: .small
            )

            Text(category.localizedName)
                .font(labelFont)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(category.localizedName)
    }

    // MARK: Adaptive helpers

    /// Horizontal gap between the icon and the label text.
    ///
    /// Grows slightly when the user has chosen an accessibility Dynamic Type size
    /// so that the touch targets remain comfortably spaced.
    private var iconTextSpacing: CGFloat {
        dynamicTypeSize.isAccessibilitySize
            ? DesignTokens.Spacing.sm
            : DesignTokens.Spacing.xs
    }

    /// The font applied to the category name, driven by the chosen style.
    private var labelFont: Font {
        switch style {
        case .compact:
            return DesignTokens.Typography.caption
        case .regular:
            return DesignTokens.Typography.body
        }
    }
}

// MARK: - Previews

#Preview("Style Variants") {
    let food = FinanceCore.Category(
        name: "Food & Drink",
        localizedName: "Food & Drink",
        iconName: "fork.knife",
        colorHex: "#FF9500",
        type: .expense
    )
    let salary = FinanceCore.Category(
        name: "Salary",
        localizedName: "Salary",
        iconName: "briefcase.fill",
        colorHex: "#34C759",
        type: .income
    )

    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
        Text("Regular").font(.caption).foregroundStyle(.secondary)
        CategoryBadge(category: food, style: .regular)
        CategoryBadge(category: salary, style: .regular)

        Divider()

        Text("Compact").font(.caption).foregroundStyle(.secondary)
        CategoryBadge(category: food, style: .compact)
        CategoryBadge(category: salary, style: .compact)
    }
    .padding()
}

#Preview("Long Name Truncation") {
    let longName = FinanceCore.Category(
        name: "Entertainment & Subscriptions",
        localizedName: "Entertainment & Subscriptions",
        iconName: "tv.fill",
        colorHex: "#AF52DE",
        type: .expense
    )

    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
        CategoryBadge(category: longName, style: .regular)
            .frame(width: 160, alignment: .leading)
        CategoryBadge(category: longName, style: .compact)
            .frame(width: 120, alignment: .leading)
    }
    .padding()
}

#Preview("In a Transaction List") {
    let categories: [(FinanceCore.Category, String)] = [
        (
            FinanceCore.Category(
                name: "Food & Drink",
                localizedName: "Food & Drink",
                iconName: "fork.knife",
                colorHex: "#FF9500",
                type: .expense
            ),
            "-85,000 VND"
        ),
        (
            FinanceCore.Category(
                name: "Salary",
                localizedName: "Salary",
                iconName: "briefcase.fill",
                colorHex: "#34C759",
                type: .income
            ),
            "+5,000,000 VND"
        ),
        (
            FinanceCore.Category(
                name: "Transport",
                localizedName: "Transport",
                iconName: "car.fill",
                colorHex: "#007AFF",
                type: .expense
            ),
            "-50,000 VND"
        ),
    ]

    List {
        ForEach(categories, id: \.0.id) { category, amount in
            HStack {
                CategoryBadge(category: category, style: .regular)
                Spacer()
                Text(amount)
                    .font(DesignTokens.Typography.smallAmount)
                    .foregroundStyle(
                        category.type == .income
                            ? DesignTokens.Colors.income
                            : DesignTokens.Colors.expense
                    )
            }
        }
    }
}

#Preview("Dark Mode") {
    let categories = [
        FinanceCore.Category(
            name: "Housing",
            localizedName: "Housing",
            iconName: "house.fill",
            colorHex: "#5856D6",
            type: .expense
        ),
        FinanceCore.Category(
            name: "Health",
            localizedName: "Health",
            iconName: "heart.fill",
            colorHex: "#FF2D55",
            type: .expense
        ),
        FinanceCore.Category(
            name: "Transfer",
            localizedName: "Transfer",
            iconName: "arrow.left.arrow.right",
            colorHex: "#007AFF",
            type: .transfer
        ),
    ]

    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
        ForEach(categories, id: \.id) { category in
            CategoryBadge(category: category, style: .regular)
        }
    }
    .padding()
    .background(.background)
    .preferredColorScheme(.dark)
}

#Preview("Accessibility — Large Text") {
    let food = FinanceCore.Category(
        name: "Food & Drink",
        localizedName: "Food & Drink",
        iconName: "fork.knife",
        colorHex: "#FF9500",
        type: .expense
    )

    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
        CategoryBadge(category: food, style: .regular)
        CategoryBadge(category: food, style: .compact)
    }
    .padding()
    .dynamicTypeSize(.accessibility3)
}
