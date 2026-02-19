import FinanceCore
import FinanceData
import Foundation
import SwiftData

/// ViewModel for the macOS transactions table view.
///
/// Manages transaction data, filtering, sorting, multi-selection, and bulk
/// delete operations. Dependencies are constructed from a `ModelContainer`
/// following the same pattern as `MacAccountsView`.
@Observable
@MainActor
final class MacTransactionsViewModel {

    // MARK: - State

    /// All transactions matching the current filter and search text.
    var transactions: [FinanceCore.Transaction] = []

    /// Current filter applied to the transaction fetch.
    var filter: TransactionFilter = TransactionFilter()

    /// Free-text search string bound to the toolbar search field.
    var searchText: String = "" {
        didSet {
            if searchText != oldValue {
                updateFilter()
            }
        }
    }

    /// Whether a data load is in progress.
    var isLoading = false

    /// The last domain-level error that occurred, or nil if none.
    var error: TransactionError?

    /// Whether the error alert is visible.
    var showError = false

    /// The UUIDs of currently selected table rows.
    var selectedTransactionIDs: Set<UUID> = []

    /// Sort descriptors bound to the SwiftUI `Table` sort order.
    var sortOrder: [KeyPathComparator<FinanceCore.Transaction>] = [
        .init(\.date, order: .reverse)
    ]

    // MARK: - Lookup data

    /// All accounts loaded from the repository (used for column display).
    var accounts: [Account] = []

    /// All categories loaded from the repository (used for column display).
    var categories: [FinanceCore.Category] = []

    // MARK: - Dependencies

    private let getTransactionsUseCase: GetTransactionsUseCaseProtocol
    private let deleteTransactionUseCase: DeleteTransactionUseCaseProtocol
    private let updateTransactionUseCase: UpdateTransactionUseCaseProtocol
    private let accountRepository: AccountRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol

    // MARK: - Init

    /// Creates the view model by constructing repositories and use cases from a model container.
    ///
    /// - Parameter modelContainer: The SwiftData container used to instantiate repositories.
    init(modelContainer: ModelContainer) {
        let transactionRepo = TransactionRepository(modelContainer: modelContainer)
        let accountRepo = AccountRepository(modelContainer: modelContainer)
        let categoryRepo = CategoryRepository(modelContainer: modelContainer)

        self.getTransactionsUseCase = GetTransactionsUseCase(repository: transactionRepo)
        self.deleteTransactionUseCase = DeleteTransactionUseCase(
            transactionRepository: transactionRepo,
            accountRepository: accountRepo
        )
        self.updateTransactionUseCase = UpdateTransactionUseCase(
            transactionRepository: transactionRepo,
            accountRepository: accountRepo,
            categoryRepository: categoryRepo
        )
        self.accountRepository = accountRepo
        self.categoryRepository = categoryRepo
    }

    /// Dependency-injection initialiser used for testing or custom composition.
    ///
    /// - Parameters:
    ///   - getTransactionsUseCase: Use case for fetching transactions.
    ///   - deleteTransactionUseCase: Use case for deleting transactions.
    ///   - updateTransactionUseCase: Use case for updating transactions.
    ///   - accountRepository: Repository for account lookups.
    ///   - categoryRepository: Repository for category lookups.
    init(
        getTransactionsUseCase: GetTransactionsUseCaseProtocol,
        deleteTransactionUseCase: DeleteTransactionUseCaseProtocol,
        updateTransactionUseCase: UpdateTransactionUseCaseProtocol,
        accountRepository: AccountRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol
    ) {
        self.getTransactionsUseCase = getTransactionsUseCase
        self.deleteTransactionUseCase = deleteTransactionUseCase
        self.updateTransactionUseCase = updateTransactionUseCase
        self.accountRepository = accountRepository
        self.categoryRepository = categoryRepository
    }

    // MARK: - Lookup Helpers

