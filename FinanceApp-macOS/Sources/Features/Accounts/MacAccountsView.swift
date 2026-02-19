import FinanceCore
import FinanceData
import SwiftData
import SwiftUI

/// Main accounts view for macOS displaying account list and detail panes.
///
/// Uses HSplitView to provide a two-pane layout: account list on the left grouped
/// by type, and selected account details on the right. All business logic is
/// delegated to `MacAccountsViewModel`.
struct MacAccountsView: View {

    // MARK: - ViewModel

    @State private var viewModel: MacAccountsViewModel

    // MARK: - Local UI state

    @State private var selectedAccount: Account?
    @State private var showingNewAccount = false
    @State private var accountToEdit: Account?

    // MARK: - Model container reference (kept for the edit sheet)

    private let modelContainer: ModelContainer

    // MARK: - Init

    /// Creates the view from a SwiftData `ModelContainer`.
    ///
    /// - Parameter modelContainer: The SwiftData container used to initialise
    ///   the view model and all underlying repositories.
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        _viewModel = State(
            initialValue: MacAccountsViewModel(modelContainer: modelContainer)
        )
    }

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.accounts.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.accounts.isEmpty {
                ContentUnavailableView {
                    Label("No Accounts", systemImage: "creditcard")
                } description: {
                    Text("Create your first account to get started.")
                } actions: {
                    Button("New Account") {
                        accountToEdit = nil
                        showingNewAccount = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                HSplitView {
                    // Account list (left pane)
                    accountListPane

                    // Detail pane (right)
                    if let account = selectedAccount {
                        MacAccountDetailView(
                            account: account,
                            onEdit: {
                                accountToEdit = account
                                showingNewAccount = true
                            },
                            onDelete: {
                                Task {
                                    let deleted = await viewModel.deleteAccount(account.id)
                                    if deleted { selectedAccount = nil }
                                }
                            }
                        )
                    } else {
                        ContentUnavailableView("Select an Account", systemImage: "creditcard")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .task { await viewModel.loadAccounts() }
        .toolbar {
            ToolbarItem {
                Button {
                    accountToEdit = nil
                    showingNewAccount = true
                } label: {
                    Label("New Account", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingNewAccount) {
            NavigationStack {
                MacAccountEditView(
                    account: accountToEdit,
                    createAccountUseCase: viewModel.createUseCase,
                    updateAccountUseCase: viewModel.updateUseCase,
                    onSave: {
                        accountToEdit = nil
                        Task { await viewModel.loadAccounts() }
                    }
                )
            }
        }
        .onChange(of: showingNewAccount) { _, newValue in
            if !newValue {
                accountToEdit = nil
            }
        }
        // Keep selectedAccount in sync after any reload
        .onChange(of: viewModel.accounts) { _, newAccounts in
            if let selected = selectedAccount,
               !newAccounts.contains(where: { $0.id == selected.id }) {
                selectedAccount = nil
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.showError = false }
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
    }

    // MARK: - Account list pane

    /// Account list pane with sidebar showing accounts grouped by type.
    private var accountListPane: some View {
        List(selection: $selectedAccount) {
            MacAccountsSidebarSection(
                groupedAccounts: viewModel.groupedAccounts,
                selectedAccount: $selectedAccount,
                onEdit: { account in
                    accountToEdit = account
                    showingNewAccount = true
                },
                onArchive: { account in
                    Task { await viewModel.archiveAccount(account) }
                },
                onHide: { account in
                    Task { await viewModel.toggleHidden(account) }
                },
                onDelete: { account in
                    Task {
                        let deleted = await viewModel.deleteAccount(account.id)
                        if deleted, selectedAccount?.id == account.id {
                            selectedAccount = nil
                        }
                    }
                }
            )
        }
        .frame(minWidth: 250)
    }
}
