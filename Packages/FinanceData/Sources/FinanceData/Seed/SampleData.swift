import FinanceCore
import Foundation
import SwiftData

// Alias to disambiguate from the Objective-C `Category` type in the SDK.
private typealias AppCategory = FinanceCore.Category

/// Pre-populated sample data for SwiftUI previews and testing.
///
/// Use ``SampleData/previewContainer`` to get a ready-to-use `ModelContainer`
/// with sample accounts, categories, and transactions already inserted.
public enum SampleData {
    // MARK: - Sample Account IDs

    private static let cashAccountID = UUID(uuidString: "AA000000-0000-0000-0000-000000000001")!
    private static let bankAccountID = UUID(uuidString: "AA000000-0000-0000-0000-000000000002")!
    private static let creditCardID = UUID(uuidString: "AA000000-0000-0000-0000-000000000003")!
    private static let momoAccountID = UUID(uuidString: "AA000000-0000-0000-0000-000000000004")!
    private static let savingsAccountID = UUID(uuidString: "AA000000-0000-0000-0000-000000000005")!

    // MARK: - Sample Tag IDs

    private static let tagBusinessID = UUID(uuidString: "BB000000-0000-0000-0000-000000000001")!
    private static let tagPersonalID = UUID(uuidString: "BB000000-0000-0000-0000-000000000002")!
    private static let tagFoodID = UUID(uuidString: "BB000000-0000-0000-0000-000000000003")!

    // MARK: - Sample Accounts

    /// Pre-built sample accounts for previews.
    public static let accounts: [Account] = [
        Account(
            id: cashAccountID,
            name: "Ví tiền mặt",
            type: .cash,
            currency: .VND,
            initialBalance: 5_000_000,
            balance: 3_250_000,
            iconName: "banknote",
            colorHex: "#34C759",
            sortOrder: 0
        ),
        Account(
            id: bankAccountID,
            name: "Vietcombank",
            type: .bank,
            currency: .VND,
            initialBalance: 50_000_000,
            balance: 42_350_000,
            iconName: "building.columns",
            colorHex: "#007AFF",
            sortOrder: 1
        ),
        Account(
            id: creditCardID,
            name: "Thẻ tín dụng VCB",
            type: .creditCard,
            currency: .VND,
            balance: -8_500_000,
            iconName: "creditcard",
            colorHex: "#FF9500",
            sortOrder: 2
        ),
        Account(
            id: momoAccountID,
            name: "MoMo",
            type: .eWallet,
            currency: .VND,
            balance: 1_200_000,
            iconName: "wallet.pass",
            colorHex: "#5856D6",
            sortOrder: 3,
            eWalletProvider: .momo
        ),
        Account(
            id: savingsAccountID,
            name: "Tiết kiệm",
            type: .savings,
            currency: .VND,
            initialBalance: 100_000_000,
            balance: 100_000_000,
            iconName: "chart.line.uptrend.xyaxis",
            colorHex: "#30B0C7",
            sortOrder: 4
        ),
    ]

    // MARK: - Sample Tags

    /// Pre-built sample tags for previews.
    public static let tags: [Tag] = [
        Tag(id: tagBusinessID, name: "Công việc", color: "#0984E3"),
        Tag(id: tagPersonalID, name: "Cá nhân", color: "#6C5CE7"),
        Tag(id: tagFoodID, name: "Ẩm thực", color: "#FF6B6B"),
    ]

    // MARK: - Sample Transactions

    /// Pre-built sample transactions for previews.
    ///
    /// Uses category IDs from ``DefaultCategories`` so the transactions
    /// match up with seeded categories.
    public static var transactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()

