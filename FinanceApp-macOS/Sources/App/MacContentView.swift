import FinanceData
import SwiftData
import SwiftUI

/// Root view with sidebar navigation for macOS
struct MacContentView: View {
    @State private var selectedSection: MacSection? = .dashboard
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationSplitView {
            List(MacSection.allCases, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }
            .navigationTitle(AppStrings.navFinanceApp)
        } detail: {
            switch selectedSection {
            case .dashboard:
                MacDashboardPlaceholderView()
            case .transactions:
                MacTransactionsView(modelContainer: modelContext.container)
            case .accounts:
                MacAccountsView(modelContainer: modelContext.container)
            case .reports:
                MacReportsPlaceholderView()
            case .settings:
                MacSettingsPlaceholderView()
            case .none:
                Text(AppStrings.navSelectSection)
            }
        }
    }
}

enum MacSection: String, CaseIterable, Identifiable {
    case dashboard
    case transactions
    case accounts
    case reports
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return AppStrings.navDashboard
        case .transactions: return AppStrings.navTransactions
        case .accounts: return AppStrings.navAccounts
        case .reports: return AppStrings.navReports
        case .settings: return AppStrings.navSettings
        }
    }

    var icon: String {
        switch self {
        case .dashboard: "house.fill"
        case .transactions: "list.bullet"
        case .accounts: "creditcard.fill"
        case .reports: "chart.pie.fill"
        case .settings: "gearshape.fill"
        }
    }
}
