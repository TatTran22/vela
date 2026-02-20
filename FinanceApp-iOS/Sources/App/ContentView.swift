import FinanceCore
import FinanceData
import SwiftData
import SwiftUI

/// Root view with tab-based navigation for iOS
struct ContentView: View {
    @State private var selectedTab: AppTab = .dashboard
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppStrings.tabDashboard, systemImage: "house.fill", value: .dashboard) {
                NavigationStack {
                    DashboardPlaceholderView()
                }
            }

            Tab(AppStrings.tabTransactions, systemImage: "list.bullet", value: .transactions) {
                NavigationStack {
                    TransactionListView(viewModel: makeTransactionListViewModel())
                }
            }

            Tab(AppStrings.tabAccounts, systemImage: "creditcard.fill", value: .accounts) {
                NavigationStack {
                    AccountListView(viewModel: makeAccountListViewModel())
                }
            }

            Tab(AppStrings.tabCategories, systemImage: "folder.fill", value: .categories) {
                NavigationStack {
                    CategoryListView(viewModel: makeCategoryListViewModel())
                }
            }

            Tab(AppStrings.tabReports, systemImage: "chart.pie.fill", value: .reports) {
                NavigationStack {
                    ReportsPlaceholderView()
                }
            }

            Tab(AppStrings.tabSettings, systemImage: "gearshape.fill", value: .settings) {
                NavigationStack {
                    SettingsPlaceholderView()
                }
            }
        }
    }

    // MARK: - Factory Methods

    /// Creates the view model for the transaction list with all dependencies.
    private func makeTransactionListViewModel() -> TransactionListViewModel {
        let container = modelContext.container
        let transactionRepo = TransactionRepository(modelContainer: container)
        let accountRepo = AccountRepository(modelContainer: container)
        let categoryRepo = CategoryRepository(modelContainer: container)
        let getTransactions = GetTransactionsUseCase(repository: transactionRepo)
        let deleteTransaction = DeleteTransactionUseCase(
            transactionRepository: transactionRepo,
            accountRepository: accountRepo
        )
        let searchUseCase = TransactionSearchUseCase(repository: transactionRepo)
        return TransactionListViewModel(
            getTransactionsUseCase: getTransactions,
            deleteTransactionUseCase: deleteTransaction,
            searchUseCase: searchUseCase,
            accountRepository: accountRepo,
            categoryRepository: categoryRepo
        )
    }

    /// Creates the view model for the category list with all dependencies.
    private func makeCategoryListViewModel() -> CategoryListViewModel {
        let container = modelContext.container
        let repository = CategoryRepository(modelContainer: container)
        let getCategories = GetCategoriesUseCase(repository: repository)
        let deleteCategory = DeleteCategoryUseCase(repository: repository)
        let reorderCategories = ReorderCategoriesUseCase(repository: repository)

        return CategoryListViewModel(
            getCategoriesUseCase: getCategories,
            deleteCategoryUseCase: deleteCategory,
            reorderCategoriesUseCase: reorderCategories
        )
    }

    /// Creates the view model for the account list with dependencies.
    private func makeAccountListViewModel() -> AccountListViewModel {
        let container = modelContext.container
        let repository = AccountRepository(modelContainer: container)
        let getAccounts = GetAccountsUseCase(repository: repository)
        let deleteAccount = DeleteAccountUseCase(repository: repository)
        let updateAccount = UpdateAccountUseCase(repository: repository)
        let reorderAccounts = ReorderAccountsUseCase(repository: repository)

        return AccountListViewModel(
            getAccountsUseCase: getAccounts,
            deleteAccountUseCase: deleteAccount,
            updateAccountUseCase: updateAccount,
            reorderAccountsUseCase: reorderAccounts
        )
    }
}

enum AppTab: Hashable {
    case dashboard
    case transactions
    case accounts
    case categories
    case reports
    case settings
}