        return [
            // Today's expenses
            Transaction(
                amount: 85_000,
                type: .expense,
                categoryID: DefaultCategories.eatDrinkID,
                accountID: cashAccountID,
                note: "Phở bò + cà phê sáng",
                date: calendar.date(byAdding: .hour, value: -2, to: now)!,
                tags: [tagFoodID]
            ),
            Transaction(
                amount: 35_000,
                type: .expense,
                categoryID: DefaultCategories.transportID,
                accountID: momoAccountID,
                note: "Grab đi làm",
                date: calendar.date(byAdding: .hour, value: -4, to: now)!
            ),
            Transaction(
                amount: 250_000,
                type: .expense,
                categoryID: DefaultCategories.shoppingID,
                accountID: creditCardID,
                note: "Shopee - Ốp điện thoại",
                date: calendar.date(byAdding: .hour, value: -6, to: now)!
            ),

            // Yesterday
            Transaction(
                amount: 15_000_000,
                type: .income,
                categoryID: DefaultCategories.salaryID,
                accountID: bankAccountID,
                note: "Lương tháng 2",
                date: calendar.date(byAdding: .day, value: -1, to: now)!,
                tags: [tagBusinessID]
            ),
            Transaction(
                amount: 120_000,
                type: .expense,
                categoryID: DefaultCategories.eatDrinkID,
                accountID: cashAccountID,
                note: "Cơm trưa văn phòng",
                date: calendar.date(byAdding: .day, value: -1, to: now)!,
                tags: [tagFoodID]
            ),

            // 2 days ago
            Transaction(
                amount: 500_000,
                type: .transfer,
                categoryID: DefaultCategories.transferID,
                accountID: bankAccountID,
                toAccountID: momoAccountID,
                note: "Nạp tiền MoMo",
                date: calendar.date(byAdding: .day, value: -2, to: now)!
            ),
            Transaction(
                amount: 2_500_000,
                type: .expense,
                categoryID: DefaultCategories.billsID,
                accountID: bankAccountID,
                note: "Tiền điện tháng 1",
                date: calendar.date(byAdding: .day, value: -2, to: now)!
            ),

            // 3 days ago
            Transaction(
                amount: 350_000,
                type: .expense,
                categoryID: DefaultCategories.healthID,
                accountID: bankAccountID,
                note: "Khám bệnh + thuốc",
                date: calendar.date(byAdding: .day, value: -3, to: now)!
            ),

            // Last week
            Transaction(
                amount: 1_500_000,
                type: .expense,
                categoryID: DefaultCategories.entertainmentID,
                accountID: creditCardID,
                note: "Xem phim + ăn tối",
                date: calendar.date(byAdding: .day, value: -5, to: now)!
            ),
            Transaction(
                amount: 3_000_000,
                type: .expense,
                categoryID: DefaultCategories.educationID,
                accountID: bankAccountID,
                note: "Khóa học Udemy",
                date: calendar.date(byAdding: .day, value: -7, to: now)!,
                tags: [tagBusinessID]
            ),

            // 2 weeks ago
            Transaction(
                amount: 8_000_000,
                type: .expense,
                categoryID: DefaultCategories.housingID,
                accountID: bankAccountID,
                note: "Tiền nhà tháng 2",
                date: calendar.date(byAdding: .day, value: -14, to: now)!
            ),
            Transaction(
                amount: 2_000_000,
                type: .income,
                categoryID: DefaultCategories.bonusID,
                accountID: bankAccountID,
                note: "Thưởng dự án Q4",
                date: calendar.date(byAdding: .day, value: -14, to: now)!,
                tags: [tagBusinessID]
            ),
        ]
    }

    // MARK: - Sample Exchange Rates

    /// Pre-built sample exchange rates for previews.
    public static let exchangeRates: [ExchangeRate] = [
        ExchangeRate(
            baseCurrency: .USD,
            targetCurrency: .VND,
            rate: 25_450,
            date: Date(),
            source: "sample"
        ),
        ExchangeRate(
            baseCurrency: .EUR,
            targetCurrency: .VND,
            rate: 27_200,
            date: Date(),
            source: "sample"
        ),
        ExchangeRate(
            baseCurrency: .JPY,
            targetCurrency: .VND,
            rate: 170,
            date: Date(),
            source: "sample"
        ),
    ]
}
