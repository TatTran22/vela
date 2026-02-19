import FinanceCore
import Foundation
import Observation

/// ViewModel for creating or editing an account
///
/// Manages form fields and validation for account creation/editing.
@Observable
@MainActor
final class AccountEditViewModel {
    // MARK: - Form Fields

    /// Account name
    var name: String = ""

    /// Account type
    var type: AccountType = .cash

    /// Currency code
    var currency: CurrencyCode = .VND

    /// Initial balance as string for TextField binding
    var initialBalance: String = "0"

    /// Icon name (SF Symbol)
    var iconName: String = "banknote"

    /// Color hex string
    var colorHex: String = "#34C759"

    /// E-wallet provider (only for eWallet type)
    var eWalletProvider: EWalletProvider?

    /// Optional note
    var note: String = ""

    // MARK: - State

    /// Whether the save operation is in progress
    var isSaving = false

    /// Field-level validation errors, keyed by field name
    var fieldErrors: [String: String] = [:]

    /// General error message (non-field-specific)
    var generalError: String?

    /// Whether to show general error alert
    var showError = false

    /// Whether the save was successful (used to dismiss view)
    var didSave = false

    // MARK: - Edit Mode

    /// The account being edited, or nil if creating new
    let editingAccount: Account?

    /// Whether this is an edit operation
    let isEditing: Bool

    // MARK: - Dependencies

    private let createAccountUseCase: CreateAccountUseCaseProtocol
    private let updateAccountUseCase: UpdateAccountUseCaseProtocol

    // MARK: - Initialization

    /// Creates a new account edit view model
    /// - Parameters:
    ///   - account: The account to edit, or nil to create new
    ///   - createAccountUseCase: Use case for creating accounts
    ///   - updateAccountUseCase: Use case for updating accounts
    init(
        account: Account? = nil,
        createAccountUseCase: CreateAccountUseCaseProtocol,
        updateAccountUseCase: UpdateAccountUseCaseProtocol
    ) {
        self.editingAccount = account
        self.isEditing = account != nil
        self.createAccountUseCase = createAccountUseCase
        self.updateAccountUseCase = updateAccountUseCase

        // Pre-populate form if editing
        if let account {
            self.name = account.name
            self.type = account.type
            self.currency = account.currency
            self.initialBalance = account.balance.description
            self.iconName = account.iconName
            self.colorHex = account.colorHex
            self.eWalletProvider = account.eWalletProvider
            self.note = account.note ?? ""
        } else {
            // Set defaults from account type
            self.iconName = type.defaultIconName
            self.colorHex = type.defaultColorHex
        }
    }

    // MARK: - Computed Properties

    /// Title for the navigation bar
    var title: String {
        isEditing ? "Edit Account" : "New Account"
    }

    /// Parsed balance as Decimal
    var parsedBalance: Decimal {
        Decimal(string: initialBalance) ?? 0
    }

    // MARK: - Actions

    /// Validates all fields. Returns true if valid.
    func validate() -> Bool {
        fieldErrors.removeAll()

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            fieldErrors["name"] = "Account name is required"
        }

        return fieldErrors.isEmpty
    }

    /// Saves the account (create or update)
    func save() async {
        guard validate() else { return }

        isSaving = true
        generalError = nil
        didSave = false

        do {
            if isEditing, let existing = editingAccount {
                var updatedAccount = existing
                updatedAccount.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                updatedAccount.type = type
                updatedAccount.iconName = iconName
                updatedAccount.colorHex = colorHex
                updatedAccount.eWalletProvider = eWalletProvider
                updatedAccount.note = note.isEmpty ? nil : note
                updatedAccount.updatedAt = Date()

                _ = try await updateAccountUseCase.execute(updatedAccount, hasTransactions: false)
                didSave = true
            } else {
                let newAccount = Account(
                    id: UUID(),
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    type: type,
                    currency: currency,
                    initialBalance: parsedBalance,
                    balance: parsedBalance,
                    iconName: iconName,
                    colorHex: colorHex,
                    sortOrder: 0,
                    isHidden: false,
                    isArchived: false,
                    note: note.isEmpty ? nil : note,
                    eWalletProvider: eWalletProvider,
                    createdAt: Date(),
                    updatedAt: Date(),
                    deletedAt: nil
                )

                _ = try await createAccountUseCase.execute(newAccount)
                didSave = true
            }
        } catch let accountError as AccountError {
            mapAccountError(accountError)
        } catch {
            generalError = error.localizedDescription
            showError = true
        }

        isSaving = false
    }

    /// Maps AccountError to field-level or general error messages.
    private func mapAccountError(_ error: AccountError) {
        switch error {
        case .nameEmpty:
            fieldErrors["name"] = "Account name is required"
        case .nameAlreadyExists(_):
            fieldErrors["name"] = "An account with this name already exists"
        default:
            generalError = error.localizedDescription
            showError = true
        }
    }

    /// Updates icon and color to match the selected account type defaults
    func updateIconAndColor() {
        iconName = type.defaultIconName
        colorHex = type.defaultColorHex
    }
}
