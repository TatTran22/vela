import SwiftUI

/// Root view with sidebar navigation for macOS
struct MacContentView: View {
    @State private var selectedSection: MacSection? = .dashboard

    var body: some View {
        NavigationSplitView {
            List(MacSection.allCases, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }
            .navigationTitle("FinanceApp")
        } detail: {
            switch selectedSection {
            case .dashboard:
                MacDashboardPlaceholderView()
            case .transactions:
                MacTransactionsPlaceholderView()
            case .accounts:
                MacAccountsPlaceholderView()
            case .reports:
                MacReportsPlaceholderView()
            case .settings:
                MacSettingsPlaceholderView()
            case .none:
                Text("Select a section")
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
        rawValue.capitalized
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
