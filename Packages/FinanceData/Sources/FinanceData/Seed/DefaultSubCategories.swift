import FinanceCore
import Foundation

// Alias to disambiguate from the Objective-C `Category` type in the SDK.
private typealias AppCategory = FinanceCore.Category

/// Provides the built-in default sub-categories seeded on first launch.
///
/// All sub-categories use fixed UUIDs (prefix `11000000`) so that the seed
/// operation is idempotent — re-running it will not create duplicate records.
/// Each sub-category has its `parentID` set to the corresponding parent from
/// `DefaultCategories` and inherits the parent's `colorHex`.
public enum DefaultSubCategories {
    // MARK: - Ăn uống sub-category IDs

    /// Cơm
    public static let eatDrink_comID = UUID(uuidString: "11000000-0001-0000-0000-000000000001")!
    /// Café/Trà sữa
    public static let eatDrink_cafeID = UUID(uuidString: "11000000-0001-0000-0000-000000000002")!
    /// Ăn vặt
    public static let eatDrink_anVatID = UUID(uuidString: "11000000-0001-0000-0000-000000000003")!
    /// Nhậu
    public static let eatDrink_nhauID = UUID(uuidString: "11000000-0001-0000-0000-000000000004")!

    // MARK: - Nhà ở sub-category IDs

    /// Tiền nhà
    public static let housing_tienNhaID = UUID(uuidString: "11000000-0002-0000-0000-000000000001")!
    /// Điện
    public static let housing_dienID = UUID(uuidString: "11000000-0002-0000-0000-000000000002")!
    /// Nước
    public static let housing_nuocID = UUID(uuidString: "11000000-0002-0000-0000-000000000003")!
    /// Internet
    public static let housing_internetID = UUID(uuidString: "11000000-0002-0000-0000-000000000004")!
    /// Gas
    public static let housing_gasID = UUID(uuidString: "11000000-0002-0000-0000-000000000005")!

    // MARK: - Di chuyển sub-category IDs

    /// Xăng
    public static let transport_xangID = UUID(uuidString: "11000000-0003-0000-0000-000000000001")!
    /// Grab/Taxi
    public static let transport_grabID = UUID(uuidString: "11000000-0003-0000-0000-000000000002")!
    /// Gửi xe
    public static let transport_guiXeID = UUID(uuidString: "11000000-0003-0000-0000-000000000003")!
    /// Bảo dưỡng xe
    public static let transport_baoDuongID = UUID(uuidString: "11000000-0003-0000-0000-000000000004")!

    // MARK: - Mua sắm sub-category IDs

    /// Quần áo
    public static let shopping_quanAoID = UUID(uuidString: "11000000-0004-0000-0000-000000000001")!
    /// Đồ gia dụng
    public static let shopping_doGiaDungID = UUID(uuidString: "11000000-0004-0000-0000-000000000002")!
    /// Điện tử
    public static let shopping_dienTuID = UUID(uuidString: "11000000-0004-0000-0000-000000000003")!

    // MARK: - Giải trí sub-category IDs

    /// Phim
    public static let entertainment_phimID = UUID(uuidString: "11000000-0005-0000-0000-000000000001")!
    /// Game
    public static let entertainment_gameID = UUID(uuidString: "11000000-0005-0000-0000-000000000002")!
    /// Du lịch
    public static let entertainment_duLichID = UUID(uuidString: "11000000-0005-0000-0000-000000000003")!
    /// Thể thao
    public static let entertainment_theThaoID = UUID(uuidString: "11000000-0005-0000-0000-000000000004")!

    // MARK: - Sức khỏe sub-category IDs

    /// Thuốc
    public static let health_thuocID = UUID(uuidString: "11000000-0006-0000-0000-000000000001")!
    /// Khám bệnh
    public static let health_khamBenhID = UUID(uuidString: "11000000-0006-0000-0000-000000000002")!
    /// Gym
    public static let health_gymID = UUID(uuidString: "11000000-0006-0000-0000-000000000003")!

