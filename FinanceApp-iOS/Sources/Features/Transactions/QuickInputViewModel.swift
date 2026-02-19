import FinanceCore
import Foundation
import Observation

/// ViewModel for the quick transaction entry sheet.
///
/// Drives a 3-step input flow: (1) amount + type, (2) category selection,
/// (3) review and optional detail expansion before saving.
@Observable
@MainActor
final class QuickInputViewModel {
    // MARK: - Input Step

    /// The three sequential steps of the quick-input flow.
    enum InputStep: Int {
        case amount
        case category
        case review
    }

    // MARK: - State

    /// Raw expression string typed into the numpad (e.g., "150k + 200k").
    var amountExpression: String = ""

    /// The evaluated decimal result of `amountExpression`.
    var parsedAmount: Decimal = 0

    /// Income or expense selection.
    var transactionType: TransactionType = .expense

    /// The category chosen on step 2.
    var selectedCategory: FinanceCore.Category?

    /// The account from which the transaction originates.
    var selectedAccount: Account?

    /// Date the financial event occurred.
    var date: Date = Date()

    /// Optional free-text note.
    var note: String = ""

    /// UUIDs of tags applied to this transaction.
    var selectedTags: [UUID] = []

    /// Whether the "More details" section is expanded on the review step.
    var showDetails = false

    /// Whether a save operation is in progress.
    var isSaving = false

    /// Current domain error, if any.
    var error: TransactionError?

    /// Whether to show the error alert.
    var showError = false

    /// Set to true after a successful save; triggers sheet dismissal.
    var didSave = false

    // MARK: - Data

    /// All available categories loaded on `loadData()`.
    var categories: [FinanceCore.Category] = []

    /// All available accounts loaded on `loadData()`.
    var accounts: [Account] = []

    /// Recently used category IDs (derived from the last 6 fetched transactions).
    var recentCategoryIDs: [UUID] = []

    // MARK: - Navigation

    /// The current active step in the flow.
    var currentStep: InputStep = .amount

    // MARK: - Dependencies

    private let createTransactionUseCase: CreateTransactionUseCaseProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let accountRepository: AccountRepositoryProtocol

    private let parser = QuickAmountParser()

    // MARK: - Initialization

    /// Creates a new quick-input view model.
    ///
    /// - Parameters:
    ///   - createTransactionUseCase: Use case used to persist the new transaction.
    ///   - categoryRepository: Repository for loading categories.
    ///   - accountRepository: Repository for loading accounts and finding a default.
    init(
        createTransactionUseCase: CreateTransactionUseCaseProtocol,
        categoryRepository: CategoryRepositoryProtocol,
        accountRepository: AccountRepositoryProtocol
    ) {
        self.createTransactionUseCase = createTransactionUseCase
        self.categoryRepository = categoryRepository
        self.accountRepository = accountRepository
    }

    // MARK: - Actions

    /// Loads categories and accounts, then sets the default account.
    func loadData() async {
        do {
            async let fetchedCategories = categoryRepository.fetchAll(type: nil)
            async let fetchedAccounts = accountRepository.fetchAll()

            let (allCategories, allAccounts) = try await (fetchedCategories, fetchedAccounts)
            categories = allCategories
            accounts = allAccounts.filter { !$0.isArchived }

            // Default to first non-hidden account
            if selectedAccount == nil {
                selectedAccount = accounts.first { !$0.isHidden } ?? accounts.first
            }
        } catch {
            // Silent failure: categories and accounts remain empty; user can still type
        }
    }

    /// Evaluates `amountExpression` using `QuickAmountParser` and updates `parsedAmount`.
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

    /// Advances to the next step if the current state is valid.
    func nextStep() {
        switch currentStep {
        case .amount:
            parseAmount()
            guard parsedAmount > 0 else {
                error = .amountMustBePositive
                showError = true
                return
            }
            currentStep = .category
        case .category:
            guard selectedCategory != nil else { return }
            currentStep = .review
        case .review:
            break
        }
    }

    /// Steps back to the previous step.
    func previousStep() {
        switch currentStep {
        case .amount:
            break
        case .category:
            currentStep = .amount
        case .review:
            currentStep = .category
        }
    }

    /// Validates inputs and creates the transaction via the use case.
    func save() async {
        parseAmount()

        guard parsedAmount > 0 else {
            error = .amountMustBePositive
            showError = true
            return
        }
        guard let category = selectedCategory else {
            error = .categoryRequired
            showError = true
            return
        }
        guard let account = selectedAccount else {
            error = .accountNotFound(UUID())
            showError = true
            return
        }

        isSaving = true
        error = nil

        let newTransaction = FinanceCore.Transaction(
            amount: parsedAmount,
            type: transactionType,
            categoryID: category.id,
            accountID: account.id,
            note: note,
            date: date,
            tags: selectedTags
        )

        do {
            _ = try await createTransactionUseCase.execute(newTransaction)
            didSave = true
        } catch let txError as TransactionError {
            error = txError
            showError = true
        } catch {
            self.error = .amountMustBePositive
            showError = true
        }

        isSaving = false
    }

    /// Toggles between income and expense.
    func switchType() {
        transactionType = transactionType == .expense ? .income : .expense
        // Clear the category selection if it no longer matches the new type
        if let cat = selectedCategory, cat.type != transactionType {
            selectedCategory = nil
        }
    }
}
