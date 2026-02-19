import Foundation

/// Errors that can occur during account operations.
///
/// These errors represent domain-level validation and business rule violations
/// related to account management.
public enum AccountError: Error, Sendable, Equatable {
    /// The account name cannot be empty.
    case nameEmpty

    /// An account with the given name already exists.
    case nameAlreadyExists(String)

    /// The user has reached the maximum number of accounts allowed in the free tier.
    case freeTierLimitReached(maxAccounts: Int)

    /// Cannot change the currency of an account that has existing transactions.
    case cannotChangeCurrencyWithTransactions

    /// Cannot delete an account that has existing transactions.
    case cannotDeleteAccountWithTransactions

    /// The account with the specified ID was not found.
    case accountNotFound(UUID)
}

extension AccountError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .nameEmpty:
            return "Account name cannot be empty."
        case .nameAlreadyExists(let name):
            return "An account named \"\(name)\" already exists."
        case .freeTierLimitReached(let maxAccounts):
            return "You have reached the free tier limit of \(maxAccounts) accounts. Upgrade to Premium to add more."
        case .cannotChangeCurrencyWithTransactions:
            return "Cannot change currency for an account with existing transactions."
        case .cannotDeleteAccountWithTransactions:
            return "Cannot delete an account with existing transactions. Archive it instead or delete all transactions first."
        case .accountNotFound(let id):
            return "Account with ID \(id) was not found."
        }
    }
}

/// Errors that can occur during exchange rate operations.
///
/// These errors represent failures in fetching, caching, or applying
/// currency exchange rates for multi-currency support.
public enum ExchangeRateError: Error, Sendable, Equatable {
    /// No exchange rate found for the specified currency pair.
    case rateNotFound(from: CurrencyCode, to: CurrencyCode)

    /// Network is unavailable and cannot fetch fresh exchange rates.
    case networkUnavailable

    /// The cached exchange rate has expired and needs to be refreshed.
    case cacheExpired
}

extension ExchangeRateError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .rateNotFound(let from, let to):
            return "Exchange rate not found for \(from.rawValue) to \(to.rawValue)."
        case .networkUnavailable:
            return "Network is unavailable. Cannot fetch current exchange rates."
        case .cacheExpired:
            return "Cached exchange rate has expired. Please refresh to get the latest rates."
        }
    }
}
