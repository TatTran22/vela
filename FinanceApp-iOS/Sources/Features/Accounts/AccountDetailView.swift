import FinanceCore
import FinanceData
import FinanceUI
import SwiftData
import SwiftUI

/// Detail view for a single account
///
/// Shows account information, balance, and recent transactions with actions menu.
struct AccountDetailView: View {
    @State private var viewModel: AccountDetailViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    /// Creates a new account detail view
    /// - Parameter viewModel: The view model managing account data
    init(viewModel: AccountDetailViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Balance card (expanded AccountCard)
                AccountCard(account: viewModel.account, layout: .expanded)
                    .padding(.horizontal)

                // Quick stats row
                HStack(spacing: 16) {
                    statCard(title: "Income", amount: 0, color: .green)
                    statCard(title: "Expense", amount: 0, color: .red)
                }
                .padding(.horizontal)

                // Transaction list placeholder
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Transactions")
                        .font(.headline)
                        .padding(.horizontal)

                    ContentUnavailableView {
                        Label("No Transactions", systemImage: "list.bullet")
                    } description: {
                        Text("Transactions will appear here once added.")
                    }
                }
            }
            .padding(.top)
        }
        .navigationTitle(viewModel.account.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        viewModel.showingEdit = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button {
                        viewModel.showingBalanceAdjust = true
                    } label: {
                        Label("Adjust Balance", systemImage: "plusminus")
                    }

                    Divider()

                    Button(role: .destructive) {
                        viewModel.showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingEdit) {
            Task {
                await viewModel.refreshAccount()
            }
        } content: {
            NavigationStack {
                AccountEditView(viewModel: makeEditViewModel())
            }
        }
        .sheet(isPresented: $viewModel.showingBalanceAdjust) {
            BalanceAdjustSheet(account: viewModel.account) { adjustment in
                await viewModel.adjustBalance(adjustment)
            }
        }
        .confirmationDialog(
            "Delete Account",
            isPresented: $viewModel.showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteAccount()
                        dismiss()
                    } catch {
                        // Show error
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(viewModel.account.name)? This action cannot be undone.")
        }
        .task {
            await viewModel.refreshAccount()
        }
    }

    // MARK: - Subviews

    private func statCard(title: String, amount: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            BalanceText(
                amount: amount,
                currencyCode: viewModel.account.currency,
                size: .medium
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    // MARK: - Factory Methods

    private func makeEditViewModel() -> AccountEditViewModel {
        let container = modelContext.container
        let repository = AccountRepository(modelContainer: container)
        let createUseCase = CreateAccountUseCase(repository: repository)
        let updateUseCase = UpdateAccountUseCase(repository: repository)

        return AccountEditViewModel(
            account: viewModel.account,
            createAccountUseCase: createUseCase,
            updateAccountUseCase: updateUseCase
        )
    }
}