    // MARK: - Giáo dục sub-category IDs

    /// Học phí
    public static let education_hocPhiID = UUID(uuidString: "11000000-0007-0000-0000-000000000001")!
    /// Sách
    public static let education_sachID = UUID(uuidString: "11000000-0007-0000-0000-000000000002")!
    /// Khóa học
    public static let education_khoaHocID = UUID(uuidString: "11000000-0007-0000-0000-000000000003")!

    // MARK: - Gia đình sub-category IDs (under personalID)

    /// Biếu bố mẹ
    public static let personal_bieuBoMeID = UUID(uuidString: "11000000-0008-0000-0000-000000000001")!
    /// Con cái
    public static let personal_conCaiID = UUID(uuidString: "11000000-0008-0000-0000-000000000002")!
    /// Thú cưng
    public static let personal_thuCungID = UUID(uuidString: "11000000-0008-0000-0000-000000000003")!

    // MARK: - Tài chính sub-category IDs (under billsID)

    /// Bảo hiểm
    public static let bills_baoHiemID = UUID(uuidString: "11000000-0009-0000-0000-000000000001")!
    /// Đầu tư
    public static let bills_dauTuID = UUID(uuidString: "11000000-0009-0000-0000-000000000002")!
    /// Trả nợ
    public static let bills_traNoDB = UUID(uuidString: "11000000-0009-0000-0000-000000000003")!
    /// Phí ngân hàng
    public static let bills_phiNganHangID = UUID(uuidString: "11000000-0009-0000-0000-000000000004")!

    // MARK: - Public Seed Data

    /// All built-in default sub-categories.
    ///
    /// Sub-categories are grouped by parent. Within each group the order reflects
    /// the desired display order (`sortOrder` starts at 0 per group).
    public static let all: [FinanceCore.Category] =
        eatDrink + housing + transport + shopping + entertainment + health + education + personal + bills

    // MARK: - Private Builders

    private static let eatDrink: [AppCategory] = [
        AppCategory(
            id: eatDrink_comID,
            name: "Cơm",
            iconName: "fork.knife.circle",
            colorHex: "#FF6B6B",
            type: .expense,
            parentID: DefaultCategories.eatDrinkID,
            sortOrder: 0,
            isDefault: true
        ),
        AppCategory(
            id: eatDrink_cafeID,
            name: "Café/Trà sữa",
            iconName: "cup.and.saucer.fill",
            colorHex: "#FF6B6B",
            type: .expense,
            parentID: DefaultCategories.eatDrinkID,
            sortOrder: 1,
            isDefault: true
        ),
        AppCategory(
            id: eatDrink_anVatID,
            name: "Ăn vặt",
            iconName: "birthday.cake.fill",
            colorHex: "#FF6B6B",
            type: .expense,
            parentID: DefaultCategories.eatDrinkID,
            sortOrder: 2,
            isDefault: true
        ),
        AppCategory(
            id: eatDrink_nhauID,
            name: "Nhậu",
            iconName: "wineglass.fill",
            colorHex: "#FF6B6B",
            type: .expense,
            parentID: DefaultCategories.eatDrinkID,
            sortOrder: 3,
            isDefault: true
        ),
    ]

    private static let housing: [AppCategory] = [
        AppCategory(
            id: housing_tienNhaID,
            name: "Tiền nhà",
            iconName: "house.lodge.fill",
            colorHex: "#96CEB4",
            type: .expense,
            parentID: DefaultCategories.housingID,
            sortOrder: 0,
            isDefault: true
        ),
        AppCategory(
            id: housing_dienID,
            name: "Điện",
            iconName: "bolt.fill",
            colorHex: "#96CEB4",
            type: .expense,
            parentID: DefaultCategories.housingID,
            sortOrder: 1,
            isDefault: true
        ),
        AppCategory(
            id: housing_nuocID,
            name: "Nước",
            iconName: "drop.fill",
            colorHex: "#96CEB4",
            type: .expense,
            parentID: DefaultCategories.housingID,
            sortOrder: 2,
            isDefault: true
        ),
        AppCategory(
            id: housing_internetID,
            name: "Internet",
            iconName: "wifi",
            colorHex: "#96CEB4",
            type: .expense,
            parentID: DefaultCategories.housingID,
            sortOrder: 3,
            isDefault: true
        ),
        AppCategory(
            id: housing_gasID,
            name: "Gas",
            iconName: "flame.fill",
            colorHex: "#96CEB4",
            type: .expense,
            parentID: DefaultCategories.housingID,
            sortOrder: 4,
            isDefault: true
        ),
    ]

