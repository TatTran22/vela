import FinanceCore
import Foundation
import Observation

/// ViewModel for the transaction detail and inline-edit screen.
///
/// Loads the associated category and account names on appearance,
/// then supports toggling into edit mode where the user can change
/// the amount, note, date, and category before saving.
@Observable
@MainActor
final class TransactionDetailViewModel {
    // MARK: - State

    /// The transaction being displayed.
    var transaction: FinanceCore.Transaction

    /// The resolved category for the transaction, if found.
    var category: FinanceCore.Category?

    /// The resolved source account for the transaction, if found.
    var account: Account?

    /// The resolved destination account for transfers, if found.
    var toAccount: Account?

    /// Whether the view is in edit mode.
    var isEditing = false

    /// Whether a deletion is in progress.
    var isDeleting = false

    /// Current domain error, if any.
    var error: TransactionError?

    /// Whether to show the error alert.
    var showError = false

    /// Whether to show the delete confirmation dialog.
    var showDeleteConfirmation = false

    /// Set to true after a successful delete; triggers navigation pop.
    var didDelete = false

    // MARK: - Edit State

    /// Raw amount string during editing.
    var editAmount: String = ""

    /// Free-text note during editing.
    var editNote: String = ""

    /// Date during editing.
    var editDate: Date = Date()

    /// Selected category during editing.
    var editCategory: FinanceCore.Category?

    /// All available categories for the category picker during editing.
    var availableCategories: [FinanceCore.Category] = []

    // MARK: - Dependencies

    private let updateTransactionUseCase: UpdateTransactionUseCaseProtocol
    private let deleteTransactionUseCase: DeleteTransactionUseCaseProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let accountRepository: AccountRepositoryProtocol

    // MARK: - Initialization

    /// Creates a new transaction detail view model.
    ///
    /// - Parameters:
    ///   - transaction: The transaction to display.
    ///   - updateTransactionUseCase: Use case for persisting edits.
    ///   - deleteTransactionUseCase: Use case for soft-deleting the transaction.
    ///   - categoryRepository: Repository for resolving category details.
    ///   - accountRepository: Repository for resolving account details.
    init(
        transaction: FinanceCore.Transaction,
        updateTransactionUseCase: UpdateTransactionUseCaseProtocol,
        deleteTransactionUseCase: DeleteTransactionUseCaseProtocol,
        categoryRepository: CategoryRepositoryProtocol,
        accountRepository: AccountRepositoryProtocol
    ) {
        self.transaction = transaction
        self.updateTransactionUseCase = updateTransactionUseCase
        self.deleteTransactionUseCase = deleteTransactionUseCase
        self.categoryRepository = categoryRepository
        self.accountRepository = accountRepository
    }

    // MARK: - Actions

    /// Fetches category and account data for the current transaction.
    func loadDetails() async {
        do {
            async let fetchedCategory = categoryRepository.fetch(by: transaction.categoryID)
            async let fetchedAccount = accountRepository.fetch(by: transaction.accountID)
            async let allCategories = categoryRepository.fetchAll(type: nil)

            let (cat, acc, cats) = try await (fetchedCategory, fetchedAccount, allCategories)
            category = cat
            account = acc
            availableCategories = cats

            if let toAccountID = transaction.toAccountID {
                toAccount = try await accountRepository.fetch(by: toAccountID)
            }
        } catch {
            // Silent failure: detail labels fall back to "Unknown"
        }
    }

    /// Enters edit mode and seeds the edit fields from the current transaction.
    func startEditing() {
        editAmount = "\(transaction.amount)"
        editNote = transaction.note
        editDate = transaction.date
        editCategory = category
        isEditing = true
    }

    /// Exits edit mode without saving changes.
    func cancelEditing() {
        isEditing = false
        error = nil
    }

    /// Validates and saves the edited transaction.
    func saveEdit() async {
        guard let parsedAmount = Decimal(string: editAmount), parsedAmount > 0 else {
            error = .amountMustBePositive
            showError = true
            return
        }
        guard let category = editCategory else {
            error = .categoryRequired
            showError = true
            return
        }

        var updated = transaction
        updated.amount = parsedAmount
        updated.note = editNote
        updated.date = editDate
        updated.categoryID = category.id
        updated.updatedAt = Date()

        do {
            let saved = try await updateTransactionUseCase.execute(updated)
            transaction = saved
            self.category = editCategory
            isEditing = false
        } catch let txError as TransactionError {
            error = txError
            showError = true
        } catch {
            self.error = .transactionNotFound(transaction.id)
            showError = true
        }
    }

    /// Soft-deletes the transaction and sets `didDelete` to trigger navigation pop.
    func deleteTransaction() async {
        isDeleting = true

        do {
            try await deleteTransactionUseCase.execute(id: transaction.id)
            didDelete = true
        } catch let txError as TransactionError {
            error = txError
            showError = true
        } catch {
            self.error = .transactionNotFound(transaction.id)
            showError = true
        }

        isDeleting = false
    }
}
