import Testing
import Foundation

@testable import FinanceCore

// MARK: - T25: TransactionFilter Tests

@Suite("TransactionFilter Tests")
struct TransactionFilterTests {

    // MARK: - Default Filter

    @Test("Default filter has all nil optional fields")
    func defaultFilterAllNil() {
        let filter = TransactionFilter()

        #expect(filter.accountIDs == nil)
        #expect(filter.categoryIDs == nil)
        #expect(filter.dateRange == nil)
        #expect(filter.amountRange == nil)
        #expect(filter.tagIDs == nil)
        #expect(filter.searchText == nil)
        #expect(filter.types == nil)
    }

    @Test("Default filter has excludeTransfers set to false")
    func defaultFilterExcludeTransfersFalse() {
        let filter = TransactionFilter()
        #expect(filter.excludeTransfers == false)
    }

    @Test("Default filter equals another default filter")
    func defaultFilterEquality() {
        let filter1 = TransactionFilter()
        let filter2 = TransactionFilter()
        #expect(filter1 == filter2)
    }

    // MARK: - Custom Initialisation

    @Test("Custom filter preserves all specified criteria")
    func customFilterPreservesCriteria() {
        let accountID = UUID()
        let categoryID = UUID()
        let tagID = UUID()
        let now = Date()
        let range = now...now.addingTimeInterval(86400)
        let amountRange = Decimal(1_000)...Decimal(500_000)

        let filter = TransactionFilter(
            accountIDs: [accountID],
            categoryIDs: [categoryID],
            dateRange: range,
            amountRange: amountRange,
            tagIDs: [tagID],
            searchText: "coffee",
            types: [.expense],
            excludeTransfers: true
        )

        #expect(filter.accountIDs == [accountID])
        #expect(filter.categoryIDs == [categoryID])
        #expect(filter.dateRange == range)
        #expect(filter.amountRange == amountRange)
        #expect(filter.tagIDs == [tagID])
        #expect(filter.searchText == "coffee")
        #expect(filter.types == [.expense])
        #expect(filter.excludeTransfers == true)
    }

    // MARK: - Static Factory: .today

    @Test(".today filter has a date range")
    func todayFilterHasDateRange() {
        let filter = TransactionFilter.today
        #expect(filter.dateRange != nil)
    }

    @Test(".today filter start is midnight of today")
    func todayFilterStartIsMidnight() {
        let filter = TransactionFilter.today
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        guard let range = filter.dateRange else {
            Issue.record("Expected dateRange to be non-nil")
            return
        }

        #expect(range.lowerBound == startOfToday)
    }

    @Test(".today filter end is before midnight tomorrow")
    func todayFilterEndIsBeforeTomorrow() {
        let filter = TransactionFilter.today
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        // swiftlint:disable:next force_unwrapping
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        guard let range = filter.dateRange else {
            Issue.record("Expected dateRange to be non-nil")
            return
        }

        #expect(range.upperBound < startOfTomorrow)
    }

    @Test(".today filter contains current time")
    func todayFilterContainsNow() {
        let filter = TransactionFilter.today

        guard let range = filter.dateRange else {
            Issue.record("Expected dateRange to be non-nil")
            return
        }

        #expect(range.contains(Date()))
    }

    @Test(".today filter has all other optionals nil")
    func todayFilterOtherOptionalNil() {
        let filter = TransactionFilter.today
        #expect(filter.accountIDs == nil)
        #expect(filter.categoryIDs == nil)
        #expect(filter.searchText == nil)
        #expect(filter.excludeTransfers == false)
    }

    // MARK: - Static Factory: .thisWeek

    @Test(".thisWeek filter has a date range")
    func thisWeekFilterHasDateRange() {
        let filter = TransactionFilter.thisWeek
        #expect(filter.dateRange != nil)
    }

    @Test(".thisWeek filter contains current time")
    func thisWeekFilterContainsNow() {
        let filter = TransactionFilter.thisWeek

        guard let range = filter.dateRange else {
            Issue.record("Expected dateRange to be non-nil")
            return
        }

        #expect(range.contains(Date()))
    }

