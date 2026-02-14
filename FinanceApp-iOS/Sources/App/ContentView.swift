import SwiftUI

/// Root view with tab-based navigation for iOS
struct ContentView: View {
    @State private var selectedTab: AppTab = .dashboard

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
                    AccountsPlaceholderView()
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
}

enum AppTab: Hashable {
    case dashboard
    case transactions
    case accounts
    case reports
    case settings
}
