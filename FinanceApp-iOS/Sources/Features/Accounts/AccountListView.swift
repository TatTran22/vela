import FinanceCore
import FinanceData
import FinanceUI
import SwiftData
import SwiftUI

/// Main view for displaying the list of accounts
///
/// Shows accounts grouped by type with total balance, supports swipe actions,
/// and navigation to detail views.
struct AccountListView: View {
    @State private var viewModel: AccountListViewModel
    @State private var showingAddAccount = false
    @Environment(\.modelContext) private var modelContext

    // MARK: - Initialization

    /// Creates a new account list view
    /// - Parameter viewModel: The view model managing account data
    init(viewModel: AccountListViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.allAccounts.isEmpty {
                ProgressView()
            } else if viewModel.allAccounts.isEmpty {
                emptyState
            } else {
                accountsList
            }
        }
        .navigationTitle(AppStrings.accountListTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddAccount = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddAccount) {
            Task {
                await viewModel.loadAccounts()
            }
        } content: {
            NavigationStack {
                AccountEditView(viewModel: makeEditViewModel(for: nil))
            }
        }
        .task {
            await viewModel.loadAccounts()
        }
        .refreshable {
            await viewModel.loadAccounts()
        }
        .alert(AppStrings.error, isPresented: $viewModel.showError) {
            Button(AppStrings.ok) {}
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView {
            Label(AppStrings.accountListEmptyTitle, systemImage: "creditcard")
        } description: {
            Text(AppStrings.accountListEmptySubtitle)
        } actions: {
            Button(AppStrings.accountListEmptyAction) {
                showingAddAccount = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var accountsList: some View {
        List {
            // Total balance header
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppStrings.accountListTotalBalance)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    BalanceText(
                        amount: viewModel.totalBalance,
                        currencyCode: viewModel.primaryCurrency,
                        size: .large
                    )
                }
                .padding(.vertical, 4)
            }

            // Grouped by type
            ForEach(viewModel.sortedTypes, id: \.self) { type in
                Section {
                    ForEach(viewModel.groupedAccounts[type] ?? []) { account in
                        NavigationLink(value: account) {
                            AccountCard(account: account, layout: .compact)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteAccount(account.id)
                                }
                            } label: {
                                Label(AppStrings.delete, systemImage: "trash")
                            }

                            Button {
                                Task {
                                    await viewModel.archiveAccount(account.id)
                                }
                            } label: {
                                Label(AppStrings.archive, systemImage: "archivebox")
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                Task {
                                    await viewModel.toggleHidden(account.id)
                                }
                            } label: {
                                Label(
                                    account.isHidden ? AppStrings.show : AppStrings.hide,
                                    systemImage: account.isHidden ? "eye" : "eye.slash"
                                )
                            }
                            .tint(.gray)
                        }
                    }
                    .onMove { source, destination in
                        viewModel.reorderAccounts(type: type, from: source, to: destination)
                    }
                } header: {
                    HStack {
                        Text(type.displayName)
                        Spacer()
                        BalanceText(
                            amount: viewModel.sectionBalance(for: type),
                            currencyCode: viewModel.primaryCurrency,
                            size: .small
                        )
                    }
                }
            }
        }
        .navigationDestination(for: Account.self) { account in
            AccountDetailView(viewModel: makeDetailViewModel(for: account))
        }
    }

    // MARK: - Factory Methods

    private func makeEditViewModel(for account: Account?) -> AccountEditViewModel {
        let container = modelContext.container
        let repository = AccountRepository(modelContainer: container)
        let createUseCase = CreateAccountUseCase(repository: repository)
        let updateUseCase = UpdateAccountUseCase(repository: repository)

        return AccountEditViewModel(
            account: account,
            createAccountUseCase: createUseCase,
            updateAccountUseCase: updateUseCase
        )
    }

    private func makeDetailViewModel(for account: Account) -> AccountDetailViewModel {
        let container = modelContext.container
        let repository = AccountRepository(modelContainer: container)
        let getAccounts = GetAccountsUseCase(repository: repository)
        let deleteAccount = DeleteAccountUseCase(repository: repository)

        return AccountDetailViewModel(
            account: account,
            repository: repository,
            getAccountsUseCase: getAccounts,
            deleteAccountUseCase: deleteAccount
        )
    }

}
