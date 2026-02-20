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
        // Expense
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
        // Income
        DefaultCategories.salaryID: "category.salary",
        DefaultCategories.bonusID: "category.bonus",
        DefaultCategories.investmentID: "category.investment",
        DefaultCategories.businessID: "category.business",
        DefaultCategories.otherIncomeID: "category.otherIncome",
        // Transfer
        DefaultCategories.transferID: "category.transfer",
    ]
}
