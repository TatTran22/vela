import FinanceCore
import FinanceData
import Foundation
import SwiftData

/// ViewModel for the macOS transaction entry form (create and edit modes).
///
/// Manages field state, data loading, validation, and persistence for the
/// `MacTransactionEntryView` sheet. Supports income, expense, and transfer
/// transaction types, including cross-currency transfers with an exchange rate.
@Observable
@MainActor
final class MacTransactionEntryViewModel {

    // MARK: - Fields

    /// The raw text entered in the amount field.
    var amountText: String = ""

    /// The transaction type selected by the segmented control.
    var transactionType: TransactionType = .expense

    /// The selected category UUID, or nil if not yet chosen.
    var selectedCategoryID: UUID?

    /// The selected source account UUID, or nil if not yet chosen.
    var selectedAccountID: UUID?

    /// The selected destination account UUID for transfer transactions.
    var toAccountID: UUID?

    /// The date of the transaction.
    var date: Date = Date()

    /// Optional free-text note.
    var note: String = ""

    /// Exchange rate text for cross-currency transfers (e.g., "23000").
    var exchangeRate: String = ""

    // MARK: - Save state

    /// Whether a save operation is in progress.
    var isSaving = false

    /// The last domain-level error that occurred, or nil if none.
    var error: TransactionError?

    /// Whether the error alert is visible.
    var showError = false

    /// Set to true after a successful save so the presenting view can dismiss.
    var didSave = false

    // MARK: - Loaded data

    /// All categories available for selection.
    var categories: [FinanceCore.Category] = []

    /// All accounts available for selection.
    var accounts: [Account] = []

    // MARK: - Computed properties

    /// Whether this is a transfer transaction.
    var isTransfer: Bool { transactionType == .transfer }

    /// Categories filtered to match the current transaction type.
    ///
    /// Transfers can use any category; income and expense are filtered to their
    /// matching category type.
    var filteredCategories: [FinanceCore.Category] {
        if transactionType == .transfer {
            return categories
        }
        return categories.filter { $0.type == transactionType }
    }

    /// Whether a cross-currency exchange rate field should be shown.
    ///
    /// Returns `true` when both a source and destination account are selected
    /// and they use different currencies.
    var showExchangeRate: Bool {
        guard isTransfer,
              let fromID = selectedAccountID,
              let toID = toAccountID,
              let fromAccount = accounts.first(where: { $0.id == fromID }),
              let toAccount = accounts.first(where: { $0.id == toID })
        else { return false }
        return fromAccount.currency != toAccount.currency
    }

    // MARK: - Edit mode

    /// The transaction being edited, or nil when creating a new transaction.
    private let editingTransaction: FinanceCore.Transaction?

    /// Whether this view model is in editing mode.
    var isEditing: Bool { editingTransaction != nil }

    // MARK: - Dependencies

    private let createTransactionUseCase: CreateTransactionUseCaseProtocol
    private let updateTransactionUseCase: UpdateTransactionUseCaseProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let accountRepository: AccountRepositoryProtocol

    // MARK: - Init

    /// Creates the view model from a model container, optionally pre-populated for editing.
    ///
    /// - Parameters:
    ///   - modelContainer: The SwiftData container used to instantiate repositories.
    ///   - transaction: When provided, the form will be pre-populated with this transaction's
    ///     values and saving will update rather than create.
    init(modelContainer: ModelContainer, transaction: FinanceCore.Transaction? = nil) {
        let transactionRepo = TransactionRepository(modelContainer: modelContainer)
        let accountRepo = AccountRepository(modelContainer: modelContainer)
        let categoryRepo = CategoryRepository(modelContainer: modelContainer)

        self.createTransactionUseCase = CreateTransactionUseCase(
            transactionRepository: transactionRepo,
            accountRepository: accountRepo,
            categoryRepository: categoryRepo
        )
        self.updateTransactionUseCase = UpdateTransactionUseCase(
            transactionRepository: transactionRepo,
            accountRepository: accountRepo,
            categoryRepository: categoryRepo
        )
        self.categoryRepository = categoryRepo
        self.accountRepository = accountRepo
        self.editingTransaction = transaction

        populateFields(from: transaction)
    }

