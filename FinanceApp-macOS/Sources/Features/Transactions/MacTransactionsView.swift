import FinanceCore
import FinanceData
import FinanceUI
import SwiftData
import SwiftUI

/// Main transactions view for macOS using a sortable, multi-select `Table`.
///
/// Displays all transactions in a column-based table with date, category, note,
/// amount, and account columns. Supports:
/// - Toolbar search field (`.searchable`)
/// - Multi-row selection via a `Set<UUID>` binding
/// - Right-click context menu: Edit, Duplicate, Delete
/// - Double-click or Enter to edit a selected row
/// - Bulk delete with `⌘Delete`
/// - New transaction with `⌘N`
/// - Empty state via `ContentUnavailableView`
///
/// This view creates its own `MacTransactionsViewModel` from a `ModelContainer`,
/// following the same dependency pattern as `MacAccountsView`.
struct MacTransactionsView: View {

    // MARK: - ViewModel

    @State private var viewModel: MacTransactionsViewModel

    // MARK: - Sheet & dialog state

    /// Transaction being edited, or nil when creating a new one.
    @State private var editingTransaction: FinanceCore.Transaction?

    /// Transaction being staged for duplication (passed to entry as a pre-filled template).
    @State private var duplicatingTransaction: FinanceCore.Transaction?

    /// Controls visibility of the new/edit entry sheet.
    @State private var showingEntrySheet = false

    /// Controls visibility of the single-row delete confirmation dialog.
    @State private var showingDeleteConfirmation = false

    /// The UUID(s) staged for deletion (single or bulk).
    @State private var pendingDeleteIDs: Set<UUID> = []

    // MARK: - Model container reference (kept for sheet construction)

    private let modelContainer: ModelContainer

    // MARK: - Init

