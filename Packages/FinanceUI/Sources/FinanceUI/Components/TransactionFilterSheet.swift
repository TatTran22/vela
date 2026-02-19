import FinanceCore
import SwiftUI

/// A sheet-based UI for filtering a transaction list.
///
/// `TransactionFilterSheet` presents the user with several sections for
/// narrowing down which transactions are visible:
///
/// - **Type** — Toggle chips for income, expense, and transfer.
/// - **Date range** — Quick-select presets (Today, This Week, This Month) plus
///   a custom date range picker.
/// - **Accounts** — Multi-select list of accounts.
/// - **Categories** — Multi-select list of categories.
/// - **Amount range** — Minimum and maximum amount text fields.
///
/// The toolbar provides a "Clear All" button and an "Apply" button. The
/// navigation title shows the number of active filter criteria.
///
/// Example usage:
/// ```swift
/// @State private var filter = TransactionFilter()
/// @State private var showFilter = false
///
/// Button("Filter") { showFilter = true }
///     .sheet(isPresented: $showFilter) {
///         TransactionFilterSheet(
///             filter: $filter,
///             accounts: accounts,
///             categories: categories,
///             onApply: { showFilter = false },
///             onClear: { filter = TransactionFilter() }
///         )
///     }
/// ```
public struct TransactionFilterSheet: View {
    /// The filter being configured. Changes are reflected immediately in the binding.
    @Binding public var filter: TransactionFilter

    /// All accounts available for selection.
    public var accounts: [Account]

    /// All categories available for selection.
    public var categories: [FinanceCore.Category]

    /// Called when the user taps "Apply".
    public var onApply: () -> Void

    /// Called when the user taps "Clear All".
    public var onClear: () -> Void

    // MARK: - Local state for draft editing

    @State private var selectedTypes: Set<TransactionType>
    @State private var selectedAccountIDs: Set<UUID>
    @State private var selectedCategoryIDs: Set<UUID>
    @State private var datePreset: DatePreset
    @State private var customStartDate: Date
    @State private var customEndDate: Date
    @State private var minAmountText: String
    @State private var maxAmountText: String

    // MARK: - Init

