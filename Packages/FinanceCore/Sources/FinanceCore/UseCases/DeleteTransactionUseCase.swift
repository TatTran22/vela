import Foundation

/// Protocol for deleting financial transactions.
///
/// This use case handles soft deletion of transactions with automatic reversal of
/// the affected account balances, ensuring financial data remains consistent
/// after a transaction is removed.
public protocol DeleteTransactionUseCaseProtocol: Sendable {
    /// Soft-deletes a transaction and reverses its account balance effect.
    ///
    /// The deletion procedure is:
    /// 1. Fetch and verify the transaction exists.
    /// 2. Reverse the transaction's balance impact on the affected account(s).
    /// 3. Soft-delete the transaction (set `deletedAt`) via the repository.
    ///
    /// Balance reversal rules:
    /// - Income: `account.balance -= amount`
    /// - Expense: `account.balance += amount`
    /// - Transfer: `source.balance += amount`, `destination.balance -= toAmount`
    ///
    /// For cross-currency transfers, `toAmount` is derived from the exchange rate
    /// stored in `transaction.metadata["exchangeRate"]`. If no rate is found but the
    /// accounts had different currencies, a 1:1 rate is assumed for the reversal
    /// (the metadata may have been lost; balance correction must proceed).
    ///
    /// - Parameter id: The unique identifier of the transaction to delete.
    /// - Throws: `TransactionError.transactionNotFound` if no record matches the ID,
    ///           or repository errors for persistence failures.
    func execute(id: UUID) async throws
}

/// Implementation of transaction deletion use case.
///
/// This use case reverses the balance impact of a transaction before soft-deleting it,
/// keeping all account balances accurate without requiring a full recalculation pass.
public struct DeleteTransactionUseCase: DeleteTransactionUseCaseProtocol {
    private let transactionRepository: TransactionRepositoryProtocol
    private let accountRepository: AccountRepositoryProtocol

    /// Creates a new transaction deletion use case.
    ///
    /// - Parameters:
    ///   - transactionRepository: The repository for transaction persistence.
    ///   - accountRepository: The repository for account balance updates.
    public init(
        transactionRepository: TransactionRepositoryProtocol,
        accountRepository: AccountRepositoryProtocol
    ) {
        self.transactionRepository = transactionRepository
        self.accountRepository = accountRepository
    }

    public func execute(id: UUID) async throws {
        // 1. Fetch the transaction; fail fast if it does not exist
        guard let transaction = try await transactionRepository.fetch(by: id) else {
            throw TransactionError.transactionNotFound(id)
        }

        // 2. Resolve the destination amount for transfers before reversing balances
        let toAmount: Decimal
        if transaction.type == .transfer {
            if let rateString = transaction.metadata?["exchangeRate"],
               let rate = Decimal(string: rateString),
               rate > 0 {
                toAmount = transaction.amount * rate
            } else {
                // Same-currency transfer or metadata unavailable; fall back to 1:1
                toAmount = transaction.amount
            }
        } else {
            toAmount = transaction.amount
        }

        // 3. Reverse the balance effect of the transaction
        switch transaction.type {
        case .income:
            // Income added to account — subtract it back
            try await accountRepository.updateBalance(transaction.accountID, delta: -transaction.amount)

        case .expense:
            // Expense subtracted from account — add it back
            try await accountRepository.updateBalance(transaction.accountID, delta: transaction.amount)

        case .transfer:
            // Source was debited — credit it back
            try await accountRepository.updateBalance(transaction.accountID, delta: transaction.amount)
            // Destination was credited — debit it back
            if let toAccountID = transaction.toAccountID {
                try await accountRepository.updateBalance(toAccountID, delta: -toAmount)
            }
        }

        // 4. Soft-delete the transaction via the repository
        try await transactionRepository.delete(by: id)
    }
}
