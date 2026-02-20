import FinanceCore
import FinanceData
import FinanceUI
import SwiftData
import SwiftUI

/// Detail view for a single category.
///
/// Shows the category icon, name, type badge, and a list of its sub-categories.
/// Provides edit and delete actions via the toolbar and a destructive bottom button.
struct CategoryDetailView: View {
    /// The category being displayed.
    let category: FinanceCategory

    /// The list view model shared from the parent, used for deletion.
    @State private var listViewModel: CategoryListViewModel

    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    /// Creates a new category detail view.
    ///
    /// - Parameters:
    ///   - category: The category to display.
    ///   - viewModel: The list view model providing delete functionality.
    init(category: FinanceCategory, viewModel: CategoryListViewModel) {
        self.category = category
        self.listViewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        List {
            // Header section
            Section {
                HStack(spacing: 16) {
                    CategoryIcon(
                        iconName: category.iconName,
                        colorHex: category.colorHex,
                        size: .large
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.localizedName)
                            .font(.title2)
                            .fontWeight(.bold)
                        HStack(spacing: 6) {
                            typeBadge
                            if category.isDefault {
                                Text("System")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.quaternary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            // Sub-categories section
            if category.parentID == nil {
                subcategoriesSection
            }

            // Delete section
            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Text(category.isDefault ? AppStrings.archive : AppStrings.delete)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(category.localizedName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEdit = true
                } label: {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel(AppStrings.edit)
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                CategoryEditView(viewModel: makeEditViewModel())
            }
        }
        .confirmationDialog(
            category.isDefault ? "Archive Category" : "Delete Category",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(category.isDefault ? AppStrings.archive : AppStrings.delete, role: .destructive) {
                Task {
                    await listViewModel.deleteCategory(category.id)
                    dismiss()
                }
            }
            Button(AppStrings.cancel, role: .cancel) {}
        } message: {
            if category.isDefault {
                Text("This is a system category. It will be archived and hidden from the category picker.")
            } else {
                Text("This category will be permanently deleted. Transactions will not be affected.")
            }
        }
        .task {
            await listViewModel.loadCategories()
        }
        .alert(AppStrings.error, isPresented: $listViewModel.showError) {
            Button(AppStrings.ok) {}
        } message: {
            if let error = listViewModel.error {
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Subviews

    private var typeBadge: some View {
        Text(category.type == .expense ? AppStrings.categoryExpense : AppStrings.categoryIncome)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(category.type == .expense ? Color.red.opacity(0.12) : Color.green.opacity(0.12))
            .foregroundStyle(category.type == .expense ? Color.red : Color.green)
            .clipShape(Capsule())
    }

    private var subcategoriesSection: some View {
        Section(AppStrings.categoryDetailSubcategories) {
            let children = childrenForCategory()
            if children.isEmpty {
                Text("No sub-categories")
                    .foregroundStyle(.secondary)
                    .font(.body)
            } else {
                ForEach(children) { child in
                    HStack(spacing: 12) {
                        CategoryIcon(
                            iconName: child.iconName,
                            colorHex: child.colorHex,
                            size: .small
                        )
                        Text(child.localizedName)
                            .font(.body)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    // MARK: - Helpers

    /// Returns the children of the current category from the view model's loaded groups.
    private func childrenForCategory() -> [FinanceCategory] {
        let groups = category.type == .expense ? listViewModel.expenseGroups : listViewModel.incomeGroups
        return groups.first(where: { $0.parent.id == category.id })?.children ?? []
    }

    // MARK: - Factory Methods

    private func makeEditViewModel() -> CategoryEditViewModel {
        let container = modelContext.container
        let repository = CategoryRepository(modelContainer: container)
        let createUseCase = CreateCategoryUseCase(repository: repository)
        let updateUseCase = UpdateCategoryUseCase(repository: repository)
        let getUseCase = GetCategoriesUseCase(repository: repository)

        return CategoryEditViewModel(
            category: category,
            createCategoryUseCase: createUseCase,
            updateCategoryUseCase: updateUseCase,
            getCategoriesUseCase: getUseCase
        )
    }
}