    private static let transport: [AppCategory] = [
        AppCategory(
            id: transport_xangID,
            name: "Xăng",
            iconName: "fuelpump.fill",
            colorHex: "#4ECDC4",
            type: .expense,
            parentID: DefaultCategories.transportID,
            sortOrder: 0,
            isDefault: true
        ),
        AppCategory(
            id: transport_grabID,
            name: "Grab/Taxi",
            iconName: "car.side.fill",
            colorHex: "#4ECDC4",
            type: .expense,
            parentID: DefaultCategories.transportID,
            sortOrder: 1,
            isDefault: true
        ),
        AppCategory(
            id: transport_guiXeID,
            name: "Gửi xe",
            iconName: "parkingsign",
            colorHex: "#4ECDC4",
            type: .expense,
            parentID: DefaultCategories.transportID,
            sortOrder: 2,
            isDefault: true
        ),
        AppCategory(
            id: transport_baoDuongID,
            name: "Bảo dưỡng xe",
            iconName: "wrench.fill",
            colorHex: "#4ECDC4",
            type: .expense,
            parentID: DefaultCategories.transportID,
            sortOrder: 3,
            isDefault: true
        ),
    ]

    private static let shopping: [AppCategory] = [
        AppCategory(
            id: shopping_quanAoID,
            name: "Quần áo",
            iconName: "tshirt.fill",
            colorHex: "#45B7D1",
            type: .expense,
            parentID: DefaultCategories.shoppingID,
            sortOrder: 0,
            isDefault: true
        ),
        AppCategory(
            id: shopping_doGiaDungID,
            name: "Đồ gia dụng",
            iconName: "washer.fill",
            colorHex: "#45B7D1",
            type: .expense,
            parentID: DefaultCategories.shoppingID,
            sortOrder: 1,
            isDefault: true
        ),
        AppCategory(
            id: shopping_dienTuID,
            name: "Điện tử",
            iconName: "desktopcomputer",
            colorHex: "#45B7D1",
            type: .expense,
            parentID: DefaultCategories.shoppingID,
            sortOrder: 2,
            isDefault: true
        ),
    ]

    private static let entertainment: [AppCategory] = [
        AppCategory(
            id: entertainment_phimID,
            name: "Phim",
            iconName: "film.fill",
            colorHex: "#DDA0DD",
            type: .expense,
            parentID: DefaultCategories.entertainmentID,
            sortOrder: 0,
            isDefault: true
        ),
        AppCategory(
            id: entertainment_gameID,
            name: "Game",
            iconName: "gamecontroller.fill",
            colorHex: "#DDA0DD",
            type: .expense,
            parentID: DefaultCategories.entertainmentID,
            sortOrder: 1,
            isDefault: true
        ),
        AppCategory(
            id: entertainment_duLichID,
            name: "Du lịch",
            iconName: "airplane",
            colorHex: "#DDA0DD",
            type: .expense,
            parentID: DefaultCategories.entertainmentID,
            sortOrder: 2,
            isDefault: true
        ),
        AppCategory(
            id: entertainment_theThaoID,
            name: "Thể thao",
            iconName: "sportscourt.fill",
            colorHex: "#DDA0DD",
            type: .expense,
            parentID: DefaultCategories.entertainmentID,
            sortOrder: 3,
            isDefault: true
        ),
    ]

