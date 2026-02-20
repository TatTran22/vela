import FinanceCore
import FinanceData
import FinanceUI
import SwiftData
import SwiftUI

// Avoid conflict with the Objective-C `Category` type in Foundation.
typealias FinanceCategory = FinanceCore.Category

/// Main category management view for macOS.
///
/// Displays a two-pane layout: a sidebar listing all categories grouped by type
/// (Expense / Income) with parent–child hierarchy, and a detail pane for the
/// currently selected category. All data mutations are driven by use-case
/// instances created from the supplied `ModelContainer`.
struct MacCategoryManagementView: View {

    // MARK: - State

    @State private var viewModel: MacCategoryManagementViewModel
    @State private var selectedCategoryID: UUID?
    @State private var showingNewCategory = false
    @State private var categoryToEdit: FinanceCategory?
    /// When set, presents the "add sub-category" sheet with this parent pre-selected.
    @State private var parentForNewSubcategory: FinanceCategory?
    @State private var searchText = ""

    // MARK: - Init

    /// Creates the view from a SwiftData `ModelContainer`.
    ///
    /// - Parameter modelContainer: The SwiftData container used to initialise
    ///   the view model and all underlying repositories.
    init(modelContainer: ModelContainer) {
        _viewModel = State(
            initialValue: MacCategoryManagementViewModel(modelContainer: modelContainer)
        )
    }

    // MARK: - Computed helpers

