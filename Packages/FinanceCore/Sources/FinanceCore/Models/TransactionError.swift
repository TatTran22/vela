import Foundation

/// Errors that can occur during transaction operations.
///
/// These errors represent domain-level validation and business rule violations
/// related to transaction creation, updating, and deletion.
public enum TransactionError: Error, Sendable, Equatable {
    /// The transaction amount must be greater than zero.
    case amountMustBePositive

    /// The account with the specified ID was not found.
    case accountNotFound(UUID)

    /// A category must be provided for all transaction types.
    case categoryRequired

    /// The category's transaction type does not match the transaction type.
    ///
    /// For example, using an expense category on an income transaction.
    case categoryTypeMismatch(expected: String, got: String)

    /// A transfer cannot use the same account as both source and destination.
    case sourceAndDestinationSame

    /// A destination account is required for transfer transactions.
    case destinationAccountRequired

    /// The transaction with the specified ID was not found.
    case transactionNotFound(UUID)

    /// An exchange rate is required when the source and destination accounts
    /// use different currencies.
    case exchangeRateRequired

    /// The amount expression string could not be parsed.
    ///
    /// The associated value contains the offending expression string.
    case invalidExpression(String)
}

extension TransactionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .amountMustBePositive:
            return "Transaction amount must be greater than zero."
        case .accountNotFound(let id):
            return "Account with ID \(id) was not found."
        case .categoryRequired:
            return "A category is required for this transaction."
        case .categoryTypeMismatch(let expected, let got):
            return "Category type mismatch: expected \"\(expected)\" but got \"\(got)\"."
        case .sourceAndDestinationSame:
            return "The source and destination accounts must be different."
        case .destinationAccountRequired:
            return "A destination account is required for transfer transactions."
        case .transactionNotFound(let id):
            return "Transaction with ID \(id) was not found."
        case .exchangeRateRequired:
            return "An exchange rate is required when transferring between accounts with different currencies."
        case .invalidExpression(let expression):
            return "Could not parse amount expression: \"\(expression)\"."
        }
    }
}