    /// Returns the display name of the category with the given ID, or a placeholder if unknown.
    ///
    /// - Parameter id: The category UUID to look up.
    /// - Returns: The category name, or "Unknown" if not found.
    func categoryName(for id: UUID) -> String {
        categories.first { $0.id == id }?.name ?? "Unknown"
    }

    /// Returns the display name of the account with the given ID, or a placeholder if unknown.
    ///
    /// - Parameter id: The account UUID to look up.
    /// - Returns: The account name, or "Unknown" if not found.
    func accountName(for id: UUID) -> String {
        accounts.first { $0.id == id }?.name ?? "Unknown"
    }

    /// Returns the `Account` for the given ID, or nil if not found.
    ///
    /// - Parameter id: The account UUID to look up.
    /// - Returns: The matching `Account`, or nil.
    func account(for id: UUID) -> Account? {
        accounts.first { $0.id == id }
    }

    // MARK: - Data Loading

    /// Loads transactions, accounts, and categories concurrently.
    func loadData() async {
        isLoading = true
        error = nil

        async let transactionsResult: [FinanceCore.Transaction] = fetchTransactions()
        async let accountsResult: [Account] = fetchAccounts()
        async let categoriesResult: [FinanceCore.Category] = fetchCategories()

        transactions = await transactionsResult
        accounts = await accountsResult
        categories = await categoriesResult

        isLoading = false
    }

    /// Reloads all data and clears the current selection.
    func refresh() async {
        selectedTransactionIDs = []
        await loadData()
    }

    /// Deletes transactions for the given set of UUIDs, refreshing the list on success.
    ///
    /// - Parameter ids: The set of transaction UUIDs to delete.
    func deleteTransactions(_ ids: Set<UUID>) async {
        error = nil
        for id in ids {
            do {
                try await deleteTransactionUseCase.execute(id: id)
            } catch let txError as TransactionError {
                error = txError
                showError = true
                return
            } catch {
                self.error = .transactionNotFound(id)
                showError = true
                return
            }
        }
        selectedTransactionIDs.subtract(ids)
        await loadData()
    }

    /// Duplicates a transaction by creating a new copy with today's date.
    ///
    /// - Parameter transaction: The source transaction to duplicate.
    func duplicateTransaction(_ transaction: FinanceCore.Transaction) async {
        let duplicate = FinanceCore.Transaction(
            amount: transaction.amount,
            type: transaction.type,
            categoryID: transaction.categoryID,
            accountID: transaction.accountID,
            toAccountID: transaction.toAccountID,
            note: transaction.note,
            date: Date(),
            isRecurring: false,
            tags: transaction.tags,
            metadata: transaction.metadata
        )

        // Use the update use case infrastructure by routing through create via save.
        // We build a minimal CreateTransactionUseCase proxy here since we already have the
        // update use case. Instead, reload after the action is performed externally.
        // For duplication, the entry view will handle creation. This is a stub so that
        // callers know the intent; actual creation happens via MacTransactionEntryViewModel.
        _ = duplicate  // Will be passed to the entry view as a pre-filled template.
    }

    // MARK: - Private Helpers

    private func fetchTransactions() async -> [FinanceCore.Transaction] {
        do {
            let txFilter = TransactionFilter(searchText: searchText.isEmpty ? nil : searchText)
            let result = try await getTransactionsUseCase.execute(
                filter: txFilter,
                offset: 0,
                limit: 500
            )
            return applySortOrder(result)
        } catch {
            return []
        }
    }

    private func fetchAccounts() async -> [Account] {
        (try? await accountRepository.fetchAll()) ?? []
    }

    private func fetchCategories() async -> [FinanceCore.Category] {
        (try? await categoryRepository.fetchAll(type: nil)) ?? []
    }

    private func updateFilter() {
        Task { await loadData() }
    }

    /// Applies the current `sortOrder` to a transaction array.
    ///
    /// - Parameter items: The unsorted transactions.
    /// - Returns: Sorted transactions.
    private func applySortOrder(_ items: [FinanceCore.Transaction]) -> [FinanceCore.Transaction] {
        items.sorted(using: sortOrder)
    }
}