    /// Dependency-injection initialiser used for testing or custom composition.
    init(
        createTransactionUseCase: CreateTransactionUseCaseProtocol,
        updateTransactionUseCase: UpdateTransactionUseCaseProtocol,
        categoryRepository: CategoryRepositoryProtocol,
        accountRepository: AccountRepositoryProtocol,
        transaction: FinanceCore.Transaction? = nil
    ) {
        self.createTransactionUseCase = createTransactionUseCase
        self.updateTransactionUseCase = updateTransactionUseCase
        self.categoryRepository = categoryRepository
        self.accountRepository = accountRepository
        self.editingTransaction = transaction

        populateFields(from: transaction)
    }

    // MARK: - Data Loading

    /// Loads categories and accounts for use in pickers.
    func loadData() async {
        async let categoriesResult: [FinanceCore.Category] = fetchCategories()
        async let accountsResult: [Account] = fetchAccounts()

        categories = await categoriesResult
        accounts = await accountsResult

        // Default to first account if none selected yet
        if selectedAccountID == nil, let first = accounts.first {
            selectedAccountID = first.id
        }
    }

    // MARK: - Save

    /// Validates and saves the transaction, either creating or updating.
    ///
    /// Sets `didSave` to `true` on success, or `showError` to `true` on failure.
    func save() async {
        guard let amount = parseAmount(), amount > 0 else {
            error = .amountMustBePositive
            showError = true
            return
        }

        guard let categoryID = selectedCategoryID else {
            error = .categoryRequired
            showError = true
            return
        }

        guard let accountID = selectedAccountID else {
            error = .accountNotFound(UUID())
            showError = true
            return
        }

        if transactionType == .transfer {
            guard toAccountID != nil else {
                error = .destinationAccountRequired
                showError = true
                return
            }
        }

        isSaving = true
        error = nil

        var metadata: [String: String]?
        if showExchangeRate, !exchangeRate.isEmpty {
            metadata = ["exchangeRate": exchangeRate]
        }

        let transaction = FinanceCore.Transaction(
            id: editingTransaction?.id ?? UUID(),
            amount: amount,
            type: transactionType,
            categoryID: categoryID,
            accountID: accountID,
            toAccountID: transactionType == .transfer ? toAccountID : nil,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            isRecurring: editingTransaction?.isRecurring ?? false,
            tags: editingTransaction?.tags ?? [],
            metadata: metadata,
            createdAt: editingTransaction?.createdAt ?? Date(),
            updatedAt: Date()
        )

        do {
            if isEditing {
                _ = try await updateTransactionUseCase.execute(transaction)
            } else {
                _ = try await createTransactionUseCase.execute(transaction)
            }
            didSave = true
        } catch let txError as TransactionError {
            error = txError
            showError = true
        } catch {
            self.error = .invalidExpression(error.localizedDescription)
            showError = true
        }

        isSaving = false
    }

    // MARK: - Private Helpers

    private func fetchCategories() async -> [FinanceCore.Category] {
        (try? await categoryRepository.fetchAll(type: nil)) ?? []
    }

    private func fetchAccounts() async -> [Account] {
        (try? await accountRepository.fetchAll()) ?? []
    }

    /// Parses the `amountText` using `QuickAmountParser`, falling back to plain `Decimal` parsing.
    ///
    /// - Returns: The parsed `Decimal` amount, or nil if the text is not parseable.
    private func parseAmount() -> Decimal? {
        let trimmed = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
        let parser = QuickAmountParser()
        if let parsed = try? parser.parse(trimmed) {
            return parsed
        }
        return Decimal(string: trimmed)
    }

    /// Pre-populates form fields from an existing transaction (edit mode).
    ///
    /// - Parameter transaction: The transaction to read values from, or nil for a blank form.
    private func populateFields(from transaction: FinanceCore.Transaction?) {
        guard let tx = transaction else { return }
        amountText = "\(tx.amount)"
        transactionType = tx.type
        selectedCategoryID = tx.categoryID
        selectedAccountID = tx.accountID
        toAccountID = tx.toAccountID
        date = tx.date
        note = tx.note
        exchangeRate = tx.metadata?["exchangeRate"] ?? ""
    }
}