    /// Creates the view from a SwiftData `ModelContainer`.
    ///
    /// - Parameter modelContainer: The SwiftData container used to initialise all repositories.
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        _viewModel = State(
            initialValue: MacTransactionsViewModel(modelContainer: modelContainer)
        )
    }

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.transactions.isEmpty {
                ProgressView("Loading transactions...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.transactions.isEmpty {
                emptyState
            } else {
                transactionTable
            }
        }
        .navigationTitle("Transactions")
        .searchable(text: $viewModel.searchText, prompt: "Search transactions")
        .task { await viewModel.loadData() }
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingEntrySheet, onDismiss: {
            editingTransaction = nil
            duplicatingTransaction = nil
        }) {
            NavigationStack {
                entrySheet
            }
        }
        .confirmationDialog(
            "Delete \(pendingDeleteIDs.count == 1 ? "Transaction" : "\(pendingDeleteIDs.count) Transactions")?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteTransactions(pendingDeleteIDs) }
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteIDs = []
            }
        } message: {
            if pendingDeleteIDs.count == 1 {
                Text("This action cannot be undone.")
            } else {
                Text("This will permanently delete \(pendingDeleteIDs.count) transactions. This action cannot be undone.")
            }
        }
        .alert(
            "Error",
            isPresented: $viewModel.showError,
            actions: {
                Button("OK") { viewModel.showError = false }
            },
            message: {
                Text(viewModel.error?.localizedDescription ?? "An unknown error occurred.")
            }
        )
        .onKeyPress(.return) {
            openSelectedTransactionForEditing()
            return .handled
        }
    }

    // MARK: - Table

    private var transactionTable: some View {
        Table(
            viewModel.transactions,
            selection: $viewModel.selectedTransactionIDs,
            sortOrder: $viewModel.sortOrder
        ) {
            // Date column — sortable by key path
            TableColumn("Date", value: \.date) { tx in
                Text(tx.date, style: .date)
                    .monospacedDigit()
            }
            .width(min: 90, ideal: 110)

            // Category column — not sortable (no direct key path to name)
            TableColumn("Category") { tx in
                HStack(spacing: 6) {
                    if let category = viewModel.categories.first(where: { $0.id == tx.categoryID }) {
                        Image(systemName: category.iconName)
                            .foregroundStyle(Color(hex: category.colorHex))
                            .frame(width: 16)
                    }
                    Text(viewModel.categoryName(for: tx.categoryID))
                        .lineLimit(1)
                }
            }
            .width(min: 100, ideal: 140)

            // Note column — sortable by key path
            TableColumn("Note", value: \.note) { tx in
                Text(tx.note.isEmpty ? "—" : tx.note)
                    .lineLimit(1)
                    .foregroundStyle(tx.note.isEmpty ? Color.secondary : Color.primary)
            }
            .width(min: 120, ideal: 200)

            // Amount column — not sortable (Decimal requires custom comparator)
            TableColumn("Amount") { tx in
                let account = viewModel.account(for: tx.accountID)
                AmountText(
                    amount: tx.amount,
                    currencyCode: account?.currency ?? .VND,
                    type: tx.type
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 100, ideal: 130)

            // Account column — not sortable (no direct key path to name)
            TableColumn("Account") { tx in
                Text(viewModel.accountName(for: tx.accountID))
                    .lineLimit(1)
            }
            .width(min: 100, ideal: 140)
        }
        .contextMenu(forSelectionType: UUID.self) { selectedIDs in
            contextMenuItems(for: selectedIDs)
        } primaryAction: { selectedIDs in
            // Double-click primary action: edit if exactly one row is selected
            if selectedIDs.count == 1, let id = selectedIDs.first,
               let tx = viewModel.transactions.first(where: { $0.id == id }) {
                editingTransaction = tx
                showingEntrySheet = true
            }
        }
        .onChange(of: viewModel.sortOrder) { _, _ in
            Task { await viewModel.loadData() }
        }
    }

    // MARK: - Context menu

    @ViewBuilder
    private func contextMenuItems(for ids: Set<UUID>) -> some View {
        let count = ids.count

        if count == 1, let id = ids.first,
           let tx = viewModel.transactions.first(where: { $0.id == id }) {
            Button("Edit") {
                editingTransaction = tx
                showingEntrySheet = true
            }

            Button("Duplicate") {
                duplicatingTransaction = tx
                showingEntrySheet = true
            }

            Divider()
        }

        Button("Delete\(count > 1 ? " \(count) Transactions" : "")", role: .destructive) {
            pendingDeleteIDs = ids
            showingDeleteConfirmation = true
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView {
            if viewModel.searchText.isEmpty {
                Label("No Transactions", systemImage: "list.bullet.rectangle")
            } else {
                Label("No Results", systemImage: "magnifyingglass")
            }
        } description: {
            if viewModel.searchText.isEmpty {
                Text("Add your first transaction to get started.")
            } else {
                Text("No transactions match \"\(viewModel.searchText)\".")
            }
        } actions: {
            if viewModel.searchText.isEmpty {
                Button("New Transaction") {
                    editingTransaction = nil
                    showingEntrySheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // New Transaction button (⌘N)
        ToolbarItem(placement: .primaryAction) {
            Button {
                editingTransaction = nil
                showingEntrySheet = true
            } label: {
                Label("New Transaction", systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
            .help("Create a new transaction (⌘N)")
        }

        // Bulk delete button — visible only when rows are selected
        ToolbarItem {
            if !viewModel.selectedTransactionIDs.isEmpty {
                Button(role: .destructive) {
                    pendingDeleteIDs = viewModel.selectedTransactionIDs
                    showingDeleteConfirmation = true
                } label: {
                    Label(
                        "Delete Selected (\(viewModel.selectedTransactionIDs.count))",
                        systemImage: "trash"
                    )
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .help("Delete selected transactions (⌘Delete)")
            }
        }

        // Refresh button
        ToolbarItem {
            Button {
                Task { await viewModel.refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .help("Refresh transactions")
        }
    }

    // MARK: - Entry sheet builder

    /// Builds the correct entry view depending on whether we are editing, duplicating, or creating.
    @ViewBuilder
    private var entrySheet: some View {
        if let tx = editingTransaction {
            MacTransactionEntryView(
                editing: tx,
                modelContainer: modelContainer
            ) {
                Task { await viewModel.loadData() }
            }
        } else if let tx = duplicatingTransaction {
            // Duplicate: open entry view pre-filled, but without setting the ID
            // so it creates a new transaction. We use a template transaction with today's date.
            MacTransactionEntryView(
                editing: duplicateTemplate(from: tx),
                modelContainer: modelContainer
            ) {
                Task { await viewModel.loadData() }
            }
        } else {
            MacTransactionEntryView(modelContainer: modelContainer) {
                Task { await viewModel.loadData() }
            }
        }
    }

    // MARK: - Helpers

    /// Opens the first (and only) selected transaction for editing via the keyboard Enter key.
    private func openSelectedTransactionForEditing() {
        guard viewModel.selectedTransactionIDs.count == 1,
              let id = viewModel.selectedTransactionIDs.first,
              let tx = viewModel.transactions.first(where: { $0.id == id })
        else { return }
        editingTransaction = tx
        showingEntrySheet = true
    }

    /// Creates a new `FinanceCore.Transaction` based on an existing one, with a new UUID and today's date.
    ///
    /// - Parameter original: The transaction to clone.
    /// - Returns: A new transaction with a fresh ID, today's date, and the same other fields.
    private func duplicateTemplate(from original: FinanceCore.Transaction) -> FinanceCore.Transaction {
        FinanceCore.Transaction(
            id: UUID(),
            amount: original.amount,
            type: original.type,
            categoryID: original.categoryID,
            accountID: original.accountID,
            toAccountID: original.toAccountID,
            note: original.note,
            date: Date(),
            isRecurring: false,
            tags: original.tags,
            metadata: original.metadata
        )
    }
}
