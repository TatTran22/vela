import FinanceCore
import FinanceData
import FinanceUI
import SwiftData
import SwiftUI

/// Form-based sheet for creating or editing a transaction on macOS.
///
/// All fields are visible simultaneously in a macOS `Form`, following the
/// platform's modal-sheet convention for data entry. The form supports
/// income, expense, and transfer transaction types, with a conditional
/// destination account and exchange rate section for cross-currency transfers.
///
/// Triggered from `MacTransactionsView` via `⌘N` (new) or row double-click / Enter (edit).
struct MacTransactionEntryView: View {

    @State private var viewModel: MacTransactionEntryViewModel

    @Environment(\.dismiss) private var dismiss

    /// Callback invoked after a successful save so the parent can refresh.
    let onSave: () -> Void

    // MARK: - Init

    /// Creates the entry view for a new transaction.
    ///
    /// - Parameters:
    ///   - modelContainer: The SwiftData container for repository construction.
    ///   - onSave: Closure called after a successful save.
    init(modelContainer: ModelContainer, onSave: @escaping () -> Void) {
        _viewModel = State(initialValue: MacTransactionEntryViewModel(modelContainer: modelContainer))
        self.onSave = onSave
    }

    /// Creates the entry view pre-populated with an existing transaction (edit mode).
    ///
    /// - Parameters:
    ///   - transaction: The transaction to edit.
    ///   - modelContainer: The SwiftData container for repository construction.
    ///   - onSave: Closure called after a successful save.
    init(
        editing transaction: FinanceCore.Transaction,
        modelContainer: ModelContainer,
        onSave: @escaping () -> Void
    ) {
        _viewModel = State(
            initialValue: MacTransactionEntryViewModel(
                modelContainer: modelContainer,
                transaction: transaction
            )
        )
        self.onSave = onSave
    }

    // MARK: - Body

    var body: some View {
        Form {
            typeSection
            amountSection
            categorySection
            accountSection
            if viewModel.isTransfer {
                destinationSection
            }
            dateSection
            noteSection
        }
        .formStyle(.grouped)
        .navigationTitle(viewModel.isEditing ? "Edit Transaction" : "New Transaction")
        .toolbar {
            cancelButton
            saveButton
        }
        .frame(minWidth: 440, minHeight: 480)
        .task { await viewModel.loadData() }
        .onChange(of: viewModel.didSave) { _, saved in
            if saved {
                onSave()
                dismiss()
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
    }

    // MARK: - Sections

    private var typeSection: some View {
        Section("Type") {
            Picker("Transaction Type", selection: $viewModel.transactionType) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .accessibilityLabel("Transaction type")
        }
    }

    private var amountSection: some View {
        Section("Amount") {
            TextField(
                "Amount",
                text: $viewModel.amountText,
                prompt: Text("0.00 or expression like 10+5")
            )
            .onSubmit { Task { await viewModel.save() } }
        }
    }

    private var categorySection: some View {
        Section("Category") {
            if viewModel.filteredCategories.isEmpty {
                Text("No categories available")
                    .foregroundStyle(.secondary)
            } else {
                Picker(
                    "Category",
                    selection: $viewModel.selectedCategoryID
                ) {
                    Text("Select a category").tag(UUID?.none)
                    ForEach(viewModel.filteredCategories) { category in
                        HStack {
                            Image(systemName: category.iconName)
                                .foregroundStyle(Color(hex: category.colorHex))
                            Text(category.name)
                        }
                        .tag(Optional(category.id))
                    }
                }
            }
        }
    }

    private var accountSection: some View {
        Section("Account") {
            if viewModel.accounts.isEmpty {
                Text("No accounts available")
                    .foregroundStyle(.secondary)
            } else {
                Picker(
                    viewModel.isTransfer ? "From Account" : "Account",
                    selection: $viewModel.selectedAccountID
                ) {
                    Text("Select an account").tag(UUID?.none)
                    ForEach(viewModel.accounts) { account in
                        HStack {
                            Image(systemName: account.iconName)
                                .foregroundStyle(Color(hex: account.colorHex))
                            Text(account.name)
                            Spacer()
                            Text(account.currency.rawValue)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .tag(Optional(account.id))
                    }
                }
            }
        }
    }

    private var destinationSection: some View {
        Section("Transfer Destination") {
            Picker("To Account", selection: $viewModel.toAccountID) {
                Text("Select destination account").tag(UUID?.none)
                ForEach(viewModel.accounts.filter { $0.id != viewModel.selectedAccountID }) { account in
                    HStack {
                        Image(systemName: account.iconName)
                            .foregroundStyle(Color(hex: account.colorHex))
                        Text(account.name)
                        Spacer()
                        Text(account.currency.rawValue)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .tag(Optional(account.id))
                }
            }

            if viewModel.showExchangeRate {
                TextField(
                    "Exchange Rate",
                    text: $viewModel.exchangeRate,
                    prompt: Text("e.g. 23000")
                )
                .help("Enter the exchange rate from source currency to destination currency.")
            }
        }
    }

    private var dateSection: some View {
        Section("Date") {
            DatePicker(
                "Date",
                selection: $viewModel.date,
                displayedComponents: [.date, .hourAndMinute]
            )
        }
    }

    private var noteSection: some View {
        Section("Note") {
            TextField(
                "Note",
                text: $viewModel.note,
                prompt: Text("Optional description"),
                axis: .vertical
            )
            .lineLimit(3...6)
            .onSubmit { Task { await viewModel.save() } }
        }
    }

    // MARK: - Toolbar items

    private var cancelButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
    }

    private var saveButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                Task { await viewModel.save() }
            }
            .disabled(viewModel.isSaving)
            .keyboardShortcut("s", modifiers: .command)
        }
    }
}