    private var selectedCategory: FinanceCategory? {
        guard let id = selectedCategoryID else { return nil }
        return viewModel.allCategories.first { $0.id == id }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.allCategories.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.allCategories.isEmpty {
                ContentUnavailableView {
                    Label(AppStrings.categoryEmptyTitle, systemImage: "folder")
                } description: {
                    Text(AppStrings.categoryEmptySubtitle)
                } actions: {
                    Button(AppStrings.categoryNew) {
                        categoryToEdit = nil
                        parentForNewSubcategory = nil
                        showingNewCategory = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                HSplitView {
                    categoryListPane
                    detailPane
                }
            }
        }
        .navigationTitle(AppStrings.navCategories)
        .task { await viewModel.loadCategories() }
        .toolbar {
            ToolbarItem {
                Button {
                    categoryToEdit = nil
                    parentForNewSubcategory = nil
                    showingNewCategory = true
                } label: {
                    Label(AppStrings.categoryNew, systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingNewCategory) {
            NavigationStack {
                MacCategoryEditView(
                    category: categoryToEdit,
                    defaultParent: parentForNewSubcategory,
                    allCategories: viewModel.parentCandidates(excluding: categoryToEdit),
                    createCategoryUseCase: viewModel.createUseCase,
                    updateCategoryUseCase: viewModel.updateUseCase,
                    onSave: { savedID in
                        categoryToEdit = nil
                        parentForNewSubcategory = nil
                        selectedCategoryID = savedID
                        Task { await viewModel.loadCategories() }
                    }
                )
            }
        }
        .onChange(of: showingNewCategory) { _, isShowing in
            if !isShowing {
                categoryToEdit = nil
                parentForNewSubcategory = nil
            }
        }
        .onChange(of: viewModel.allCategories) { _, newCategories in
            if let id = selectedCategoryID,
               !newCategories.contains(where: { $0.id == id }) {
                selectedCategoryID = nil
            }
        }
        .alert(AppStrings.error, isPresented: $viewModel.showError) {
            Button(AppStrings.ok) { viewModel.showError = false }
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
    }

    // MARK: - Sidebar list pane

    private var categoryListPane: some View {
        List(selection: $selectedCategoryID) {
            // Expense section
            let expenseGroups = viewModel.expenseGroups(matching: searchText)
            if !expenseGroups.isEmpty {
                Section(AppStrings.categoryExpense) {
                    ForEach(expenseGroups) { group in
                        categoryRow(for: group.parent, isChild: false)
                            .contextMenu { contextMenu(for: group.parent) }
                        ForEach(group.children) { child in
                            categoryRow(for: child, isChild: true)
                                .contextMenu { contextMenu(for: child) }
                        }
                    }
                }
            }

            // Income section
            let incomeGroups = viewModel.incomeGroups(matching: searchText)
            if !incomeGroups.isEmpty {
                Section(AppStrings.categoryIncome) {
                    ForEach(incomeGroups) { group in
                        categoryRow(for: group.parent, isChild: false)
                            .contextMenu { contextMenu(for: group.parent) }
                        ForEach(group.children) { child in
                            categoryRow(for: child, isChild: true)
                                .contextMenu { contextMenu(for: child) }
                        }
                    }
                }
            }
        }
        .frame(minWidth: 240)
        .searchable(text: $searchText, prompt: AppStrings.categoryListTitle)
    }

    // MARK: - Sidebar row

    @ViewBuilder
    private func categoryRow(for category: FinanceCategory, isChild: Bool) -> some View {
        HStack(spacing: 8) {
            if isChild {
                Spacer()
                    .frame(width: 20)
            }
            CategoryIcon(iconName: category.iconName, colorHex: category.colorHex, size: .small)
            VStack(alignment: .leading, spacing: 1) {
                Text(category.localizedName)
                    .font(.body)
                if category.isArchived {
                    Text("Archived")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .tag(category.id)
        .opacity(category.isArchived ? 0.5 : 1.0)
    }

    // MARK: - Context menu

    @ViewBuilder
    private func contextMenu(for category: FinanceCategory) -> some View {
        Button(AppStrings.categoryEdit) {
            categoryToEdit = category
            parentForNewSubcategory = nil
            showingNewCategory = true
        }

        if category.parentID == nil {
            Button(AppStrings.categoryAddSubcategory) {
                categoryToEdit = nil
                parentForNewSubcategory = category
                showingNewCategory = true
            }
        }

        Divider()

        Button(AppStrings.categoryArchive) {
            Task { await viewModel.toggleArchive(category) }
        }

        Divider()

        Button(AppStrings.categoryDelete, role: .destructive) {
            Task {
                let deleted = await viewModel.deleteCategory(category.id)
                if deleted, selectedCategoryID == category.id {
                    selectedCategoryID = nil
                }
            }
        }
    }

    // MARK: - Detail pane

    @ViewBuilder
    private var detailPane: some View {
        if let category = selectedCategory {
            MacCategoryDetailView(
                category: category,
                subcategories: viewModel.children(of: category.id),
                onEdit: {
                    categoryToEdit = category
                    parentForNewSubcategory = nil
                    showingNewCategory = true
                },
                onAddSubcategory: {
                    categoryToEdit = nil
                    parentForNewSubcategory = category
                    showingNewCategory = true
                },
                onArchive: {
                    Task { await viewModel.toggleArchive(category) }
                },
                onDelete: {
                    Task {
                        let deleted = await viewModel.deleteCategory(category.id)
                        if deleted { selectedCategoryID = nil }
                    }
                }
            )
        } else {
            ContentUnavailableView(AppStrings.categoryListTitle, systemImage: "folder")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Detail sub-view

/// Detail pane showing information for a selected category.
private struct MacCategoryDetailView: View {
    let category: FinanceCategory
    let subcategories: [FinanceCategory]
    let onEdit: () -> Void
    let onAddSubcategory: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    CategoryIcon(iconName: category.iconName, colorHex: category.colorHex, size: .large)
                    Text(category.localizedName)
                        .font(.title2.bold())
                    Text(category.type == .expense
                         ? AppStrings.categoryExpense
                         : AppStrings.categoryIncome)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if category.isArchived {
                        Text("Archived")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 3, y: 1)

                // Subcategories section (only for parent categories)
                if category.parentID == nil {
                    GroupBox(AppStrings.categorySubcategories) {
                        if subcategories.isEmpty {
                            Text("No sub-categories")
                                .foregroundStyle(.secondary)
                                .font(.callout)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                        } else {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(subcategories) { child in
                                    HStack(spacing: 10) {
                                        CategoryIcon(iconName: child.iconName, colorHex: child.colorHex, size: .small)
                                        Text(child.localizedName)
                                            .font(.body)
                                        Spacer()
                                        if child.isArchived {
                                            Text("Archived")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .opacity(child.isArchived ? 0.5 : 1.0)
                                    .padding(.vertical, 8)

                                    if child.id != subcategories.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                }

                // Action buttons
                VStack(spacing: 8) {
                    Button(AppStrings.categoryEdit) { onEdit() }
                        .buttonStyle(.bordered)
                        .keyboardShortcut("e", modifiers: .command)
                        .frame(maxWidth: .infinity)

                    if category.parentID == nil {
                        Button(AppStrings.categoryAddSubcategory) { onAddSubcategory() }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                    }

                    Button(AppStrings.categoryArchive) { onArchive() }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)

                    Button(AppStrings.categoryDelete, role: .destructive) { onDelete() }
                        .buttonStyle(.bordered)
                        .keyboardShortcut(.delete, modifiers: .command)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .navigationTitle(category.localizedName)
        .toolbar {
            ToolbarItemGroup {
                Button { onEdit() } label: {
                    Label(AppStrings.categoryEdit, systemImage: "pencil")
                }
                .keyboardShortcut("e", modifiers: .command)

                Button(role: .destructive) { onDelete() } label: {
                    Label(AppStrings.categoryDelete, systemImage: "trash")
                }
                .keyboardShortcut(.delete, modifiers: .command)
            }
        }
    }
}

// MARK: - ViewModel

/// ViewModel for `MacCategoryManagementView`.
///
/// Owns all use-case instances and provides grouped data to the view.
@Observable
@MainActor
final class MacCategoryManagementViewModel {

    // MARK: - Published state

    var allCategories: [FinanceCategory] = []
    var expenseGroupsAll: [CategoryGroup] = []
    var incomeGroupsAll: [CategoryGroup] = []
    var isLoading = false
    var errorMessage: String?
    var showError = false

    // MARK: - Use-case instances (stored to avoid actor re-creation)

    private let getCategoriesUseCase: GetCategoriesUseCaseProtocol
    private let createCategoryUseCase: CreateCategoryUseCaseProtocol
    private let updateCategoryUseCase: UpdateCategoryUseCaseProtocol
    private let deleteCategoryUseCase: DeleteCategoryUseCaseProtocol

    // MARK: - Init

    init(modelContainer: ModelContainer) {
        let repository = CategoryRepository(modelContainer: modelContainer)
        self.getCategoriesUseCase = GetCategoriesUseCase(repository: repository)
        self.createCategoryUseCase = CreateCategoryUseCase(repository: repository)
        self.updateCategoryUseCase = UpdateCategoryUseCase(repository: repository)
        self.deleteCategoryUseCase = DeleteCategoryUseCase(repository: repository)
    }

    // MARK: - Data loading

    func loadCategories() async {
        isLoading = true
        errorMessage = nil

        do {
            allCategories = try await getCategoriesUseCase.execute(type: nil, includeArchived: true)
            expenseGroupsAll = try await getCategoriesUseCase.executeNested(type: .expense, includeArchived: true)
            incomeGroupsAll = try await getCategoriesUseCase.executeNested(type: .income, includeArchived: true)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    // MARK: - Filtered groups

    func expenseGroups(matching search: String) -> [CategoryGroup] {
        filtered(groups: expenseGroupsAll, search: search)
    }

    func incomeGroups(matching search: String) -> [CategoryGroup] {
        filtered(groups: incomeGroupsAll, search: search)
    }

    private func filtered(groups: [CategoryGroup], search: String) -> [CategoryGroup] {
        guard !search.isEmpty else { return groups }
        let query = search.lowercased()
        return groups.compactMap { group in
            let parentMatches = group.parent.localizedName.lowercased().contains(query)
                || group.parent.name.lowercased().contains(query)
            let matchingChildren = group.children.filter {
                $0.localizedName.lowercased().contains(query)
                || $0.name.lowercased().contains(query)
            }
            if parentMatches || !matchingChildren.isEmpty {
                return CategoryGroup(parent: group.parent, children: matchingChildren)
            }
            return nil
        }
    }

    // MARK: - Children lookup

    func children(of parentID: UUID) -> [FinanceCategory] {
        allCategories.filter { $0.parentID == parentID }
    }

    // MARK: - Parent candidates for edit sheet

    func parentCandidates(excluding editedCategory: FinanceCategory?) -> [FinanceCategory] {
        allCategories.filter { candidate in
            // Only top-level categories can be parents
            guard candidate.parentID == nil else { return false }
            // Exclude the category being edited (cannot be its own parent)
            if let edited = editedCategory, candidate.id == edited.id { return false }
            return true
        }
    }

    // MARK: - Mutations

    @discardableResult
    func deleteCategory(_ id: UUID) async -> Bool {
        errorMessage = nil
        do {
            try await deleteCategoryUseCase.execute(id: id)
            await loadCategories()
            return true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }

    func toggleArchive(_ category: FinanceCategory) async {
        var updated = category
        updated.isArchived.toggle()
        do {
            _ = try await updateCategoryUseCase.execute(updated)
            await loadCategories()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Accessors for the edit sheet

    var createUseCase: CreateCategoryUseCaseProtocol { createCategoryUseCase }
    var updateUseCase: UpdateCategoryUseCaseProtocol { updateCategoryUseCase }
}