    /// Creates a transaction filter sheet.
    ///
    /// - Parameters:
    ///   - filter: Binding to the filter being edited.
    ///   - accounts: Accounts to display in the account selector.
    ///   - categories: Categories to display in the category selector.
    ///   - onApply: Closure called when the user confirms the filter.
    ///   - onClear: Closure called when the user clears all filters.
    public init(
        filter: Binding<TransactionFilter>,
        accounts: [Account],
        categories: [FinanceCore.Category],
        onApply: @escaping () -> Void,
        onClear: @escaping () -> Void
    ) {
        self._filter = filter
        self.accounts = accounts
        self.categories = categories
        self.onApply = onApply
        self.onClear = onClear

        let current = filter.wrappedValue

        // Initialise local draft state from the current filter.
        _selectedTypes = State(initialValue: Set(current.types ?? []))
        _selectedAccountIDs = State(initialValue: Set(current.accountIDs ?? []))
        _selectedCategoryIDs = State(initialValue: Set(current.categoryIDs ?? []))

        let preset = DatePreset(from: current.dateRange)
        _datePreset = State(initialValue: preset)

        let calendar = Calendar.current
        _customStartDate = State(
            initialValue: current.dateRange?.lowerBound ?? calendar.startOfDay(for: Date())
        )
        _customEndDate = State(
            initialValue: current.dateRange?.upperBound ?? Date()
        )

        if let range = current.amountRange {
            _minAmountText = State(initialValue: "\(range.lowerBound)")
            _maxAmountText = State(initialValue: "\(range.upperBound)")
        } else {
            _minAmountText = State(initialValue: "")
            _maxAmountText = State(initialValue: "")
        }
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            Form {
                typeSection
                dateSection
                accountSection
                categorySection
                amountSection
            }
            .navigationTitle(navigationTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear All") {
                        clearAll()
                        onClear()
                    }
                    .foregroundStyle(.red)
                    .accessibilityLabel("Clear all filters.")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyFilter()
                        onApply()
                    }
                    .fontWeight(.semibold)
                    .accessibilityLabel("Apply selected filters.")
                }
            }
        }
    }

    // MARK: - Sections

    private var typeSection: some View {
        Section("Transaction Type") {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    TypeChip(
                        type: type,
                        isSelected: selectedTypes.contains(type)
                    ) {
                        toggleType(type)
                    }
                }
                Spacer()
            }
            .listRowInsets(EdgeInsets(
                top: DesignTokens.Spacing.sm,
                leading: DesignTokens.Spacing.lg,
                bottom: DesignTokens.Spacing.sm,
                trailing: DesignTokens.Spacing.lg
            ))
        }
    }

    private var dateSection: some View {
        Section("Date Range") {
            // Preset picker
            Picker("Preset", selection: $datePreset) {
                ForEach(DatePreset.allCases, id: \.self) { preset in
                    Text(preset.label).tag(preset)
                }
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(
                top: DesignTokens.Spacing.sm,
                leading: DesignTokens.Spacing.lg,
                bottom: DesignTokens.Spacing.sm,
                trailing: DesignTokens.Spacing.lg
            ))
            .accessibilityLabel("Date preset selector.")

            // Custom date range — only visible when "Custom" is selected
            if datePreset == .custom {
                DatePicker(
                    "From",
                    selection: $customStartDate,
                    displayedComponents: .date
                )
                .accessibilityLabel("Start date.")

                DatePicker(
                    "To",
                    selection: $customEndDate,
                    in: customStartDate...,
                    displayedComponents: .date
                )
                .accessibilityLabel("End date.")
            }
        }
    }

    private var accountSection: some View {
        Section("Accounts") {
            if accounts.isEmpty {
                Text("No accounts available.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(accounts) { account in
                    AccountToggleRow(
                        name: account.name,
                        iconName: account.iconName,
                        colorHex: account.colorHex,
                        isSelected: selectedAccountIDs.contains(account.id)
                    ) {
                        toggleAccount(account.id)
                    }
                }
            }
        }
    }

    private var categorySection: some View {
        Section("Categories") {
            if categories.isEmpty {
                Text("No categories available.")
                    .foregroundStyle(.secondary)
            } else {
                // Filter categories to match selected types, or show all
                let filtered = filteredCategories
                ForEach(filtered) { category in
                    AccountToggleRow(
                        name: category.name,
                        iconName: category.iconName,
                        colorHex: category.colorHex,
                        isSelected: selectedCategoryIDs.contains(category.id)
                    ) {
                        toggleCategory(category.id)
                    }
                }
            }
        }
    }

    private var amountSection: some View {
        Section("Amount Range") {
            HStack {
                Text("Min")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("0", text: $minAmountText)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                    .accessibilityLabel("Minimum amount.")
            }

            HStack {
                Text("Max")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("No limit", text: $maxAmountText)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                    .accessibilityLabel("Maximum amount.")
            }
        }
    }

    // MARK: - Helpers

    private var navigationTitle: String {
        let count = activeFilterCount
        return count == 0 ? "Filter" : "Filter (\(count))"
    }

    private var activeFilterCount: Int {
        var count = 0
        if !selectedTypes.isEmpty { count += 1 }
        if !selectedAccountIDs.isEmpty { count += 1 }
        if !selectedCategoryIDs.isEmpty { count += 1 }
        if datePreset != .all { count += 1 }
        if !minAmountText.isEmpty || !maxAmountText.isEmpty { count += 1 }
        return count
    }

    /// Categories filtered to match the selected types (or all if no types selected).
    private var filteredCategories: [FinanceCore.Category] {
        if selectedTypes.isEmpty {
            return categories
        }
        return categories.filter { selectedTypes.contains($0.type) }
    }

    private func toggleType(_ type: TransactionType) {
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
        }
    }

    private func toggleAccount(_ id: UUID) {
        if selectedAccountIDs.contains(id) {
            selectedAccountIDs.remove(id)
        } else {
            selectedAccountIDs.insert(id)
        }
    }

    private func toggleCategory(_ id: UUID) {
        if selectedCategoryIDs.contains(id) {
            selectedCategoryIDs.remove(id)
        } else {
            selectedCategoryIDs.insert(id)
        }
    }

    private func clearAll() {
        selectedTypes = []
        selectedAccountIDs = []
        selectedCategoryIDs = []
        datePreset = .all
        minAmountText = ""
        maxAmountText = ""
    }

    private func applyFilter() {
        filter.types = selectedTypes.isEmpty ? nil : Array(selectedTypes)
        filter.accountIDs = selectedAccountIDs.isEmpty ? nil : Array(selectedAccountIDs)
        filter.categoryIDs = selectedCategoryIDs.isEmpty ? nil : Array(selectedCategoryIDs)
        filter.dateRange = datePreset.dateRange(customStart: customStartDate, customEnd: customEndDate)

        let minAmount = Decimal(string: minAmountText)
        let maxAmount = Decimal(string: maxAmountText)
        if let min = minAmount, let max = maxAmount, min <= max {
            filter.amountRange = min...max
        } else if let min = minAmount {
            filter.amountRange = min...Decimal.greatestFiniteMagnitude
        } else {
            filter.amountRange = nil
        }
    }
}

