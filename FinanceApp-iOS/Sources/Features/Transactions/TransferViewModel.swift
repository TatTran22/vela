import FinanceCore
import Foundation
import Observation

/// ViewModel for the account transfer sheet.
///
/// Manages source/destination account selection, cross-currency exchange rate
/// entry, an optional fee, and the final save operation.
@Observable
@MainActor
final class TransferViewModel {
    // MARK: - State

    /// The account from which money is transferred.
    var sourceAccount: Account?

    /// The account into which money is transferred.
    var destinationAccount: Account?

    /// Raw amount expression typed into the numpad.
    var amountExpression: String = ""

    /// The evaluated amount (in source account currency).
    var parsedAmount: Decimal = 0

    /// Exchange rate string, required when source and destination currencies differ.
    var exchangeRate: String = ""

    /// Optional transaction fee charged for the transfer.
    var fee: String = ""

    /// Date the transfer occurred.
    var date: Date = Date()

    /// Optional free-text note.
    var note: String = ""

    /// Whether a save operation is in progress.
    var isSaving = false

    /// Current domain error, if any.
    var error: TransactionError?

    /// Whether to show the error alert.
    var showError = false

    /// Set to true after a successful save; triggers sheet dismissal.
    var didSave = false

    /// All accounts available for selection.
    var accounts: [Account] = []

    // MARK: - Computed Properties

    /// Returns true when the source and destination accounts use different currencies.
    var needsExchangeRate: Bool {
        guard
            let src = sourceAccount,
            let dst = destinationAccount
        else { return false }
        return src.currency != dst.currency
    }

    /// The amount credited to the destination account (amount × exchange rate).
    var destinationAmount: Decimal {
        guard needsExchangeRate,
              let rate = Decimal(string: exchangeRate),
              rate > 0
        else { return parsedAmount }
        return parsedAmount * rate
    }

    /// Available destination accounts (excludes the selected source account).
    var availableDestinations: [Account] {
        accounts.filter { $0.id != sourceAccount?.id }
    }

    // MARK: - Dependencies

    private let createTransactionUseCase: CreateTransactionUseCaseProtocol
    private let accountRepository: AccountRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol

    private let parser = QuickAmountParser()

    // MARK: - Initialization

    /// Creates a new transfer view model.
    ///
    /// - Parameters:
    ///   - createTransactionUseCase: Use case for persisting the transfer transaction.
    ///   - accountRepository: Repository for loading all accounts.
    ///   - categoryRepository: Repository for resolving a default transfer category.
    init(
        createTransactionUseCase: CreateTransactionUseCaseProtocol,
        accountRepository: AccountRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol
    ) {
        self.createTransactionUseCase = createTransactionUseCase
        self.accountRepository = accountRepository
        self.categoryRepository = categoryRepository
    }

    // MARK: - Actions

    /// Loads all non-archived accounts and sets default source selection.
    func loadAccounts() async {
        do {
            let all = try await accountRepository.fetchAll()
            accounts = all.filter { !$0.isArchived }

            if sourceAccount == nil {
                sourceAccount = accounts.first { !$0.isHidden } ?? accounts.first
            }
            if destinationAccount == nil {
                destinationAccount = availableDestinations.first { !$0.isHidden } ?? availableDestinations.first
            }
        } catch {
            // Silent failure: user can still interact with the form
        }
    }

    /// Parses `amountExpression` and updates `parsedAmount`.
    func parseAmount() {
        guard !amountExpression.trimmingCharacters(in: .whitespaces).isEmpty else {
            parsedAmount = 0
            return
        }
        do {
            parsedAmount = try parser.parse(amountExpression)
        } catch {
            parsedAmount = 0
        }
    }

    /// Validates inputs and persists the transfer transaction.
    ///
    /// The exchange rate (if required) is stored in `transaction.metadata["exchangeRate"]`
    /// so that the use case can correctly compute the credited destination amount.
    func save() async {
        parseAmount()

        guard parsedAmount > 0 else {
            error = .amountMustBePositive
            showError = true
            return
        }
        guard let source = sourceAccount else {
            error = .accountNotFound(UUID())
            showError = true
            return
        }
        guard let destination = destinationAccount else {
            error = .destinationAccountRequired
            showError = true
            return
        }
        guard source.id != destination.id else {
            error = .sourceAndDestinationSame
            showError = true
            return
        }
        if needsExchangeRate {
            guard
                let rate = Decimal(string: exchangeRate),
                rate > 0
            else {
                error = .exchangeRateRequired
                showError = true
                return
            }
        }

        // Fetch the transfer category (first available, or create with a placeholder UUID)
        let transferCategory: FinanceCore.Category?
        do {
            let cats = try await categoryRepository.fetchAll(type: nil)
            transferCategory = cats.first { $0.name.lowercased().contains("transfer") }
        } catch {
            transferCategory = nil
        }

        guard let category = transferCategory else {
            self.error = .categoryRequired
            showError = true
            return
        }

        var metadata: [String: String]? = nil
        if needsExchangeRate, let rate = Decimal(string: exchangeRate), rate > 0 {
            metadata = ["exchangeRate": "\(rate)"]
        }

        let transfer = FinanceCore.Transaction(
            amount: parsedAmount,
            type: .transfer,
            categoryID: category.id,
            accountID: source.id,
            toAccountID: destination.id,
            note: note,
            date: date,
            metadata: metadata
        )

        isSaving = true
        error = nil

        do {
            _ = try await createTransactionUseCase.execute(transfer)
            didSave = true
        } catch let txError as TransactionError {
            self.error = txError
            showError = true
        } catch {
            self.error = .amountMustBePositive
            showError = true
        }

        isSaving = false
    }
}
