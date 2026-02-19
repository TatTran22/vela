import FinanceCore
import Foundation
import Observation

/// ViewModel for the account detail screen
///
/// Manages displaying account details and actions like edit, delete, and balance adjustment.
@Observable
@MainActor
final class AccountDetailViewModel {
    // MARK: - State

    /// The account being displayed
    var account: Account

    /// Whether to show the edit sheet
    var showingEdit = false

    /// Whether to show the balance adjustment sheet
    var showingBalanceAdjust = false

    /// Whether to show the delete confirmation dialog
    var showingDeleteConfirmation = false

    // MARK: - Dependencies

    private let accountRepository: AccountRepositoryProtocol
    private let getAccountsUseCase: GetAccountsUseCaseProtocol
    private let deleteAccountUseCase: DeleteAccountUseCaseProtocol

    // MARK: - Initialization

    /// Creates a new account detail view model
    /// - Parameters:
    ///   - account: The account to display
    ///   - repository: Repository for balance updates
    ///   - getAccountsUseCase: Use case for fetching account updates
    ///   - deleteAccountUseCase: Use case for deleting accounts
    init(
        account: Account,
        repository: AccountRepositoryProtocol,
        getAccountsUseCase: GetAccountsUseCaseProtocol,
        deleteAccountUseCase: DeleteAccountUseCaseProtocol
    ) {
        self.account = account
        self.accountRepository = repository
        self.getAccountsUseCase = getAccountsUseCase
        self.deleteAccountUseCase = deleteAccountUseCase
    }

    // MARK: - Actions

    /// Refreshes the account data from the repository
    func refreshAccount() async {
        do {
            let filter = AccountFilter(
                includeArchived: true,
                includeHidden: true,
                types: nil
            )

            let accounts = try await getAccountsUseCase.execute(filter: filter)
            if let updated = accounts.first(where: { $0.id == account.id }) {
                self.account = updated
            }
        } catch {
            // Silent failure for refresh
        }
    }

    /// Adjusts the account balance by a given delta
    /// - Parameter delta: The amount to add (positive) or subtract (negative)
    func adjustBalance(_ delta: Decimal) async {
        do {
            try await accountRepository.updateBalance(account.id, delta: delta)
            await refreshAccount()
        } catch {
            // Silent failure for balance adjustment
        }
    }

    /// Deletes the account
    func deleteAccount() async throws {
        // For now, assume no transactions
        try await deleteAccountUseCase.execute(accountID: account.id, hasTransactions: false)
    }
}
