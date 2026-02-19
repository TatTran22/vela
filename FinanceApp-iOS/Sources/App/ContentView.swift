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
            Tab("Dashboard", systemImage: "house.fill", value: .dashboard) {
                NavigationStack {
                    DashboardPlaceholderView()
                }
            }

            Tab("Transactions", systemImage: "list.bullet", value: .transactions) {
                NavigationStack {
                    TransactionsPlaceholderView()
                }
            }

            Tab("Accounts", systemImage: "creditcard.fill", value: .accounts) {
                NavigationStack {
                    AccountListView(viewModel: makeAccountListViewModel())
                }
            }

            Tab("Reports", systemImage: "chart.pie.fill", value: .reports) {
                NavigationStack {
                    ReportsPlaceholderView()
                }
            }

            Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                NavigationStack {
                    SettingsPlaceholderView()
                }
            }
        }
    }

    // MARK: - Factory Methods

    /// Creates the view model for the account list with dependencies
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
    case reports
    case settings
}
