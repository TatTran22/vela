import FinanceCore
import FinanceData
import FinanceUI
import SwiftData
import SwiftUI

/// Main view for the transaction list screen.
///
/// Displays transactions grouped by calendar day with date group headers showing
/// daily income/expense totals. Supports searching, filtering, pull-to-refresh,
/// infinite scroll, and swipe-to-delete/edit actions. A floating action button
/// opens the quick-entry sheet.
struct TransactionListView: View {
    @State private var viewModel: TransactionListViewModel
    @State private var showingFilter = false
    @State private var showingQuickInput = false
    @State private var showingTransfer = false
    @Environment(\.modelContext) private var modelContext

    // MARK: - Initialization

    /// Creates a new transaction list view.
    /// - Parameter viewModel: The view model managing transaction data.
    init(viewModel: TransactionListViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Computed Maps

    /// O(1) category lookup by ID.
    private var categoryMap: [UUID: FinanceCore.Category] {
        Dictionary(uniqueKeysWithValues: viewModel.categories.map { ($0.id, $0) })
    }

    /// O(1) account lookup by ID.
    private var accountMap: [UUID: Account] {
        Dictionary(uniqueKeysWithValues: viewModel.accounts.map { ($0.id, $0) })
    }

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.groupedTransactions.isEmpty {
                ProgressView()
                    .accessibilityLabel("Loading transactions.")
            } else if viewModel.groupedTransactions.isEmpty {
                emptyState
            } else {
                transactionList
            }
        }
        .navigationTitle(AppStrings.transactionListTitle)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: AppStrings.transactionListSearchPrompt
        )
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.search()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                filterButton
            }
            ToolbarItem(placement: .secondaryAction) {
                transferButton
            }
        }
        .sheet(isPresented: $showingFilter) {
            TransactionFilterSheet(
                filter: $viewModel.filter,
                accounts: viewModel.accounts,
                categories: viewModel.categories,
                onApply: {
                    showingFilter = false
                    Task { await viewModel.applyFilter() }
                },
                onClear: {
                    viewModel.filter = TransactionFilter()
                    Task { await viewModel.applyFilter() }
                }
            )
        }
        .sheet(isPresented: $showingQuickInput) {
            NavigationStack {
                QuickInputView(viewModel: makeQuickInputViewModel())
            }
            .onDisappear {
                Task { await viewModel.refresh() }
            }
        }
        .sheet(isPresented: $showingTransfer) {
            NavigationStack {
                TransferView(viewModel: makeTransferViewModel())
            }
            .onDisappear {
                Task { await viewModel.refresh() }
            }
        }
        .alert(AppStrings.error, isPresented: $viewModel.showError) {
            Button(AppStrings.ok) {}
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .task {
            await viewModel.loadTransactions()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .overlay(alignment: .bottomTrailing) {
            fabButton
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView {
            Label(AppStrings.transactionListEmptyTitle, systemImage: "list.bullet.rectangle")
        } description: {
            Text(AppStrings.transactionListEmptySubtitle)
        } actions: {
            Button(AppStrings.transactionListEmptyAction) {
                showingQuickInput = true
            }
            .buttonStyle(.borderedProminent)
        }
        .accessibilityLabel("No transactions found. Tap Add Transaction to create one.")
    }

    private var transactionList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                ForEach(viewModel.groupedTransactions, id: \.0) { date, transactions in
                    dateGroup(date: date, transactions: transactions)
                }

                if viewModel.hasMore {
                    ProgressView()
                        .padding()
                        .task {
                            await viewModel.loadMore()
                        }
                }
            }
        }
        .navigationDestination(for: FinanceCore.Transaction.self) { transaction in
            TransactionDetailView(viewModel: makeDetailViewModel(for: transaction))
        }
    }

    private func dateGroup(date: Date, transactions: [FinanceCore.Transaction]) -> some View {
        let totals = viewModel.dailyTotals[date]
        return Section {
            DateGroupHeader(
                date: date,
                income: totals?.income ?? 0,
                expense: totals?.expense ?? 0,
                currencyCode: .VND
            )

            ForEach(transactions) { transaction in
                NavigationLink(value: transaction) {
                    transactionRow(for: transaction)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    deleteAction(for: transaction)
                }
                .swipeActions(edge: .leading) {
                    editAction(for: transaction)
                }

                Divider()
                    .padding(.leading, 72)
            }
        }
    }

    private func transactionRow(for transaction: FinanceCore.Transaction) -> some View {
        let category = categoryMap[transaction.categoryID]
        let account = accountMap[transaction.accountID]
        return TransactionRow(
            transaction: transaction,
            categoryName: category?.name ?? AppStrings.transactionDetailUnknown,
            categoryIcon: category?.iconName ?? "questionmark.circle",
            categoryColor: category?.colorHex ?? "#8E8E93",
            accountName: account?.name ?? AppStrings.transactionDetailUnknown,
            currencyCode: account?.currency ?? .VND
        )
        .padding(.horizontal, 16)
    }

    private func deleteAction(for transaction: FinanceCore.Transaction) -> some View {
        Button(role: .destructive) {
            Task {
                await viewModel.deleteTransaction(transaction.id)
            }
        } label: {
            Label(AppStrings.delete, systemImage: "trash")
        }
        .accessibilityLabel("Delete transaction.")
    }

    private func editAction(for transaction: FinanceCore.Transaction) -> some View {
        NavigationLink(value: transaction) {
            Label(AppStrings.edit, systemImage: "pencil")
        }
        .tint(.blue)
        .accessibilityLabel("Edit transaction.")
    }

    private var filterButton: some View {
        let hasActiveFilter = viewModel.filter != TransactionFilter()
        return Button {
            showingFilter = true
        } label: {
            Image(systemName: hasActiveFilter ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel(hasActiveFilter ? "Filter active. Tap to modify." : "Filter transactions.")
    }

    private var transferButton: some View {
        Button {
            showingTransfer = true
        } label: {
            Image(systemName: "arrow.left.arrow.right")
        }
        .accessibilityLabel("Create a transfer between accounts.")
    }

    private var fabButton: some View {
        Button {
            showingQuickInput = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 24)
        .accessibilityLabel("Add new transaction.")
        .accessibilityHint("Opens the quick transaction entry form.")
    }

    // MARK: - Factory Methods

    private func makeDetailViewModel(for transaction: FinanceCore.Transaction) -> TransactionDetailViewModel {
        let container = modelContext.container
        let transactionRepo = TransactionRepository(modelContainer: container)
        let accountRepo = AccountRepository(modelContainer: container)
        let categoryRepo = CategoryRepository(modelContainer: container)
        let updateUseCase = UpdateTransactionUseCase(
            transactionRepository: transactionRepo,
            accountRepository: accountRepo,
            categoryRepository: categoryRepo
        )
        let deleteUseCase = DeleteTransactionUseCase(
            transactionRepository: transactionRepo,
            accountRepository: accountRepo
        )
        return TransactionDetailViewModel(
            transaction: transaction,
            updateTransactionUseCase: updateUseCase,
            deleteTransactionUseCase: deleteUseCase,
            categoryRepository: categoryRepo,
            accountRepository: accountRepo
        )
    }

    private func makeQuickInputViewModel() -> QuickInputViewModel {
        let container = modelContext.container
        let transactionRepo = TransactionRepository(modelContainer: container)
        let accountRepo = AccountRepository(modelContainer: container)
        let categoryRepo = CategoryRepository(modelContainer: container)
        let createUseCase = CreateTransactionUseCase(
            transactionRepository: transactionRepo,
            accountRepository: accountRepo,
            categoryRepository: categoryRepo
        )
        return QuickInputViewModel(
            createTransactionUseCase: createUseCase,
            categoryRepository: categoryRepo,
            accountRepository: accountRepo
        )
    }

    private func makeTransferViewModel() -> TransferViewModel {
        let container = modelContext.container
        let transactionRepo = TransactionRepository(modelContainer: container)
        let accountRepo = AccountRepository(modelContainer: container)
        let categoryRepo = CategoryRepository(modelContainer: container)
        let createUseCase = CreateTransactionUseCase(
            transactionRepository: transactionRepo,
            accountRepository: accountRepo,
            categoryRepository: categoryRepo
        )
        return TransferViewModel(
            createTransactionUseCase: createUseCase,
            accountRepository: accountRepo,
            categoryRepository: categoryRepo
        )
    }
}
