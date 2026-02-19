import Foundation

/// Protocol for creating new financial transactions.
///
/// This use case handles transaction creation with full validation of business rules
/// including amount positivity, account existence, category type matching, and
/// automatic account balance updates. Cross-currency transfers are supported via
/// an exchange rate stored in transaction metadata.
public protocol CreateTransactionUseCaseProtocol: Sendable {
    /// Creates a new transaction after validating business rules.
    ///
    /// The transaction will be validated for:
    /// - Amount greater than zero
    /// - Source account existence
    /// - Category existence and type compatibility (income category for income, expense for expense)
    /// - For transfers: destination account existence and source != destination
    /// - For cross-currency transfers: exchange rate present in metadata
    ///
    /// Account balances are updated atomically after the transaction is saved:
    /// - Income: `account.balance += amount`
    /// - Expense: `account.balance -= amount`
    /// - Transfer: `source.balance -= amount`, `destination.balance += toAmount`
    ///
    /// For cross-currency transfers, `toAmount = amount * exchangeRate` where the
    /// exchange rate is read from `transaction.metadata["exchangeRate"]`.
    ///
    /// - Parameter transaction: The transaction to create.
    /// - Returns: The saved transaction.
    /// - Throws: `TransactionError.amountMustBePositive` if amount <= 0,
    ///           `TransactionError.accountNotFound` if source or destination account does not exist,
    ///           `TransactionError.categoryRequired` if no category is provided (guard at call site),
    ///           `TransactionError.categoryTypeMismatch` if category type does not match transaction type,
    ///           `TransactionError.destinationAccountRequired` if type is transfer but toAccountID is nil,
    ///           `TransactionError.sourceAndDestinationSame` if source and destination accounts match,
    ///           `TransactionError.exchangeRateRequired` if currencies differ but no exchange rate provided,
    ///           or repository errors for persistence failures.
    func execute(_ transaction: Transaction) async throws -> Transaction
}

/// Implementation of transaction creation use case.
///
/// This use case validates all domain business rules before persisting a new transaction,
/// then atomically updates the affected account balances. It depends on three repository
/// protocols to remain fully decoupled from the data layer.
public struct CreateTransactionUseCase: CreateTransactionUseCaseProtocol {
    private let transactionRepository: TransactionRepositoryProtocol
    private let accountRepository: AccountRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol

    /// Creates a new transaction creation use case.
    ///
    /// - Parameters:
    ///   - transactionRepository: The repository for transaction persistence.
    ///   - accountRepository: The repository for account persistence and balance updates.
    ///   - categoryRepository: The repository for category validation.
    public init(
        transactionRepository: TransactionRepositoryProtocol,
        accountRepository: AccountRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol
    ) {
        self.transactionRepository = transactionRepository
        self.accountRepository = accountRepository
        self.categoryRepository = categoryRepository
    }

    public func execute(_ transaction: Transaction) async throws -> Transaction {
        // 1. Validate amount is strictly positive
        guard transaction.amount > 0 else {
            throw TransactionError.amountMustBePositive
        }

        // 2. Validate source account exists
        guard let sourceAccount = try await accountRepository.fetch(by: transaction.accountID) else {
            throw TransactionError.accountNotFound(transaction.accountID)
        }

        // 3. Validate category exists and type matches for non-transfer transactions
        guard let category = try await categoryRepository.fetch(by: transaction.categoryID) else {
            throw TransactionError.categoryRequired
        }

        // For income and expense, the category's transaction type must align.
        // Transfers may use any category (e.g., a dedicated "Transfer" category).
        if transaction.type != .transfer && category.type != transaction.type {
            throw TransactionError.categoryTypeMismatch(
                expected: transaction.type.displayName,
                got: category.type.displayName
            )
        }

        // 4. Transfer-specific validations
        let toAmount: Decimal
        if transaction.type == .transfer {
            guard let toAccountID = transaction.toAccountID else {
                throw TransactionError.destinationAccountRequired
            }

            guard toAccountID != transaction.accountID else {
                throw TransactionError.sourceAndDestinationSame
            }

            guard let destinationAccount = try await accountRepository.fetch(by: toAccountID) else {
                throw TransactionError.accountNotFound(toAccountID)
            }

            // 5. Resolve the amount credited to the destination account.
            //    Same currency: toAmount == amount. Different currency: requires exchange rate.
            if sourceAccount.currency == destinationAccount.currency {
                toAmount = transaction.amount
            } else {
                guard
                    let rateString = transaction.metadata?["exchangeRate"],
                    let rate = Decimal(string: rateString),
                    rate > 0
                else {
                    throw TransactionError.exchangeRateRequired
                }
                toAmount = transaction.amount * rate
            }
        } else {
            toAmount = transaction.amount
        }

        // 6. Persist the transaction
        var savedTransaction = transaction
        savedTransaction.updatedAt = Date()
        try await transactionRepository.save(savedTransaction)

        // 7. Update account balances atomically
        switch transaction.type {
        case .income:
            try await accountRepository.updateBalance(transaction.accountID, delta: transaction.amount)

        case .expense:
            try await accountRepository.updateBalance(transaction.accountID, delta: -transaction.amount)

        case .transfer:
            // Source account is debited; destination account is credited with toAmount
            try await accountRepository.updateBalance(transaction.accountID, delta: -transaction.amount)
            // toAccountID is guaranteed non-nil here (validated above)
            try await accountRepository.updateBalance(transaction.toAccountID!, delta: toAmount)
        }

        return savedTransaction
    }
}