    private static let health: [AppCategory] = [
        AppCategory(
            id: health_thuocID,
            name: "Thuốc",
            iconName: "pills.fill",
            colorHex: "#FF6B6B",
            type: .expense,
            parentID: DefaultCategories.healthID,
            sortOrder: 0,
            isDefault: true
        ),
        AppCategory(
            id: health_khamBenhID,
            name: "Khám bệnh",
            iconName: "stethoscope",
            colorHex: "#FF6B6B",
            type: .expense,
            parentID: DefaultCategories.healthID,
            sortOrder: 1,
            isDefault: true
        ),
        AppCategory(
            id: health_gymID,
            name: "Gym",
            iconName: "dumbbell.fill",
            colorHex: "#FF6B6B",
            type: .expense,
            parentID: DefaultCategories.healthID,
            sortOrder: 2,
            isDefault: true
        ),
    ]

    private static let education: [AppCategory] = [
        AppCategory(
            id: education_hocPhiID,
            name: "Học phí",
            iconName: "graduationcap.fill",
            colorHex: "#74B9FF",
            type: .expense,
            parentID: DefaultCategories.educationID,
            sortOrder: 0,
            isDefault: true
        ),
        AppCategory(
            id: education_sachID,
            name: "Sách",
            iconName: "books.vertical.fill",
            colorHex: "#74B9FF",
            type: .expense,
            parentID: DefaultCategories.educationID,
            sortOrder: 1,
            isDefault: true
        ),
        AppCategory(
            id: education_khoaHocID,
            name: "Khóa học",
            iconName: "laptopcomputer",
            colorHex: "#74B9FF",
            type: .expense,
            parentID: DefaultCategories.educationID,
            sortOrder: 2,
            isDefault: true
        ),
    ]

    /// Gia đình sub-categories stored under the "Cá nhân" parent.
    private static let personal: [AppCategory] = [
        AppCategory(
            id: personal_bieuBoMeID,
            name: "Biếu bố mẹ",
            iconName: "gift.fill",
            colorHex: "#A29BFE",
            type: .expense,
            parentID: DefaultCategories.personalID,
            sortOrder: 0,
            isDefault: true
        ),
        AppCategory(
            id: personal_conCaiID,
            name: "Con cái",
            iconName: "figure.2.and.child.holdinghands",
            colorHex: "#A29BFE",
            type: .expense,
            parentID: DefaultCategories.personalID,
            sortOrder: 1,
            isDefault: true
        ),
        AppCategory(
            id: personal_thuCungID,
            name: "Thú cưng",
            iconName: "pawprint.fill",
            colorHex: "#A29BFE",
            type: .expense,
            parentID: DefaultCategories.personalID,
            sortOrder: 2,
            isDefault: true
        ),
    ]

    /// Tài chính sub-categories stored under the "Hóa đơn & Tiện ích" parent.
    private static let bills: [AppCategory] = [
        AppCategory(
            id: bills_baoHiemID,
            name: "Bảo hiểm",
            iconName: "shield.fill",
            colorHex: "#FFEAA7",
            type: .expense,
            parentID: DefaultCategories.billsID,
            sortOrder: 0,
            isDefault: true
        ),
        AppCategory(
            id: bills_dauTuID,
            name: "Đầu tư",
            iconName: "chart.bar.fill",
            colorHex: "#FFEAA7",
            type: .expense,
            parentID: DefaultCategories.billsID,
            sortOrder: 1,
            isDefault: true
        ),
        AppCategory(
            id: bills_traNoDB,
            name: "Trả nợ",
            iconName: "creditcard.fill",
            colorHex: "#FFEAA7",
            type: .expense,
            parentID: DefaultCategories.billsID,
            sortOrder: 2,
            isDefault: true
        ),
        AppCategory(
            id: bills_phiNganHangID,
            name: "Phí ngân hàng",
            iconName: "building.columns.fill",
            colorHex: "#FFEAA7",
            type: .expense,
            parentID: DefaultCategories.billsID,
            sortOrder: 3,
            isDefault: true
        ),
    ]
}
