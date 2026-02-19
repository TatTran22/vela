import FinanceCore
import SwiftUI

/// A category selection component for transaction forms.
///
/// `CategoryPicker` offers a two-stage browsing experience:
///
/// 1. **Quick grid** — Up to 6 recent or frequent categories shown immediately
///    in a compact grid for fast reselection.
/// 2. **Full list** — A grouped list of all categories, accessible via the
///    "Xem tat ca" (Show all) button. Categories are grouped by their parent
///    category, with standalone root categories listed first.
///
/// The component automatically filters categories to match `transactionType`,
/// so income categories are not shown when adding an expense and vice versa.
///
/// Example usage:
/// ```swift
/// CategoryPicker(
///     categories: allCategories,
///     recentCategoryIDs: recentIDs,
///     transactionType: .expense
/// ) { selected in
///     transaction.categoryID = selected.id
/// }
/// ```
public struct CategoryPicker: View {
    private let categories: [FinanceCore.Category]
    private let recentCategoryIDs: [UUID]
    private let transactionType: TransactionType
    private let onSelect: (FinanceCore.Category) -> Void

    @State private var showAll = false

    /// Creates a category picker.
    ///
    /// - Parameters:
    ///   - categories: The full list of categories to pick from. The component
    ///     will filter these by `transactionType` automatically.
    ///   - recentCategoryIDs: Ordered list of recently used category IDs. The
    ///     picker shows up to 6 of these at the top. Defaults to an empty array.
    ///   - transactionType: The transaction type being created. Used to filter
    ///     income vs. expense categories.
    ///   - onSelect: Closure called with the chosen `Category` when the user
    ///     makes a selection.
    public init(
        categories: [FinanceCore.Category],
        recentCategoryIDs: [UUID] = [],
        transactionType: TransactionType,
        onSelect: @escaping (FinanceCore.Category) -> Void
    ) {
        self.categories = categories
        self.recentCategoryIDs = recentCategoryIDs
        self.transactionType = transactionType
        self.onSelect = onSelect
    }

    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                if !recentCategories.isEmpty {
                    recentSection
                }

                if showAll {
                    fullListSection
                } else {
                    showAllButton
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
    }

    // MARK: - Sections

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Recent")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.sm), count: 3),
                spacing: DesignTokens.Spacing.sm
            ) {
                ForEach(recentCategories) { category in
                    CategoryGridCell(category: category) {
                        onSelect(category)
                    }
                }
            }
        }
    }

    private var showAllButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showAll = true
            }
        } label: {
            HStack {
                Spacer()
                Text("Xem tat ca")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Image(systemName: "chevron.down")
                    .font(.caption)
                Spacer()
            }
            .foregroundStyle(.blue)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show all categories.")
        .accessibilityHint("Expands the full category list.")
    }

    private var fullListSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("All Categories")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            // Root categories (no parent)
            let grouped = groupedCategories
            ForEach(grouped, id: \.parent.id) { group in
                CategoryGroupView(parent: group.parent, children: group.children) { category in
                    onSelect(category)
                }
            }

            // Standalone root categories (no children)
            let standalone = standaloneCategories
            if !standalone.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    ForEach(standalone) { category in
                        CategoryListRow(category: category) {
                            onSelect(category)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Computed Data

    private var filteredCategories: [FinanceCore.Category] {
        if transactionType == .transfer {
            // Transfer may use all categories; show all.
            return categories
        }
        return categories.filter { $0.type == transactionType }
    }

    private var recentCategories: [FinanceCore.Category] {
        let filtered = filteredCategories
        let categoryByID: [UUID: FinanceCore.Category] = Dictionary(uniqueKeysWithValues: filtered.map { ($0.id, $0) })
        let recent = recentCategoryIDs.compactMap { categoryByID[$0] }
        return Array(recent.prefix(6))
    }

    /// Pairs of (parent, children) for categories that have sub-categories.
    private var groupedCategories: [(parent: FinanceCore.Category, children: [FinanceCore.Category])] {
        let filtered = filteredCategories
        // Identify root categories that have at least one child.
        let roots = filtered.filter { $0.parentID == nil }
        let childrenByParent = Dictionary(grouping: filtered.filter { $0.parentID != nil }) { $0.parentID! }

        return roots.compactMap { root -> (parent: FinanceCore.Category, children: [FinanceCore.Category])? in
            guard let children = childrenByParent[root.id], !children.isEmpty else { return nil }
            let sorted = children.sorted { $0.sortOrder < $1.sortOrder }
            return (parent: root, children: sorted)
        }
    }

    /// Root categories that have no children — listed flat in the full list.
    private var standaloneCategories: [FinanceCore.Category] {
        let filtered = filteredCategories
        let parentsWithChildren = Set(groupedCategories.map { $0.parent.id })
        return filtered.filter { $0.parentID == nil && !parentsWithChildren.contains($0.id) }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
}

// MARK: - Category Grid Cell

/// A compact square cell displaying a category icon and name for the quick grid.
private struct CategoryGridCell: View {
    let category: FinanceCore.Category
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.colorHex))
                        .frame(width: 44, height: 44)
                    Image(systemName: category.iconName)
                        .font(.body)
                        .foregroundStyle(.white)
                }

                Text(category.name)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.name)
        .accessibilityHint("Select \(category.name) category.")
    }
}

