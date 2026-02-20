import Foundation

/// Provides localized display names for default categories.
///
/// The seed data in `DefaultCategories` stores Vietnamese names as stable keys.
/// This helper maps known default category IDs to localized strings from the
/// FinanceData module's String Catalog, allowing the UI to display the correct
/// name based on the user's locale.
public enum DefaultCategoryNames {
    /// Returns the localized display name for a known default category.
    ///
    /// - Parameter categoryID: The UUID of the category.
    /// - Returns: The localized name if the ID matches a known default category, otherwise `nil`.
    public static func localizedName(for categoryID: UUID) -> String? {
        guard let key = idToKey[categoryID] else { return nil }
        return String(localized: String.LocalizationValue(key), bundle: .module)
    }

    private static let idToKey: [UUID: String] = [
        // Expense — top-level
        DefaultCategories.eatDrinkID: "category.eatDrink",
        DefaultCategories.transportID: "category.transport",
        DefaultCategories.shoppingID: "category.shopping",
        DefaultCategories.housingID: "category.housing",
        DefaultCategories.billsID: "category.bills",
        DefaultCategories.entertainmentID: "category.entertainment",
        DefaultCategories.healthID: "category.health",
        DefaultCategories.educationID: "category.education",
        DefaultCategories.personalID: "category.personal",
        DefaultCategories.otherExpenseID: "category.otherExpense",
        // Income — top-level
        DefaultCategories.salaryID: "category.salary",
        DefaultCategories.bonusID: "category.bonus",
        DefaultCategories.investmentID: "category.investment",
        DefaultCategories.businessID: "category.business",
        DefaultCategories.otherIncomeID: "category.otherIncome",
        // Transfer — top-level
        DefaultCategories.transferID: "category.transfer",
        // Ăn uống sub-categories
        DefaultSubCategories.eatDrink_comID: "subcategory.eatDrink.com",
        DefaultSubCategories.eatDrink_cafeID: "subcategory.eatDrink.cafe",
        DefaultSubCategories.eatDrink_anVatID: "subcategory.eatDrink.anVat",
        DefaultSubCategories.eatDrink_nhauID: "subcategory.eatDrink.nhau",
        // Nhà ở sub-categories
        DefaultSubCategories.housing_tienNhaID: "subcategory.housing.tienNha",
        DefaultSubCategories.housing_dienID: "subcategory.housing.dien",
        DefaultSubCategories.housing_nuocID: "subcategory.housing.nuoc",
        DefaultSubCategories.housing_internetID: "subcategory.housing.internet",
        DefaultSubCategories.housing_gasID: "subcategory.housing.gas",
        // Di chuyển sub-categories
        DefaultSubCategories.transport_xangID: "subcategory.transport.xang",
        DefaultSubCategories.transport_grabID: "subcategory.transport.grab",
        DefaultSubCategories.transport_guiXeID: "subcategory.transport.guiXe",
        DefaultSubCategories.transport_baoDuongID: "subcategory.transport.baoDuong",
        // Mua sắm sub-categories
        DefaultSubCategories.shopping_quanAoID: "subcategory.shopping.quanAo",
        DefaultSubCategories.shopping_doGiaDungID: "subcategory.shopping.doGiaDung",
        DefaultSubCategories.shopping_dienTuID: "subcategory.shopping.dienTu",
        // Giải trí sub-categories
        DefaultSubCategories.entertainment_phimID: "subcategory.entertainment.phim",
        DefaultSubCategories.entertainment_gameID: "subcategory.entertainment.game",
        DefaultSubCategories.entertainment_duLichID: "subcategory.entertainment.duLich",
        DefaultSubCategories.entertainment_theThaoID: "subcategory.entertainment.theThao",
        // Sức khỏe sub-categories
        DefaultSubCategories.health_thuocID: "subcategory.health.thuoc",
        DefaultSubCategories.health_khamBenhID: "subcategory.health.khamBenh",
        DefaultSubCategories.health_gymID: "subcategory.health.gym",
        // Giáo dục sub-categories
        DefaultSubCategories.education_hocPhiID: "subcategory.education.hocPhi",
        DefaultSubCategories.education_sachID: "subcategory.education.sach",
        DefaultSubCategories.education_khoaHocID: "subcategory.education.khoaHoc",
        // Gia đình sub-categories (under personalID)
        DefaultSubCategories.personal_bieuBoMeID: "subcategory.personal.bieuBoMe",
        DefaultSubCategories.personal_conCaiID: "subcategory.personal.conCai",
        DefaultSubCategories.personal_thuCungID: "subcategory.personal.thuCung",
        // Tài chính sub-categories (under billsID)
        DefaultSubCategories.bills_baoHiemID: "subcategory.bills.baoHiem",
        DefaultSubCategories.bills_dauTuID: "subcategory.bills.dauTu",
        DefaultSubCategories.bills_traNoDB: "subcategory.bills.traNos",
        DefaultSubCategories.bills_phiNganHangID: "subcategory.bills.phiNganHang",
    ]
}
