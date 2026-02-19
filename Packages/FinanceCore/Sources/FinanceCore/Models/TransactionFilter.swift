import Foundation

/// A value type that encapsulates all criteria used to query transactions.
///
/// All properties are optional; a default-constructed `TransactionFilter` matches
/// every non-deleted transaction. Combine multiple criteria to narrow results.
/// Static convenience factories are provided for the most common queries.
public struct TransactionFilter: Sendable, Equatable {
    /// Restrict results to transactions belonging to any of these accounts.
    ///
    /// When nil, transactions from all accounts are included.
    public var accountIDs: [UUID]?

    /// Restrict results to transactions assigned to any of these categories.
    ///
    /// When nil, transactions from all categories are included.
    public var categoryIDs: [UUID]?

    /// Restrict results to transactions whose date falls within this range (inclusive).
    ///
    /// When nil, no date constraint is applied.
    public var dateRange: ClosedRange<Date>?

    /// Restrict results to transactions whose amount falls within this range (inclusive).
    ///
    /// Amounts are compared against the absolute value stored in `Transaction.amount`.
    /// When nil, no amount constraint is applied.
    public var amountRange: ClosedRange<Decimal>?

    /// Restrict results to transactions that carry any of these tags.
    ///
    /// When nil, transactions with or without tags are included.
    public var tagIDs: [UUID]?

    /// Free-text search applied against the transaction note field.
    ///
    /// Matching is case-insensitive. When nil or empty, no text filtering is applied.
    public var searchText: String?

    /// Restrict results to transactions of any of these types.
    ///
    /// When nil, all transaction types are included.
    public var types: [TransactionType]?

    /// When `true`, transfer transactions are excluded from results.
    ///
    /// Defaults to `false`.
    public var excludeTransfers: Bool

    /// Creates a transaction filter with the specified criteria.
    ///
    /// All parameters are optional with sensible defaults. Omit any parameter
    /// to leave that criterion unrestricted.
    ///
    /// - Parameters:
    ///   - accountIDs: Account IDs to include. Defaults to nil (all accounts).
    ///   - categoryIDs: Category IDs to include. Defaults to nil (all categories).
    ///   - dateRange: Inclusive date range. Defaults to nil (no date constraint).
    ///   - amountRange: Inclusive amount range. Defaults to nil (no amount constraint).
    ///   - tagIDs: Tag IDs to include. Defaults to nil (any tags).
    ///   - searchText: Text to match against notes. Defaults to nil (no text filter).
    ///   - types: Transaction types to include. Defaults to nil (all types).
    ///   - excludeTransfers: Whether to exclude transfer transactions. Defaults to false.
    public init(
        accountIDs: [UUID]? = nil,
        categoryIDs: [UUID]? = nil,
        dateRange: ClosedRange<Date>? = nil,
        amountRange: ClosedRange<Decimal>? = nil,
        tagIDs: [UUID]? = nil,
        searchText: String? = nil,
        types: [TransactionType]? = nil,
        excludeTransfers: Bool = false
    ) {
        self.accountIDs = accountIDs
        self.categoryIDs = categoryIDs
        self.dateRange = dateRange
        self.amountRange = amountRange
        self.tagIDs = tagIDs
        self.searchText = searchText
        self.types = types
        self.excludeTransfers = excludeTransfers
    }
}

// MARK: - Static Convenience Factories

extension TransactionFilter {
    /// A filter that matches all transactions recorded today (midnight to midnight,
    /// in the current calendar and time zone).
    public static var today: TransactionFilter {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        // swiftlint:disable:next force_unwrapping
        let end = calendar.date(byAdding: .day, value: 1, to: start)!.addingTimeInterval(-1)
        return TransactionFilter(dateRange: start...end)
    }

    /// A filter that matches all transactions recorded in the current calendar week
    /// (Monday through Sunday, or Sunday through Saturday depending on locale).
    public static var thisWeek: TransactionFilter {
        let calendar = Calendar.current
        let now = Date()
        guard
            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now)
        else {
            return TransactionFilter()
        }
        let end = weekInterval.end.addingTimeInterval(-1)
        return TransactionFilter(dateRange: weekInterval.start...end)
    }

    /// A filter that matches all transactions recorded in the current calendar month.
    public static var thisMonth: TransactionFilter {
        let calendar = Calendar.current
        let now = Date()
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: now)
        else {
            return TransactionFilter()
        }
        let end = monthInterval.end.addingTimeInterval(-1)
        return TransactionFilter(dateRange: monthInterval.start...end)
    }

    /// A filter that matches all transactions belonging to a single account.
    ///
    /// - Parameter id: The unique identifier of the account to filter by.
    /// - Returns: A filter restricted to the specified account.
    public static func forAccount(_ id: UUID) -> TransactionFilter {
        TransactionFilter(accountIDs: [id])
    }
}
