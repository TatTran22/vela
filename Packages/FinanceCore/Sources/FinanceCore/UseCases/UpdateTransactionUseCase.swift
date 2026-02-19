import Foundation

/// Protocol for updating existing financial transactions.
///
/// This use case handles transaction updates with full validation of business rules.
/// It reverses the balance effect of the original transaction, validates the new
/// transaction values, and applies the new balance effect — all in sequence.
public protocol UpdateTransactionUseCaseProtocol: Sendable {
    /// Updates an existing transaction after validating business rules.
    ///
    /// The update procedure is:
    /// 1. Fetch and verify the original transaction exists.
    /// 2. Validate the new transaction values (amount, account, category, transfer rules).
    /// 3. Reverse the balance effect of the original transaction.
    /// 4. Apply the balance effect of the new transaction.
    /// 5. Persist the updated transaction.
    ///
    /// The transaction is identified by its `id`; all other fields may change.
    ///
    /// - Parameter transaction: The transaction with updated values. The `id` field
    ///   is used to locate the existing record.
    /// - Returns: The updated transaction.
    /// - Throws: `TransactionError.transactionNotFound` if no record matches the ID,
    ///           `TransactionError.amountMustBePositive` if amount <= 0,
    ///           `TransactionError.accountNotFound` if source or destination account does not exist,
    ///           `TransactionError.categoryRequired` if category does not exist,
    ///           `TransactionError.categoryTypeMismatch` if category type does not match transaction type,
    ///           `TransactionError.destinationAccountRequired` if type is transfer but toAccountID is nil,
    ///           `TransactionError.sourceAndDestinationSame` if source and destination accounts match,
    ///           `TransactionError.exchangeRateRequired` if currencies differ but no exchange rate provided,
    ///           or repository errors for persistence failures.
    func execute(_ transaction: Transaction) async throws -> Transaction
}

/// Implementation of transaction update use case.
///
/// This use case reverses the original transaction's balance impact, validates the
/// replacement transaction, and applies the new balance impact. The two-step
/// balance adjustment (reverse old, apply new) handles changes to account, amount,
/// type, and currency in a single operation.
public struct UpdateTransactionUseCase: UpdateTransactionUseCaseProtocol {
    private let transactionRepository: TransactionRepositoryProtocol
    private let accountRepository: AccountRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol

    /// Creates a new transaction update use case.
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
        // 1. Fetch the original transaction to reverse its balance effect
        guard let originalTransaction = try await transactionRepository.fetch(by: transaction.id) else {
            throw TransactionError.transactionNotFound(transaction.id)
        }

        // 2. Validate new amount
        guard transaction.amount > 0 else {
            throw TransactionError.amountMustBePositive
        }

        // 3. Validate new source account exists
        guard try await accountRepository.fetch(by: transaction.accountID) != nil else {
            throw TransactionError.accountNotFound(transaction.accountID)
        }

        // 4. Validate new category exists and type matches
        guard let category = try await categoryRepository.fetch(by: transaction.categoryID) else {
            throw TransactionError.categoryRequired
        }

        if transaction.type != .transfer && category.type != transaction.type {
            throw TransactionError.categoryTypeMismatch(
                expected: transaction.type.displayName,
                got: category.type.displayName
            )
        }

        // 5. Transfer-specific validations and resolve toAmount for new transaction
        let newToAmount: Decimal
        if transaction.type == .transfer {
            guard let toAccountID = transaction.toAccountID else {
                throw TransactionError.destinationAccountRequired
            }

            guard toAccountID != transaction.accountID else {
                throw TransactionError.sourceAndDestinationSame
            }

            guard let newDestinationAccount = try await accountRepository.fetch(by: toAccountID) else {
                throw TransactionError.accountNotFound(toAccountID)
            }

            guard let newSourceAccount = try await accountRepository.fetch(by: transaction.accountID) else {
                throw TransactionError.accountNotFound(transaction.accountID)
            }

            if newSourceAccount.currency == newDestinationAccount.currency {
                newToAmount = transaction.amount
            } else {
                guard
                    let rateString = transaction.metadata?["exchangeRate"],
                    let rate = Decimal(string: rateString),
                    rate > 0
                else {
                    throw TransactionError.exchangeRateRequired
                }
                newToAmount = transaction.amount * rate
            }
        } else {
            newToAmount = transaction.amount
        }

        // 6. Resolve the original toAmount for transfer reversal
        let originalToAmount: Decimal
        if originalTransaction.type == .transfer, let originalToAccountID = originalTransaction.toAccountID {
            if let rateString = originalTransaction.metadata?["exchangeRate"],
               let rate = Decimal(string: rateString),
               rate > 0 {
                originalToAmount = originalTransaction.amount * rate
            } else {
                // Same-currency transfer or missing rate: assume 1:1
                originalToAmount = originalTransaction.amount
            }
            _ = originalToAccountID // suppress unused warning; used conceptually below
        } else {
            originalToAmount = originalTransaction.amount
        }

        // 7. Reverse the original transaction's balance effect
        switch originalTransaction.type {
        case .income:
            try await accountRepository.updateBalance(
                originalTransaction.accountID,
                delta: -originalTransaction.amount
            )

        case .expense:
            try await accountRepository.updateBalance(
                originalTransaction.accountID,
                delta: originalTransaction.amount
            )

        case .transfer:
            try await accountRepository.updateBalance(
                originalTransaction.accountID,
                delta: originalTransaction.amount
            )
            if let originalToAccountID = originalTransaction.toAccountID {
                try await accountRepository.updateBalance(
                    originalToAccountID,
                    delta: -originalToAmount
                )
            }
        }

        // 8. Apply the new transaction's balance effect
        switch transaction.type {
        case .income:
            try await accountRepository.updateBalance(transaction.accountID, delta: transaction.amount)

        case .expense:
            try await accountRepository.updateBalance(transaction.accountID, delta: -transaction.amount)

        case .transfer:
            try await accountRepository.updateBalance(transaction.accountID, delta: -transaction.amount)
            // toAccountID is guaranteed non-nil here (validated above)
            try await accountRepository.updateBalance(transaction.toAccountID!, delta: newToAmount)
        }

        // 9. Persist the updated transaction
        var updatedTransaction = transaction
        updatedTransaction.updatedAt = Date()
        try await transactionRepository.update(updatedTransaction)

        return updatedTransaction
    }
}
