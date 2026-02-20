import FinanceCore
import Foundation
import Observation

// Disambiguate from Objective-C's `Category` type present in Foundation/Swift SDK.
typealias FinanceCategory = FinanceCore.Category

/// ViewModel for creating or editing a category.
///
/// Manages form fields, validation, and save logic for category creation and editing.
@Observable
@MainActor
final class CategoryEditViewModel {
    // MARK: - Form Fields

    /// The display name for the category.
    var name: String = ""

    /// The transaction type (expense or income).
    var type: TransactionType = .expense

    /// The optional parent category ID (nil means this is a top-level category).
    var parentID: UUID?

    /// The SF Symbol name used as the category icon.
    var iconName: String = "folder"

    /// The hex color string for the category icon background.
    var colorHex: String = "#007AFF"

    // MARK: - State

    /// Whether a save operation is in progress.
    var isSaving = false

    /// Field-level validation errors keyed by field name.
    var fieldErrors: [String: String] = [:]

    /// A general (non-field-specific) error message.
    var generalError: String?

    /// Whether to show a general error alert.
    var showError = false

    /// Whether the save completed successfully (used to trigger dismissal).
    var didSave = false

    /// Available parent categories for the parent picker (top-level only).
    var availableParents: [FinanceCategory] = []

    // MARK: - Edit Mode

    /// The category being edited, or nil when creating a new category.
    let editingCategory: FinanceCategory?

    /// Whether this view model represents an edit operation.
    let isEditing: Bool

    /// Whether this category has associated transactions, which locks the type picker.
    var hasTransactions = false

    // MARK: - Dependencies

    private let createCategoryUseCase: CreateCategoryUseCaseProtocol
    private let updateCategoryUseCase: UpdateCategoryUseCaseProtocol
    private let getCategoriesUseCase: GetCategoriesUseCaseProtocol

    // MARK: - Initialization

    /// Creates a new category edit view model.
    ///
    /// - Parameters:
    ///   - category: The category to edit. Pass nil to create a new category.
    ///   - createCategoryUseCase: Use case for creating categories.
    ///   - updateCategoryUseCase: Use case for updating categories.
    ///   - getCategoriesUseCase: Use case for fetching parent candidates.
    init(
        category: FinanceCategory? = nil,
        createCategoryUseCase: CreateCategoryUseCaseProtocol,
        updateCategoryUseCase: UpdateCategoryUseCaseProtocol,
        getCategoriesUseCase: GetCategoriesUseCaseProtocol
    ) {
        self.editingCategory = category
        self.isEditing = category != nil
        self.createCategoryUseCase = createCategoryUseCase
        self.updateCategoryUseCase = updateCategoryUseCase
        self.getCategoriesUseCase = getCategoriesUseCase

        if let category {
            self.name = category.name
            self.type = category.type
            self.parentID = category.parentID
            self.iconName = category.iconName
            self.colorHex = category.colorHex
        }
    }

    // MARK: - Computed Properties

    /// The navigation title for the form sheet.
    var title: String {
        isEditing ? AppStrings.categoryEditEditTitle : AppStrings.categoryEditNewTitle
    }

    // MARK: - Actions

    /// Loads the list of top-level categories eligible to be selected as parents.
    ///
    /// Excludes the category being edited to prevent circular references.
    func loadAvailableParents() async {
        do {
            let all = try await getCategoriesUseCase.execute(type: type, includeArchived: false)
            // Only top-level categories can be parents (parentID == nil)
            // Also exclude the category being edited itself
            availableParents = all.filter { category in
                category.parentID == nil &&
                category.id != editingCategory?.id
            }
        } catch {
            // Non-critical; parent picker simply shows no options
        }
    }

    /// Validates all form fields.
    ///
    /// - Returns: `true` if all fields are valid, `false` otherwise.
    func validate() -> Bool {
        fieldErrors.removeAll()

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            fieldErrors["name"] = "Category name is required"
        }

        return fieldErrors.isEmpty
    }

    /// Saves the category (creates a new one or updates the existing one).
    func save() async {
        guard validate() else { return }

        isSaving = true
        generalError = nil
        didSave = false

        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

            if isEditing, let existing = editingCategory {
                var updated = existing
                updated.name = trimmedName
                updated.localizedName = trimmedName
                updated.type = type
                updated.parentID = parentID
                updated.iconName = iconName
                updated.colorHex = colorHex

                _ = try await updateCategoryUseCase.execute(updated)
                didSave = true
            } else {
                let newCategory = FinanceCategory(
                    id: UUID(),
                    name: trimmedName,
                    localizedName: trimmedName,
                    iconName: iconName,
                    colorHex: colorHex,
                    type: type,
                    parentID: parentID,
                    sortOrder: 0,
                    isDefault: false,
                    isArchived: false,
                    createdAt: Date()
                )

                _ = try await createCategoryUseCase.execute(newCategory)
                didSave = true
            }
        } catch let categoryError as CategoryError {
            mapCategoryError(categoryError)
        } catch {
            generalError = error.localizedDescription
            showError = true
        }

        isSaving = false
    }

    // MARK: - Private Helpers

    /// Maps a CategoryError to field-level or general error messages.
    private func mapCategoryError(_ error: CategoryError) {
        switch error {
        case .nameEmpty:
            fieldErrors["name"] = "Category name is required"
        case .nameAlreadyExists(let name):
            fieldErrors["name"] = "A category named \"\(name)\" already exists"
        case .cannotChangeTypeWithTransactions:
            generalError = "Cannot change type for a category with existing transactions"
            showError = true
        default:
            generalError = error.localizedDescription
            showError = true
        }
    }
}
