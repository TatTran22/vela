import FinanceCore
import FinanceData
import FinanceUI
import SwiftUI

// Avoid conflict with the Objective-C `Category` type in Foundation.
private typealias FinanceCategory = FinanceCore.Category

/// macOS sheet for creating or editing a category.
///
/// Presents a grouped form with name, type, parent, icon, and color fields,
/// plus a live preview showing the result. Supports both creation (when
/// `category` is nil) and editing (when `category` is set) modes.
struct MacCategoryEditView: View {

    // MARK: - Form state

    @State private var name: String
    @State private var type: TransactionType
    @State private var parentID: UUID?
    @State private var iconName: String
    @State private var colorHex: String
    @State private var isSaving = false
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false

    /// Field-level validation errors, keyed by field name.
    @State private var fieldErrors: [String: String] = [:]

    /// General error message (non-field-specific).
    @State private var errorMessage: String?

    // MARK: - Dependencies

    /// The category being edited, or nil for creation mode.
    let editingCategory: FinanceCategory?

    /// The parent category to pre-select when adding a sub-category.
    let defaultParent: FinanceCategory?

    /// Available top-level categories eligible to be selected as parent.
    let allCategories: [FinanceCategory]

    let createCategoryUseCase: CreateCategoryUseCaseProtocol
    let updateCategoryUseCase: UpdateCategoryUseCaseProtocol

    /// Callback invoked after a successful save, supplying the saved category's ID.
    let onSave: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss

    var isEditing: Bool { editingCategory != nil }

    // MARK: - Init

    init(
        category: FinanceCategory? = nil,
        defaultParent: FinanceCategory? = nil,
        allCategories: [FinanceCategory],
        createCategoryUseCase: CreateCategoryUseCaseProtocol,
        updateCategoryUseCase: UpdateCategoryUseCaseProtocol,
        onSave: @escaping (UUID) -> Void
    ) {
        self.editingCategory = category
        self.defaultParent = defaultParent
        self.allCategories = allCategories
        self.createCategoryUseCase = createCategoryUseCase
        self.updateCategoryUseCase = updateCategoryUseCase
        self.onSave = onSave

        if let category {
            _name = State(initialValue: category.name)
            _type = State(initialValue: category.type)
            _parentID = State(initialValue: category.parentID)
            _iconName = State(initialValue: category.iconName)
            _colorHex = State(initialValue: category.colorHex)
        } else {
            _name = State(initialValue: "")
            _type = State(initialValue: .expense)
            _parentID = State(initialValue: defaultParent?.id)
            _iconName = State(initialValue: "folder")
            _colorHex = State(initialValue: "#007AFF")
        }
    }

    // MARK: - Body

    var body: some View {
        Form {
            // MARK: General
            Section(AppStrings.editGeneral) {
                VStack(alignment: .leading, spacing: 4) {
                    TextField(AppStrings.categoryEditName, text: $name)
                        .onChange(of: name) { _, _ in fieldErrors.removeValue(forKey: "name") }
                    if let error = fieldErrors["name"] {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                // Type picker — only available when creating; blocked in edit mode
                // when transactions exist (enforced by the use case).
                Picker(AppStrings.categoryEditType, selection: $type) {
                    Text(AppStrings.categoryExpense).tag(TransactionType.expense)
                    Text(AppStrings.categoryIncome).tag(TransactionType.income)
                }
                .pickerStyle(.segmented)
                .disabled(isEditing)

                // Parent picker
                Picker(AppStrings.categoryEditParent, selection: $parentID) {
                    Text(AppStrings.categoryNoParent).tag(UUID?.none)
                    ForEach(eligibleParents) { parent in
                        Label(parent.localizedName, systemImage: parent.iconName)
                            .tag(Optional(parent.id))
                    }
                }
            }

            // MARK: Appearance
            Section(AppStrings.editAppearance) {
                // Icon row
                HStack {
                    Text(AppStrings.categoryEditIcon)
                    Spacer()
                    Button {
                        showingIconPicker = true
                    } label: {
                        Image(systemName: iconName)
                            .font(.title3)
                            .foregroundStyle(Color(hex: colorHex))
                            .frame(width: 32, height: 32)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingIconPicker) {
                        IconPicker(selectedIcon: $iconName)
                            .frame(width: 360, height: 400)
                    }
                }

                // Color row
                HStack {
                    Text(AppStrings.categoryEditColor)
                    Spacer()
                    Button {
                        showingColorPicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 20, height: 20)
                            Text(colorHex)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingColorPicker) {
                        VStack(spacing: 16) {
                            Text(AppStrings.editChooseColor)
                                .font(.headline)
                            ColorPickerGrid(selectedColorHex: $colorHex) { _ in
                                showingColorPicker = false
                            }
                        }
                        .padding(20)
                        .frame(width: 280)
                    }
                }
            }

            // MARK: Preview
            Section(AppStrings.categoryEditPreview) {
                HStack(spacing: 12) {
                    CategoryIcon(iconName: iconName, colorHex: colorHex, size: .large)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name.isEmpty ? "Category Name" : name)
                            .font(.headline)
                        Text(type == .expense ? AppStrings.categoryExpense : AppStrings.categoryIncome)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }

            // MARK: General error
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(isEditing ? AppStrings.categoryEdit : AppStrings.categoryNew)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(AppStrings.cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(AppStrings.save) {
                    Task { await save() }
                }
                .disabled(isSaving)
                .keyboardShortcut("s", modifiers: .command)
            }
        }
        .frame(minWidth: 420, minHeight: 460)
    }

    // MARK: - Helpers

    /// Top-level categories eligible to be selected as the parent of the new/edited category.
    private var eligibleParents: [FinanceCategory] {
        allCategories.filter { $0.type == type && $0.parentID == nil }
    }

    // MARK: - Validation

    /// Validates form fields, populates `fieldErrors`. Returns true when valid.
    private func validate() -> Bool {
        fieldErrors.removeAll()

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            fieldErrors["name"] = AppStrings.editNameRequired
        }

        return fieldErrors.isEmpty
    }

    // MARK: - Save

    private func save() async {
        guard validate() else { return }

        isSaving = true
        errorMessage = nil

        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let savedCategory: FinanceCategory

            if let existing = editingCategory {
                var updated = existing
                updated.name = trimmedName
                updated.localizedName = trimmedName
                updated.type = type
                updated.parentID = parentID
                updated.iconName = iconName
                updated.colorHex = colorHex
                savedCategory = try await updateCategoryUseCase.execute(updated)
            } else {
                let newCategory = FinanceCategory(
                    name: trimmedName,
                    localizedName: trimmedName,
                    iconName: iconName,
                    colorHex: colorHex,
                    type: type,
                    parentID: parentID
                )
                savedCategory = try await createCategoryUseCase.execute(newCategory)
            }

            onSave(savedCategory.id)
            dismiss()
        } catch let error as CategoryError {
            mapCategoryError(error)
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    /// Maps `CategoryError` to field-level or general error messages.
    private func mapCategoryError(_ error: CategoryError) {
        switch error {
        case .nameEmpty:
            fieldErrors["name"] = AppStrings.editNameRequired
        case .nameAlreadyExists(let existing):
            fieldErrors["name"] = "A category named \"\(existing)\" already exists."
        default:
            errorMessage = error.localizedDescription
        }
    }
}
