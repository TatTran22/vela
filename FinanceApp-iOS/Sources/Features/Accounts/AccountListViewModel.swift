import FinanceCore
import Foundation
import Observation

/// ViewModel for the account list screen
///
/// Manages loading, displaying, and organizing accounts by type,
/// as well as handling account deletion, archiving, and visibility.
@Observable
@MainActor
final class AccountListViewModel {
    // MARK: - State

    /// Accounts grouped by account type
    var groupedAccounts: [AccountType: [Account]] = [:]

    /// Total balance across all accounts (in primary currency)
    var totalBalance: Decimal = 0

    /// Whether the view is currently loading data
    var isLoading = false

    /// Current error, if any
    var error: AccountError?

    /// Whether to show error alert
    var showError = false

    /// Primary currency for total balance display (defaults to VND, can be configured via Settings)
    var primaryCurrency: CurrencyCode = .VND

    // MARK: - Dependencies

    private let getAccountsUseCase: GetAccountsUseCaseProtocol
    private let deleteAccountUseCase: DeleteAccountUseCaseProtocol
    private let updateAccountUseCase: UpdateAccountUseCaseProtocol
    private let reorderAccountsUseCase: ReorderAccountsUseCaseProtocol

    // MARK: - Initialization

    /// Creates a new account list view model
    /// - Parameters:
    ///   - getAccountsUseCase: Use case for fetching accounts
    ///   - deleteAccountUseCase: Use case for deleting accounts
    ///   - updateAccountUseCase: Use case for updating accounts
    ///   - reorderAccountsUseCase: Use case for reordering accounts
    init(
        getAccountsUseCase: GetAccountsUseCaseProtocol,
        deleteAccountUseCase: DeleteAccountUseCaseProtocol,
        updateAccountUseCase: UpdateAccountUseCaseProtocol,
        reorderAccountsUseCase: ReorderAccountsUseCaseProtocol
    ) {
        self.getAccountsUseCase = getAccountsUseCase
        self.deleteAccountUseCase = deleteAccountUseCase
        self.updateAccountUseCase = updateAccountUseCase
        self.reorderAccountsUseCase = reorderAccountsUseCase
    }

    // MARK: - Computed Properties

    /// Account types that have at least one account, in display order
    var sortedTypes: [AccountType] {
        AccountType.allCases.filter { groupedAccounts[$0]?.isEmpty == false }
    }

    /// All accounts flattened in display order
    var allAccounts: [Account] {
        sortedTypes.flatMap { groupedAccounts[$0] ?? [] }
    }

    // MARK: - Actions

    /// Loads accounts from the repository
    func loadAccounts() async {
        isLoading = true
        error = nil

        do {
            let filter = AccountFilter(
                includeArchived: false,
                includeHidden: true,
                types: nil
            )

            groupedAccounts = try await getAccountsUseCase.executeGrouped(filter: filter)
            totalBalance = try await getAccountsUseCase.executeTotalBalance(in: primaryCurrency)
        } catch let accountError as AccountError {
            error = accountError
            showError = true
        } catch {
            self.error = .accountNotFound(UUID())
            showError = true
        }

        isLoading = false
    }

    /// Deletes an account
    /// - Parameter id: The account ID to delete
    func deleteAccount(_ id: UUID) async {
        do {
            // For now, assume no transactions
            try await deleteAccountUseCase.execute(accountID: id, hasTransactions: false)
            await loadAccounts()
        } catch let accountError as AccountError {
            error = accountError
            showError = true
        } catch {
            self.error = .accountNotFound(id)
            showError = true
        }
    }

    /// Toggles the archived state of an account
    /// - Parameter id: The account ID to archive/unarchive
    func archiveAccount(_ id: UUID) async {
        guard let account = allAccounts.first(where: { $0.id == id }) else {
            error = .accountNotFound(id)
            showError = true
            return
        }

        var updatedAccount = account
        updatedAccount.isArchived.toggle()
        updatedAccount.updatedAt = Date()

        do {
            _ = try await updateAccountUseCase.execute(updatedAccount, hasTransactions: false)
            await loadAccounts()
        } catch let accountError as AccountError {
            error = accountError
            showError = true
        } catch {
            self.error = .accountNotFound(id)
            showError = true
        }
    }

    /// Toggles the hidden state of an account
    /// - Parameter id: The account ID to show/hide
    func toggleHidden(_ id: UUID) async {
        guard let account = allAccounts.first(where: { $0.id == id }) else {
            error = .accountNotFound(id)
            showError = true
            return
        }

        var updatedAccount = account
        updatedAccount.isHidden.toggle()
        updatedAccount.updatedAt = Date()

        do {
            _ = try await updateAccountUseCase.execute(updatedAccount, hasTransactions: false)
            await loadAccounts()
        } catch let accountError as AccountError {
            error = accountError
            showError = true
        } catch {
            self.error = .accountNotFound(id)
            showError = true
        }
    }

    /// Reorders accounts within a specific type section
    /// - Parameters:
    ///   - type: The account type section being reordered
    ///   - source: Source indices in the section
    ///   - destination: Destination index in the section
    func reorderAccounts(type: AccountType, from source: IndexSet, to destination: Int) {
        guard var sectionAccounts = groupedAccounts[type] else { return }
        sectionAccounts.move(fromOffsets: source, toOffset: destination)
        groupedAccounts[type] = sectionAccounts

        // Persist new order
        let orderedIDs = sectionAccounts.map { $0.id }
        Task {
            do {
                try await reorderAccountsUseCase.execute(orderedIDs: orderedIDs)
            } catch let accountError as AccountError {
                error = accountError
                showError = true
            } catch {
                // Silent failure for reorder
            }
        }
    }

    /// Calculates the total balance for a specific account type section
    /// - Parameter type: The account type
    /// - Returns: The sum of all account balances for that type
    func sectionBalance(for type: AccountType) -> Decimal {
        (groupedAccounts[type] ?? []).reduce(0) { $0 + $1.balance }
    }
}