// MARK: - Date Preset

private enum DatePreset: CaseIterable, Hashable {
    case all
    case today
    case thisWeek
    case thisMonth
    case custom

    var label: String {
        switch self {
        case .all: return "All"
        case .today: return "Today"
        case .thisWeek: return "Week"
        case .thisMonth: return "Month"
        case .custom: return "Custom"
        }
    }

    /// Derives a preset from an existing date range, if any.
    init(from range: ClosedRange<Date>?) {
        guard range != nil else {
            self = .all
            return
        }
        // Default to custom since we cannot reliably reverse-engineer presets.
        self = .custom
    }

    func dateRange(customStart: Date, customEnd: Date) -> ClosedRange<Date>? {
        let calendar = Calendar.current
        switch self {
        case .all:
            return nil
        case .today:
            let start = calendar.startOfDay(for: Date())
            // swiftlint:disable:next force_unwrapping
            let end = calendar.date(byAdding: .day, value: 1, to: start)!.addingTimeInterval(-1)
            return start...end
        case .thisWeek:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
                return nil
            }
            return interval.start...interval.end.addingTimeInterval(-1)
        case .thisMonth:
            guard let interval = calendar.dateInterval(of: .month, for: Date()) else {
                return nil
            }
            return interval.start...interval.end.addingTimeInterval(-1)
        case .custom:
            let start = calendar.startOfDay(for: customStart)
            // swiftlint:disable:next force_unwrapping
            let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: customEnd))!.addingTimeInterval(-1)
            return start...end
        }
    }
}

// MARK: - Type Chip

/// A toggle chip for selecting a transaction type.
private struct TypeChip: View {
    let type: TransactionType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(type.displayName)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(isSelected ? chipColor.opacity(0.15) : Color.secondary.opacity(0.1))
                .foregroundStyle(isSelected ? chipColor : .secondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? chipColor : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(type.displayName) filter.")
        .accessibilityHint(isSelected ? "Currently selected. Tap to deselect." : "Tap to select.")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var chipColor: Color {
        switch type {
        case .income: return .green
        case .expense: return .red
        case .transfer: return .blue
        }
    }
}

// MARK: - Account / Category Toggle Row

/// A list row with a colored icon that toggles a selection checkmark.
private struct AccountToggleRow: View {
    let name: String
    let iconName: String
    let colorHex: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color(hex: colorHex))
                        .frame(width: 32, height: 32)
                    Image(systemName: iconName)
                        .font(.caption)
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)

                Text(name)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .fontWeight(.semibold)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityHint(isSelected ? "Selected. Tap to deselect." : "Tap to select.")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Decimal Largest Finite Value Helper

private extension Decimal {
    static var greatestFiniteMagnitude: Decimal {
        Decimal(string: "9999999999999999999999999999") ?? 0
    }
}

// MARK: - Previews

#Preview("Empty Filter") {
    @Previewable @State var filter = TransactionFilter()

    TransactionFilterSheet(
        filter: $filter,
        accounts: [
            Account(name: "Cash Wallet", type: .cash, currency: .VND, iconName: "banknote", colorHex: "#34C759"),
            Account(name: "Main Checking", type: .bank, currency: .VND, iconName: "building.columns", colorHex: "#007AFF"),
        ],
        categories: [
            FinanceCore.Category(name: "Food & Drink", iconName: "fork.knife", colorHex: "#FF9500", type: .expense),
            FinanceCore.Category(name: "Salary", iconName: "briefcase.fill", colorHex: "#34C759", type: .income),
            FinanceCore.Category(name: "Transport", iconName: "car.fill", colorHex: "#5856D6", type: .expense),
        ],
        onApply: {},
        onClear: {}
    )
}

#Preview("Dark Mode") {
    @Previewable @State var filter = TransactionFilter(
        types: [.expense],
        excludeTransfers: false
    )

    TransactionFilterSheet(
        filter: $filter,
        accounts: [
            Account(name: "Cash Wallet", type: .cash, currency: .VND, iconName: "banknote", colorHex: "#34C759"),
        ],
        categories: [
            FinanceCore.Category(name: "Food & Drink", iconName: "fork.knife", colorHex: "#FF9500", type: .expense),
        ],
        onApply: {},
        onClear: {}
    )
    .preferredColorScheme(.dark)
}
