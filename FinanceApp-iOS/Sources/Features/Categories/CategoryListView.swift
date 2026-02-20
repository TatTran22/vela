import FinanceCore
import FinanceData
import FinanceUI
import SwiftData
import SwiftUI

/// Main view for displaying the hierarchical list of categories.
///
/// Shows categories grouped by expense or income type, organized in parent-child
/// sections. Supports search, swipe-to-delete/archive, and navigation to detail.
struct CategoryListView: View {
    @State private var viewModel: CategoryListViewModel
    @State private var showingAddCategory = false
    @State private var editingCategory: FinanceCategory?
    @Environment(\.modelContext) private var modelContext

    // MARK: - Initialization

    /// Creates a new category list view.
    ///
    /// - Parameter viewModel: The view model managing category data.
    ///   Use `ContentView`'s `makeCategoryListViewModel()` factory to construct this.
    init(viewModel: CategoryListViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.currentGroups.isEmpty {
                ProgressView()
                    .accessibilityLabel("Loading categories")
            } else if viewModel.currentGroups.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                categoriesList
            }
        }
        .navigationTitle(AppStrings.categoryListTitle)
        .searchable(text: $viewModel.searchText, prompt: "Search categories")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddCategory = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add category")
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            Task { await viewModel.loadCategories() }
        } content: {
            NavigationStack {
                CategoryEditView(viewModel: makeEditViewModel(for: nil))
            }
        }
        .sheet(item: $editingCategory, onDismiss: {
            Task { await viewModel.loadCategories() }
        }) { category in
            NavigationStack {
                CategoryEditView(viewModel: makeEditViewModel(for: category))
            }
        }
        .task {
            await viewModel.loadCategories()
        }
        .refreshable {
            await viewModel.loadCategories()
        }
        .alert(AppStrings.error, isPresented: $viewModel.showError) {
            Button(AppStrings.ok) {}
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView {
            Label(AppStrings.categoryListEmptyTitle, systemImage: "folder")
        } description: {
            Text(AppStrings.categoryListEmptySubtitle)
        } actions: {
            Button(AppStrings.categoryListEmptyAction) {
                showingAddCategory = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var categoriesList: some View {
        List {
            // Type picker pinned at the top
            Section {
                Picker(AppStrings.categoryEditType, selection: $viewModel.selectedType) {
                    Text(AppStrings.categoryExpense).tag(TransactionType.expense)
                    Text(AppStrings.categoryIncome).tag(TransactionType.income)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }

            // Category groups
            ForEach(viewModel.currentGroups) { group in
                Section {
                    // Children rows
                    ForEach(group.children) { child in
                        NavigationLink(value: child) {
                            categoryRow(child, isChild: true)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteCategory(child.id) }
                            } label: {
                                Label(AppStrings.delete, systemImage: "trash")
                            }

                            Button {
                                editingCategory = child
                            } label: {
                                Label(AppStrings.edit, systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                } header: {
                    parentHeader(group)
                }
            }
            .onMove { source, destination in
                viewModel.reorderCategories(from: source, to: destination)
            }
        }
        .navigationDestination(for: FinanceCategory.self) { category in
            CategoryDetailView(
                category: category,
                viewModel: makeListViewModelForDetail()
            )
        }
    }

    // MARK: - Row Builders

    private func parentHeader(_ group: CategoryGroup) -> some View {
        Button {
            editingCategory = group.parent
        } label: {
            HStack(spacing: 8) {
                CategoryIcon(
                    iconName: group.parent.iconName,
                    colorHex: group.parent.colorHex,
                    size: .small
                )
                Text(group.parent.localizedName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Spacer()
                if !group.children.isEmpty {
                    Text("\(group.children.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .clipShape(Capsule())
                }
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                Task { await viewModel.deleteCategory(group.parent.id) }
            } label: {
                Label(AppStrings.delete, systemImage: "trash")
            }
        }
        .accessibilityLabel("\(group.parent.localizedName), \(group.children.count) subcategories. Tap to edit.")
    }

    private func categoryRow(_ category: FinanceCategory, isChild: Bool) -> some View {
        HStack(spacing: 12) {
            CategoryIcon(
                iconName: category.iconName,
                colorHex: category.colorHex,
                size: isChild ? .small : .medium
            )
            Text(category.localizedName)
                .font(isChild ? .body : .headline)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Factory Methods

    private func makeEditViewModel(for category: FinanceCategory?) -> CategoryEditViewModel {
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

    private func makeListViewModelForDetail() -> CategoryListViewModel {
        let container = modelContext.container
        let repository = CategoryRepository(modelContainer: container)
        let getUseCase = GetCategoriesUseCase(repository: repository)
        let deleteUseCase = DeleteCategoryUseCase(repository: repository)
        let reorderUseCase = ReorderCategoriesUseCase(repository: repository)

        return CategoryListViewModel(
            getCategoriesUseCase: getUseCase,
            deleteCategoryUseCase: deleteUseCase,
            reorderCategoriesUseCase: reorderUseCase
        )
    }
}
