import FinanceCore
import FinanceData
import SwiftData
import SwiftUI

/// Main accounts view for macOS displaying account list and detail panes.
///
/// Uses HSplitView to provide a two-pane layout: account list on the left grouped
/// by type, and selected account details on the right. Manages loading, creating,
/// editing, and deleting accounts with proper dependency injection.
struct MacAccountsView: View {
    /// SwiftData model container for data access
    let modelContainer: ModelContainer

    @State private var selectedAccount: Account?
    @State private var accounts: [Account] = []
    @State private var groupedAccounts: [AccountType: [Account]] = [:]
    @State private var isLoading = true
    @State private var showingNewAccount = false
    @State private var accountToEdit: Account?
    @State private var errorMessage: String?

    // Use cases
    private var repository: AccountRepository { AccountRepository(modelContainer: modelContainer) }
    private var getAccountsUseCase: GetAccountsUseCaseProtocol { GetAccountsUseCase(repository: repository) }
    private var createAccountUseCase: CreateAccountUseCaseProtocol { CreateAccountUseCase(repository: repository) }
    private var updateAccountUseCase: UpdateAccountUseCaseProtocol { UpdateAccountUseCase(repository: repository) }
    private var deleteAccountUseCase: DeleteAccountUseCaseProtocol { DeleteAccountUseCase(repository: repository) }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if accounts.isEmpty {
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
                            onDelete: { Task { await deleteAccount(account.id) } }
                        )
                    } else {
                        ContentUnavailableView("Select an Account", systemImage: "creditcard")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .task { await loadAccounts() }
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
                    createAccountUseCase: createAccountUseCase,
                    updateAccountUseCase: updateAccountUseCase,
                    onSave: {
                        accountToEdit = nil
                        Task { await loadAccounts() }
                    }
                )
            }
        }
        .onChange(of: showingNewAccount) { _, newValue in
            if !newValue {
                accountToEdit = nil
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
    }

    /// Account list pane with sidebar.
    private var accountListPane: some View {
        List(selection: $selectedAccount) {
            MacAccountsSidebarSection(
                groupedAccounts: groupedAccounts,
                selectedAccount: $selectedAccount,
                onEdit: { account in
                    accountToEdit = account
                    showingNewAccount = true
                },
                onArchive: { account in
                    Task { await archiveAccount(account) }
                },
                onHide: { account in
                    Task { await toggleHidden(account) }
                },
                onDelete: { account in
                    Task { await deleteAccount(account.id) }
                }
            )
        }
        .frame(minWidth: 250)
    }

    /// Loads all accounts and groups them by type.
    private func loadAccounts() async {
        isLoading = true
        errorMessage = nil

        do {
            let filter = AccountFilter(
                includeArchived: true,
                includeHidden: true,
                types: nil
            )
            accounts = try await getAccountsUseCase.execute(filter: filter)
            groupedAccounts = try await getAccountsUseCase.executeGrouped(filter: filter)

            // Ensure selected account is still valid
            if let selected = selectedAccount,
               !accounts.contains(where: { $0.id == selected.id }) {
                selectedAccount = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Deletes an account by ID.
    ///
    /// - Parameter accountID: The UUID of the account to delete
    private func deleteAccount(_ accountID: UUID) async {
        errorMessage = nil

        do {
            // For now, assume no transactions
            try await deleteAccountUseCase.execute(accountID: accountID, hasTransactions: false)

            // Clear selection if deleted account was selected
            if selectedAccount?.id == accountID {
                selectedAccount = nil
            }

            await loadAccounts()
        } catch let error as AccountError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Toggles the archived state of an account.
    ///
    /// - Parameter account: The account to archive or unarchive
    private func archiveAccount(_ account: Account) async {
        var updated = account
        updated.isArchived.toggle()
        updated.updatedAt = Date()

        do {
            _ = try await updateAccountUseCase.execute(updated, hasTransactions: false)
            await loadAccounts()
        } catch let error as AccountError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Toggles the hidden state of an account.
    ///
    /// - Parameter account: The account to show or hide
    private func toggleHidden(_ account: Account) async {
        var updated = account
        updated.isHidden.toggle()
        updated.updatedAt = Date()

        do {
            _ = try await updateAccountUseCase.execute(updated, hasTransactions: false)
            await loadAccounts()
        } catch let error as AccountError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
