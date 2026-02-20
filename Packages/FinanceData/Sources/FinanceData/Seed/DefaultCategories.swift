import FinanceCore
import Foundation

// Alias to disambiguate from the Objective-C `Category` type in the SDK.
private typealias AppCategory = FinanceCore.Category

/// Provides the built-in default categories seeded on first launch.
///
/// All categories use fixed UUIDs so that the seed operation is idempotent —
/// re-running it will not create duplicate records when the repository checks
/// for existing IDs before inserting.
public enum DefaultCategories {
    // MARK: - Expense Category IDs

    /// Ăn uống
    public static let eatDrinkID = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
    /// Di chuyển
    public static let transportID = UUID(uuidString: "10000000-0000-0000-0000-000000000002")!
    /// Mua sắm
    public static let shoppingID = UUID(uuidString: "10000000-0000-0000-0000-000000000003")!
    /// Nhà ở
    public static let housingID = UUID(uuidString: "10000000-0000-0000-0000-000000000004")!
    /// Hóa đơn & Tiện ích
    public static let billsID = UUID(uuidString: "10000000-0000-0000-0000-000000000005")!
    /// Giải trí
    public static let entertainmentID = UUID(uuidString: "10000000-0000-0000-0000-000000000006")!
    /// Sức khỏe
    public static let healthID = UUID(uuidString: "10000000-0000-0000-0000-000000000007")!
    /// Giáo dục
    public static let educationID = UUID(uuidString: "10000000-0000-0000-0000-000000000008")!
    /// Cá nhân
    public static let personalID = UUID(uuidString: "10000000-0000-0000-0000-000000000009")!
    /// Khác (expense)
    public static let otherExpenseID = UUID(uuidString: "10000000-0000-0000-0000-00000000000A")!

    // MARK: - Income Category IDs

    /// Lương
    public static let salaryID = UUID(uuidString: "20000000-0000-0000-0000-000000000001")!
    /// Thưởng
    public static let bonusID = UUID(uuidString: "20000000-0000-0000-0000-000000000002")!
    /// Đầu tư
    public static let investmentID = UUID(uuidString: "20000000-0000-0000-0000-000000000003")!
    /// Kinh doanh
    public static let businessID = UUID(uuidString: "20000000-0000-0000-0000-000000000004")!
    /// Thu nhập khác
    public static let otherIncomeID = UUID(uuidString: "20000000-0000-0000-0000-000000000005")!

    // MARK: - Transfer Category IDs

    /// Chuyển khoản
    public static let transferID = UUID(uuidString: "30000000-0000-0000-0000-000000000001")!

    // MARK: - Public Seed Data

    /// All built-in default categories.
    ///
    /// The array is ordered so that top-level categories come before their
    /// children, which allows repositories to insert them in a single pass.
    public static let all: [FinanceCore.Category] = expense + income + transfer

    // MARK: - Private Builders

    private static let expense: [AppCategory] = [
        AppCategory(
            id: eatDrinkID,
            name: "Ăn uống",
            iconName: "fork.knife",
            colorHex: "#FF6B6B",
            type: .expense,
            sortOrder: 0,
            isDefault: true
        ),
        AppCategory(
            id: transportID,
            name: "Di chuyển",
            iconName: "car.fill",
            colorHex: "#4ECDC4",
            type: .expense,
            sortOrder: 1,
            isDefault: true
        ),
        AppCategory(
            id: shoppingID,
            name: "Mua sắm",
            iconName: "bag.fill",
            colorHex: "#45B7D1",
            type: .expense,
            sortOrder: 2,
            isDefault: true
        ),
        AppCategory(
            id: housingID,
            name: "Nhà ở",
            iconName: "house.fill",
            colorHex: "#96CEB4",
            type: .expense,
            sortOrder: 3,
            isDefault: true
        ),
        AppCategory(
            id: billsID,
            name: "Hóa đơn & Tiện ích",
            iconName: "doc.text.fill",
            colorHex: "#FFEAA7",
            type: .expense,
            sortOrder: 4,
            isDefault: true
        ),
        AppCategory(
            id: entertainmentID,
            name: "Giải trí",
            iconName: "gamecontroller.fill",
            colorHex: "#DDA0DD",
            type: .expense,
            sortOrder: 5,
            isDefault: true
        ),
        AppCategory(
            id: healthID,
            name: "Sức khỏe",
            iconName: "heart.fill",
            colorHex: "#FF6B6B",
            type: .expense,
            sortOrder: 6,
            isDefault: true
        ),
        AppCategory(
            id: educationID,
            name: "Giáo dục",
            iconName: "book.fill",
            colorHex: "#74B9FF",
            type: .expense,
            sortOrder: 7,
            isDefault: true
        ),
        AppCategory(
            id: personalID,
            name: "Cá nhân",
            iconName: "person.fill",
            colorHex: "#A29BFE",
            type: .expense,
            sortOrder: 8,
            isDefault: true
        ),
        AppCategory(
            id: otherExpenseID,
            name: "Khác",
            iconName: "ellipsis.circle.fill",
            colorHex: "#636E72",
            type: .expense,
            sortOrder: 9,
            isDefault: true
        ),
    ]

    private static let income: [AppCategory] = [
        AppCategory(
            id: salaryID,
            name: "Lương",
            iconName: "banknote.fill",
            colorHex: "#00B894",
            type: .income,
            sortOrder: 0,
            isDefault: true
        ),
        AppCategory(
            id: bonusID,
            name: "Thưởng",
            iconName: "gift.fill",
            colorHex: "#FDCB6E",
            type: .income,
            sortOrder: 1,
            isDefault: true
        ),
        AppCategory(
            id: investmentID,
            name: "Đầu tư",
            iconName: "chart.line.uptrend.xyaxis",
            colorHex: "#6C5CE7",
            type: .income,
            sortOrder: 2,
            isDefault: true
        ),
        AppCategory(
            id: businessID,
            name: "Kinh doanh",
            iconName: "briefcase.fill",
            colorHex: "#0984E3",
            type: .income,
            sortOrder: 3,
            isDefault: true
        ),
        AppCategory(
            id: otherIncomeID,
            name: "Thu nhập khác",
            iconName: "plus.circle.fill",
            colorHex: "#00CEC9",
            type: .income,
            sortOrder: 4,
            isDefault: true
        ),
    ]

    private static let transfer: [AppCategory] = [
        AppCategory(
            id: transferID,
            name: "Chuyển khoản",
            iconName: "arrow.left.arrow.right",
            colorHex: "#0984E3",
            type: .transfer,
            sortOrder: 0,
            isDefault: true
        ),
    ]
}
