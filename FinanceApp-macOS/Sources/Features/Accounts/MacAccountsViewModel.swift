import FinanceCore
import FinanceData
import Foundation
import Observation
import SwiftData

/// ViewModel for the macOS accounts view.
///
/// Manages account data loading, grouping, and mutations (delete, archive, toggle
/// hidden). All repository and use-case instances are created once in `init` and
/// reused for the lifetime of the view model, avoiding the bug where computed
/// properties would create fresh actor instances on every access.
@Observable
@MainActor
final class MacAccountsViewModel {

    // MARK: - Published state

    /// All accounts matching the current filter.
    var accounts: [Account] = []

    /// Accounts grouped by their type, used to drive the sidebar sections.
    var groupedAccounts: [AccountType: [Account]] = [:]

    /// Whether a data load is in progress.
    var isLoading = false

    /// The last error message to display, or nil if none.
    var errorMessage: String?

    /// Whether the error alert is currently visible.
    var showError = false

    /// The primary display currency used for balance totals.
    var primaryCurrency: CurrencyCode = .VND

    // MARK: - Dependencies

    private let getAccountsUseCase: GetAccountsUseCaseProtocol
    private let deleteAccountUseCase: DeleteAccountUseCaseProtocol
    private let createAccountUseCase: CreateAccountUseCaseProtocol
    private let updateAccountUseCase: UpdateAccountUseCaseProtocol

    // MARK: - Init (ModelContainer convenience)

    /// Creates the view model by constructing repositories and use cases from a
    /// SwiftData `ModelContainer`. This is the designated initialiser used by
    /// `MacContentView`.
    ///
    /// - Parameter modelContainer: The SwiftData container from which all
    ///   repositories are instantiated.
    init(modelContainer: ModelContainer) {
        let repository = AccountRepository(modelContainer: modelContainer)
        self.getAccountsUseCase = GetAccountsUseCase(repository: repository)
        self.deleteAccountUseCase = DeleteAccountUseCase(repository: repository)
        self.createAccountUseCase = CreateAccountUseCase(repository: repository)
        self.updateAccountUseCase = UpdateAccountUseCase(repository: repository)
    }

    /// Dependency-injection initialiser used for testing or custom composition.
    ///
    /// - Parameters:
    ///   - getAccountsUseCase: Use case for fetching accounts.
    ///   - deleteAccountUseCase: Use case for deleting accounts.
    ///   - createAccountUseCase: Use case for creating accounts.
    ///   - updateAccountUseCase: Use case for updating accounts.
    init(
        getAccountsUseCase: GetAccountsUseCaseProtocol,
        deleteAccountUseCase: DeleteAccountUseCaseProtocol,
        createAccountUseCase: CreateAccountUseCaseProtocol,
        updateAccountUseCase: UpdateAccountUseCaseProtocol
    ) {
        self.getAccountsUseCase = getAccountsUseCase
        self.deleteAccountUseCase = deleteAccountUseCase
        self.createAccountUseCase = createAccountUseCase
        self.updateAccountUseCase = updateAccountUseCase
    }

    // MARK: - Data loading

    /// Loads all accounts (including archived and hidden) and groups them by type.
    ///
    /// Clears any previous error state before fetching. If the currently selected
    /// account is no longer present after a reload the caller is responsible for
    /// clearing the selection; this method simply refreshes the data arrays.
    func loadAccounts() async {
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
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    // MARK: - Mutations

    /// Deletes the account with the given ID.
    ///
    /// Reloads account data on success. On failure, populates `errorMessage` and
    /// sets `showError` to true.
    ///
    /// - Parameter accountID: The UUID of the account to delete.
    /// - Returns: `true` if deletion succeeded, `false` otherwise. Callers can
    ///   use the return value to clear a selection binding.
    @discardableResult
    func deleteAccount(_ accountID: UUID) async -> Bool {
        errorMessage = nil

        do {
            // Assume no transactions for now; the use case enforces this constraint.
            try await deleteAccountUseCase.execute(accountID: accountID, hasTransactions: false)
            await loadAccounts()
            return true
        } catch let error as AccountError {
            errorMessage = error.localizedDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        return false
    }

    /// Toggles the archived state of the given account.
    ///
    /// - Parameter account: The account to archive or unarchive.
    func archiveAccount(_ account: Account) async {
        var updated = account
        updated.isArchived.toggle()
        updated.updatedAt = Date()

        do {
            _ = try await updateAccountUseCase.execute(updated, hasTransactions: false)
            await loadAccounts()
        } catch let error as AccountError {
            errorMessage = error.localizedDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    /// Toggles the hidden state of the given account.
    ///
    /// - Parameter account: The account to show or hide.
    func toggleHidden(_ account: Account) async {
        var updated = account
        updated.isHidden.toggle()
        updated.updatedAt = Date()

        do {
            _ = try await updateAccountUseCase.execute(updated, hasTransactions: false)
            await loadAccounts()
        } catch let error as AccountError {
            errorMessage = error.localizedDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Accessors for the edit sheet

    /// Returns the `CreateAccountUseCaseProtocol` instance for use in the edit sheet.
    var createUseCase: CreateAccountUseCaseProtocol { createAccountUseCase }

    /// Returns the `UpdateAccountUseCaseProtocol` instance for use in the edit sheet.
    var updateUseCase: UpdateAccountUseCaseProtocol { updateAccountUseCase }
}
