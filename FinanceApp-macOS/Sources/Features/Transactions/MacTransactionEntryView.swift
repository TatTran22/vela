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
        .navigationTitle(viewModel.isEditing ? AppStrings.transactionEdit : AppStrings.transactionNew)
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
            AppStrings.error,
            isPresented: $viewModel.showError,
            actions: {
                Button(AppStrings.ok) { viewModel.showError = false }
            },
            message: {
                Text(viewModel.error?.localizedDescription ?? "An unknown error occurred.")
            }
        )
    }

    // MARK: - Sections

    private var typeSection: some View {
        Section(AppStrings.entryType) {
            Picker(AppStrings.entryType, selection: $viewModel.transactionType) {
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
        Section(AppStrings.entryAmount) {
            TextField(
                AppStrings.entryAmount,
                text: $viewModel.amountText,
                prompt: Text("0.00 or expression like 10+5")
            )
            .onSubmit { Task { await viewModel.save() } }
        }
    }

    private var categorySection: some View {
        Section(AppStrings.entryCategory) {
            if viewModel.filteredCategories.isEmpty {
                Text(AppStrings.entryNoCategoriesAvailable)
                    .foregroundStyle(.secondary)
            } else {
                Picker(
                    AppStrings.entryCategory,
                    selection: $viewModel.selectedCategoryID
                ) {
                    Text(AppStrings.entrySelectCategory).tag(UUID?.none)
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
        Section(AppStrings.entryAccount) {
            if viewModel.accounts.isEmpty {
                Text(AppStrings.entryNoAccountsAvailable)
                    .foregroundStyle(.secondary)
            } else {
                Picker(
                    viewModel.isTransfer ? AppStrings.entryFromAccount : AppStrings.entryAccount,
                    selection: $viewModel.selectedAccountID
                ) {
                    Text(AppStrings.entrySelectAccount).tag(UUID?.none)
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
        Section(AppStrings.entryTransferDestination) {
            Picker(AppStrings.entryToAccount, selection: $viewModel.toAccountID) {
                Text(AppStrings.entrySelectDestination).tag(UUID?.none)
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
                    AppStrings.entryExchangeRate,
                    text: $viewModel.exchangeRate,
                    prompt: Text("e.g. 23000")
                )
                .help("Enter the exchange rate from source currency to destination currency.")
            }
        }
    }

    private var dateSection: some View {
        Section(AppStrings.entryDate) {
            DatePicker(
                AppStrings.entryDate,
                selection: $viewModel.date,
                displayedComponents: [.date, .hourAndMinute]
            )
        }
    }

    private var noteSection: some View {
        Section(AppStrings.entryNote) {
            TextField(
                AppStrings.entryNote,
                text: $viewModel.note,
                prompt: Text(AppStrings.entryOptionalDescription),
                axis: .vertical
            )
            .lineLimit(3...6)
            .onSubmit { Task { await viewModel.save() } }
        }
    }

    // MARK: - Toolbar items

    private var cancelButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(AppStrings.cancel) { dismiss() }
        }
    }

    private var saveButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(AppStrings.save) {
                Task { await viewModel.save() }
            }
            .disabled(viewModel.isSaving)
            .keyboardShortcut("s", modifiers: .command)
        }
    }
}
