import FinanceCore
import FinanceUI
import SwiftUI

/// Detail view for a single transaction.
///
/// Displays the full transaction information and supports switching into
/// an inline edit mode where the user can modify the amount, note, date,
/// and category. A delete button with a confirmation dialog allows removing
/// the transaction.
struct TransactionDetailView: View {
    @State private var viewModel: TransactionDetailViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    /// Creates a transaction detail view.
    /// - Parameter viewModel: The view model providing transaction data.
    init(viewModel: TransactionDetailViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.isEditing {
                editContent
            } else {
                detailContent
            }
        }
        .navigationTitle(viewModel.isEditing ? "Edit Transaction" : (viewModel.category?.name ?? "Transaction"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.cancelEditing() }
                        .accessibilityLabel("Cancel editing.")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await viewModel.saveEdit() }
                    }
                    .fontWeight(.semibold)
                    .accessibilityLabel("Save changes.")
                }
            } else {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { viewModel.startEditing() }
                        .accessibilityLabel("Edit this transaction.")
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        viewModel.showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Delete this transaction.")
                }
            }
        }
        .confirmationDialog(
            "Delete Transaction?",
            isPresented: $viewModel.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteTransaction() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .onChange(of: viewModel.didDelete) { _, deleted in
            if deleted { dismiss() }
        }
        .task {
            await viewModel.loadDetails()
        }
    }

    // MARK: - Detail Content

    private var detailContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                amountHeader
                    .padding(.top, 8)

                detailRows

                if !viewModel.transaction.tags.isEmpty {
                    tagsSection
                }

                Spacer(minLength: 24)
            }
            .padding()
        }
    }

    private var amountHeader: some View {
        VStack(spacing: 8) {
            // Type badge
            Text(viewModel.transaction.type.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(typeColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(typeColor.opacity(0.12))
                .clipShape(Capsule())
                .accessibilityLabel("Transaction type: \(viewModel.transaction.type.displayName)")

            // Large amount
            let formatter = CurrencyFormatter(currencyCode: viewModel.account?.currency ?? .VND)
            let sign = viewModel.transaction.type == .expense ? "-" : (viewModel.transaction.type == .income ? "+" : "")
            Text("\(sign)\(formatter.format(viewModel.transaction.amount))")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(typeColor)
                .monospacedDigit()
                .accessibilityLabel("Amount: \(formatter.format(viewModel.transaction.amount))")
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var detailRows: some View {
        VStack(spacing: 0) {
            // Category
            DetailRow(
                icon: viewModel.category?.iconName ?? "questionmark.circle",
                iconColor: Color(hex: viewModel.category?.colorHex ?? "#8E8E93"),
                label: "Category",
                value: viewModel.category?.name ?? "Unknown"
            )
            Divider().padding(.leading, 52)

            // Account
            DetailRow(
                icon: viewModel.account?.iconName ?? "banknote",
                iconColor: Color(hex: viewModel.account?.colorHex ?? "#007AFF"),
                label: "Account",
                value: viewModel.account?.name ?? "Unknown"
            )

            // To account (transfers only)
            if viewModel.transaction.type == .transfer {
                Divider().padding(.leading, 52)
                DetailRow(
                    icon: viewModel.toAccount?.iconName ?? "banknote",
                    iconColor: Color(hex: viewModel.toAccount?.colorHex ?? "#007AFF"),
                    label: "To Account",
                    value: viewModel.toAccount?.name ?? "Unknown"
                )
            }

            Divider().padding(.leading, 52)

            // Date
            DetailRow(
                icon: "calendar",
                iconColor: .blue,
                label: "Date",
                value: viewModel.transaction.date.formatted(date: .long, time: .shortened)
            )

            // Note
            if !viewModel.transaction.note.isEmpty {
                Divider().padding(.leading, 52)
                DetailRow(
                    icon: "note.text",
                    iconColor: .orange,
                    label: "Note",
                    value: viewModel.transaction.note
                )
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)

            FlowLayout(spacing: 8) {
                ForEach(viewModel.transaction.tags, id: \.self) { _ in
                    Text("#tag")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Edit Content

    private var editContent: some View {
        Form {
            Section("Amount") {
                HStack {
                    Text("Amount")
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("0", text: $viewModel.editAmount)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .accessibilityLabel("Edit amount.")
                }
            }

            Section("Category") {
                if viewModel.availableCategories.isEmpty {
                    Text("No categories available.")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Category", selection: $viewModel.editCategory) {
                        Text("None").tag(Optional<FinanceCore.Category>.none)
                        ForEach(viewModel.availableCategories.filter { $0.type == viewModel.transaction.type }) { cat in
                            Label(cat.name, systemImage: cat.iconName)
                                .tag(Optional(cat))
                        }
                    }
                    .accessibilityLabel("Select category.")
                }
            }

            Section("Date") {
                DatePicker(
                    "Date",
                    selection: $viewModel.editDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .accessibilityLabel("Edit transaction date and time.")
            }

            Section("Note") {
                TextField("Optional note", text: $viewModel.editNote, axis: .vertical)
                    .lineLimit(3)
                    .accessibilityLabel("Edit note.")
            }
        }
    }

    // MARK: - Helpers

    private var typeColor: Color {
        switch viewModel.transaction.type {
        case .income: return .green
        case .expense: return .red
        case .transfer: return .blue
        }
    }
}

// MARK: - Detail Row

/// A single labelled row in the transaction detail view.
private struct DetailRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Flow Layout (for tags)

/// A simple wrapping horizontal layout for tag chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