    @Test(".thisWeek filter start is at or before start of today")
    func thisWeekFilterStartBeforeToday() {
        let filter = TransactionFilter.thisWeek
        let startOfToday = Calendar.current.startOfDay(for: Date())

        guard let range = filter.dateRange else {
            Issue.record("Expected dateRange to be non-nil")
            return
        }

        #expect(range.lowerBound <= startOfToday)
    }

    @Test(".thisWeek filter spans at most 7 days")
    func thisWeekFilterSpansAtMostSevenDays() {
        let filter = TransactionFilter.thisWeek

        guard let range = filter.dateRange else {
            Issue.record("Expected dateRange to be non-nil")
            return
        }

        let seconds = range.upperBound.timeIntervalSince(range.lowerBound)
        let sevenDaysInSeconds: TimeInterval = 7 * 24 * 60 * 60
        #expect(seconds <= sevenDaysInSeconds)
    }

    // MARK: - Static Factory: .thisMonth

    @Test(".thisMonth filter has a date range")
    func thisMonthFilterHasDateRange() {
        let filter = TransactionFilter.thisMonth
        #expect(filter.dateRange != nil)
    }

    @Test(".thisMonth filter contains current time")
    func thisMonthFilterContainsNow() {
        let filter = TransactionFilter.thisMonth

        guard let range = filter.dateRange else {
            Issue.record("Expected dateRange to be non-nil")
            return
        }

        #expect(range.contains(Date()))
    }

    @Test(".thisMonth filter start is on day 1 of current month")
    func thisMonthFilterStartIsFirstOfMonth() {
        let filter = TransactionFilter.thisMonth
        let calendar = Calendar.current

        guard let range = filter.dateRange else {
            Issue.record("Expected dateRange to be non-nil")
            return
        }

        let dayOfMonth = calendar.component(.day, from: range.lowerBound)
        #expect(dayOfMonth == 1)
    }

    @Test(".thisMonth filter end is within the current month")
    func thisMonthFilterEndIsWithinCurrentMonth() {
        let filter = TransactionFilter.thisMonth
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())

        guard let range = filter.dateRange else {
            Issue.record("Expected dateRange to be non-nil")
            return
        }

        let endMonth = calendar.component(.month, from: range.upperBound)
        #expect(endMonth == currentMonth)
    }

    // MARK: - Static Factory: .forAccount(id:)

    @Test(".forAccount sets accountIDs to the specified single ID")
    func forAccountSetsAccountID() {
        let id = UUID()
        let filter = TransactionFilter.forAccount(id)
        #expect(filter.accountIDs == [id])
    }

    @Test(".forAccount has all other optionals nil")
    func forAccountOtherOptionalNil() {
        let filter = TransactionFilter.forAccount(UUID())
        #expect(filter.categoryIDs == nil)
        #expect(filter.dateRange == nil)
        #expect(filter.searchText == nil)
        #expect(filter.excludeTransfers == false)
    }

    @Test(".forAccount filters are not equal to filter for different account")
    func forAccountDifferentIDNotEqual() {
        let filter1 = TransactionFilter.forAccount(UUID())
        let filter2 = TransactionFilter.forAccount(UUID())
        #expect(filter1 != filter2)
    }

    // MARK: - Mutability

    @Test("Filter fields can be mutated after construction")
    func filterFieldsMutable() {
        var filter = TransactionFilter()
        let accountID = UUID()
        filter.accountIDs = [accountID]
        filter.excludeTransfers = true

        #expect(filter.accountIDs == [accountID])
        #expect(filter.excludeTransfers == true)
    }

    @Test("Two filters with same values are equal")
    func filtersWithSameValuesAreEqual() {
        let accountID = UUID()
        let filter1 = TransactionFilter(accountIDs: [accountID])
        let filter2 = TransactionFilter(accountIDs: [accountID])
        #expect(filter1 == filter2)
    }

    @Test("Two filters with different values are not equal")
    func filtersWithDifferentValuesAreNotEqual() {
        let filter1 = TransactionFilter(accountIDs: [UUID()])
        let filter2 = TransactionFilter(accountIDs: [UUID()])
        #expect(filter1 != filter2)
    }
}