// MARK: - Category Group View

/// A collapsible group showing a parent category header and its children.
private struct CategoryGroupView: View {
    let parent: FinanceCore.Category
    let children: [FinanceCore.Category]
    let onSelect: (FinanceCore.Category) -> Void

    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            // Group header row: icon+name selects parent; chevron toggles expansion.
            HStack(spacing: DesignTokens.Spacing.md) {
                // Tapping the icon or name selects the parent category.
                Button {
                    onSelect(parent)
                } label: {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: parent.colorHex).opacity(0.2))
                                .frame(width: 36, height: 36)
                            Image(systemName: parent.iconName)
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: parent.colorHex))
                        }

                        Text(parent.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(parent.name).")
                .accessibilityHint("Select \(parent.name) category.")

                Spacer()

                // Tapping the chevron expands or collapses children.
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(DesignTokens.Spacing.sm)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Collapse \(parent.name)." : "Expand \(parent.name).")
            }
            .padding(.vertical, DesignTokens.Spacing.xs)

            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(children) { child in
                        CategoryListRow(category: child, indented: true) {
                            onSelect(child)
                        }
                        if child.id != children.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
            }
        }
    }
}

// MARK: - Category List Row

/// A single category row for the full list, with optional indentation for children.
private struct CategoryListRow: View {
    let category: FinanceCore.Category
    var indented: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.md) {
                if indented {
                    Spacer()
                        .frame(width: DesignTokens.Spacing.lg)
                }

                ZStack {
                    Circle()
                        .fill(Color(hex: category.colorHex))
                        .frame(width: 32, height: 32)
                    Image(systemName: category.iconName)
                        .font(.caption)
                        .foregroundStyle(.white)
                }

                Text(category.name)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.name)
        .accessibilityHint("Select \(category.name) category.")
    }
}

// MARK: - Previews

#Preview("Expense Categories") {
    let parentID = UUID()
    let parent = FinanceCore.Category(id: parentID, name: "Food & Drink", iconName: "fork.knife", colorHex: "#FF9500", type: .expense, sortOrder: 0)
    let children = [
        FinanceCore.Category(name: "Restaurant", iconName: "star.fill", colorHex: "#FF6B35", type: .expense, parentID: parentID, sortOrder: 0),
        FinanceCore.Category(name: "Coffee", iconName: "cup.and.saucer.fill", colorHex: "#A0522D", type: .expense, parentID: parentID, sortOrder: 1),
        FinanceCore.Category(name: "Groceries", iconName: "cart.fill", colorHex: "#34C759", type: .expense, parentID: parentID, sortOrder: 2),
    ]
    let standalone = [
        FinanceCore.Category(name: "Transport", iconName: "car.fill", colorHex: "#5856D6", type: .expense, sortOrder: 1),
        FinanceCore.Category(name: "Health", iconName: "heart.fill", colorHex: "#FF2D55", type: .expense, sortOrder: 2),
    ]
    let all = [parent] + children + standalone
    let recentIDs = [children[0].id, standalone[0].id]

    CategoryPicker(
        categories: all,
        recentCategoryIDs: recentIDs,
        transactionType: .expense
    ) { category in
        print("Selected: \(category.name)")
    }
}

#Preview("Income Categories") {
    let categories = [
        FinanceCore.Category(name: "Salary", iconName: "briefcase.fill", colorHex: "#34C759", type: .income, sortOrder: 0),
        FinanceCore.Category(name: "Freelance", iconName: "laptopcomputer", colorHex: "#007AFF", type: .income, sortOrder: 1),
        FinanceCore.Category(name: "Investment", iconName: "chart.line.uptrend.xyaxis", colorHex: "#AF52DE", type: .income, sortOrder: 2),
        FinanceCore.Category(name: "Gift", iconName: "gift.fill", colorHex: "#FF9500", type: .income, sortOrder: 3),
    ]

    CategoryPicker(
        categories: categories,
        recentCategoryIDs: [categories[0].id, categories[1].id],
        transactionType: .income
    ) { category in
        print("Selected: \(category.name)")
    }
}

#Preview("No Recent") {
    let categories = [
        FinanceCore.Category(name: "Transport", iconName: "car.fill", colorHex: "#5856D6", type: .expense, sortOrder: 0),
        FinanceCore.Category(name: "Health", iconName: "heart.fill", colorHex: "#FF2D55", type: .expense, sortOrder: 1),
    ]

    CategoryPicker(
        categories: categories,
        transactionType: .expense
    ) { category in
        print("Selected: \(category.name)")
    }
}

#Preview("Dark Mode") {
    let categories = [
        FinanceCore.Category(name: "Salary", iconName: "briefcase.fill", colorHex: "#34C759", type: .income, sortOrder: 0),
        FinanceCore.Category(name: "Freelance", iconName: "laptopcomputer", colorHex: "#007AFF", type: .income, sortOrder: 1),
    ]

    CategoryPicker(
        categories: categories,
        recentCategoryIDs: [categories[0].id],
        transactionType: .income
    ) { category in
        print("Selected: \(category.name)")
    }
    .preferredColorScheme(.dark)
}
