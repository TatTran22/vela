import FinanceCore
import Foundation
import Observation

/// ViewModel for the transaction list screen.
///
/// Manages loading, paginating, searching, and filtering transactions grouped
/// by date. Provides state for the filter sheet (accounts and categories) and
/// triggers deletion of individual transactions.
@Observable
@MainActor
final class TransactionListViewModel {
    // MARK: - State

    /// Transactions grouped by calendar day, ordered newest-first.
    var groupedTransactions: [(Date, [FinanceCore.Transaction])] = []

    /// Per-day income and expense totals keyed by midnight-normalised date.
    var dailyTotals: [Date: (income: Decimal, expense: Decimal)] = [:]

    /// Active filter applied to the transaction list.
    var filter: TransactionFilter = TransactionFilter()

    /// Current search query text.
    var searchText: String = ""

    /// Whether a network or data operation is in progress.
    var isLoading = false

    /// Current domain error, if any.
    var error: TransactionError?

    /// Whether to display the error alert.
    var showError = false

    /// Whether more pages are available for infinite scroll.
    var hasMore = true

    /// All accounts, used to populate the filter sheet.
    var accounts: [Account] = []

    /// All categories, used to populate the filter sheet.
    var categories: [FinanceCore.Category] = []

    // MARK: - Dependencies

    private let getTransactionsUseCase: GetTransactionsUseCaseProtocol
    private let deleteTransactionUseCase: DeleteTransactionUseCaseProtocol
    private let searchUseCase: TransactionSearchUseCaseProtocol
    private let accountRepository: AccountRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol

    // MARK: - Pagination

    private var currentOffset = 0
    private let pageSize = 50

    // MARK: - Search debounce

    private var searchTask: Task<Void, Never>?

    // MARK: - Initialization

    /// Creates a new transaction list view model.
    ///
    /// - Parameters:
    ///   - getTransactionsUseCase: Use case for fetching and grouping transactions.
    ///   - deleteTransactionUseCase: Use case for soft-deleting a transaction.
    ///   - searchUseCase: Use case for free-text search.
    ///   - accountRepository: Repository used to populate the filter sheet's account list.
    ///   - categoryRepository: Repository used to populate the filter sheet's category list.
    init(
        getTransactionsUseCase: GetTransactionsUseCaseProtocol,
        deleteTransactionUseCase: DeleteTransactionUseCaseProtocol,
        searchUseCase: TransactionSearchUseCaseProtocol,
        accountRepository: AccountRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol
    ) {
        self.getTransactionsUseCase = getTransactionsUseCase
        self.deleteTransactionUseCase = deleteTransactionUseCase
        self.searchUseCase = searchUseCase
        self.accountRepository = accountRepository
        self.categoryRepository = categoryRepository
    }

    // MARK: - Actions

    /// Resets pagination and loads the first page of transactions.
    ///
    /// Also fetches accounts and categories for the filter sheet,
    /// and computes daily totals for the current filter.
    func loadTransactions() async {
        isLoading = true
        error = nil
        currentOffset = 0

        do {
            async let transactionGroups = getTransactionsUseCase.executeGrouped(filter: filter)
            async let fetchedAccounts = accountRepository.fetchAll()
            async let fetchedCategories = categoryRepository.fetchAll(type: nil)
            async let totals = getTransactionsUseCase.dailyTotals(filter: filter)

            let (groups, allAccounts, allCategories, dailyData) = try await (
                transactionGroups, fetchedAccounts, fetchedCategories, totals
            )

            groupedTransactions = groups
            accounts = allAccounts
            categories = allCategories

            var totalsMap: [Date: (income: Decimal, expense: Decimal)] = [:]
            for entry in dailyData {
                totalsMap[entry.date] = (income: entry.income, expense: entry.expense)
            }
            dailyTotals = totalsMap

            // Determine if there are more items for pagination
            let flatCount = groups.reduce(0) { $0 + $1.1.count }
            hasMore = flatCount >= pageSize
            currentOffset = flatCount
        } catch let txError as TransactionError {
            error = txError
            showError = true
        } catch {
            self.error = .transactionNotFound(UUID())
            showError = true
        }

        isLoading = false
    }

    /// Loads the next page of transactions and appends them to existing groups.
    func loadMore() async {
        guard hasMore, !isLoading else { return }
        isLoading = true

        do {
            let nextPage = try await getTransactionsUseCase.execute(
                filter: filter,
                offset: currentOffset,
                limit: pageSize
            )

            if nextPage.isEmpty {
                hasMore = false
            } else {
                // Merge the new page into existing groups by date
                mergeIntoGroups(nextPage)
                currentOffset += nextPage.count
                hasMore = nextPage.count >= pageSize
            }
        } catch let txError as TransactionError {
            error = txError
            showError = true
        } catch {
            // Silent failure for pagination errors; existing data is preserved
        }

        isLoading = false
    }

    /// Soft-deletes a transaction by ID and refreshes the list.
    ///
    /// - Parameter id: The identifier of the transaction to delete.
    func deleteTransaction(_ id: UUID) async {
        do {
            try await deleteTransactionUseCase.execute(id: id)
            await loadTransactions()
        } catch let txError as TransactionError {
            error = txError
            showError = true
        } catch {
            self.error = .transactionNotFound(id)
            showError = true
        }
    }

    /// Refreshes the transaction list from scratch.
    func refresh() async {
        await loadTransactions()
    }

    /// Applies the current filter and reloads transactions from the start.
    func applyFilter() async {
        await loadTransactions()
    }

    /// Schedules a debounced search using the current `searchText`.
    ///
    /// Waits 300 ms before executing to avoid excessive queries while typing.
    func search() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await performSearch()
        }
    }

    // MARK: - Private Helpers

    private func performSearch() async {
        isLoading = true
        error = nil

        do {
            let results = try await searchUseCase.execute(query: searchText, filter: filter)
            groupedTransactions = groupByDate(results)
        } catch let txError as TransactionError {
            error = txError
            showError = true
        } catch {
            // Silent failure for search errors
        }

        isLoading = false
    }

    /// Groups a flat array of transactions by calendar day (midnight-normalised).
    private func groupByDate(_ transactions: [FinanceCore.Transaction]) -> [(Date, [FinanceCore.Transaction])] {
        let calendar = Calendar.current
        var groups: [Date: [FinanceCore.Transaction]] = [:]
        for transaction in transactions {
            let day = calendar.startOfDay(for: transaction.date)
            groups[day, default: []].append(transaction)
        }
        return groups.sorted { $0.key > $1.key }.map { ($0.key, $0.value) }
    }

    /// Merges a new page of transactions into the existing grouped structure.
    private func mergeIntoGroups(_ newTransactions: [FinanceCore.Transaction]) {
        let calendar = Calendar.current
        var existing: [Date: [FinanceCore.Transaction]] = Dictionary(
            uniqueKeysWithValues: groupedTransactions
        )
        for transaction in newTransactions {
            let day = calendar.startOfDay(for: transaction.date)
            existing[day, default: []].append(transaction)
        }
        groupedTransactions = existing.sorted { $0.key > $1.key }.map { ($0.key, $0.value) }
    }
}
