import FinanceCore
import Foundation
import Observation

/// ViewModel for the category list screen.
///
/// Manages loading, displaying, and organizing categories by type in a nested
/// parent-child hierarchy. Supports searching, deletion, and reordering.
@Observable
@MainActor
final class CategoryListViewModel {
    // MARK: - State

    /// Category groups for expense type, each containing a parent and its children.
    var expenseGroups: [CategoryGroup] = []

    /// Category groups for income type, each containing a parent and its children.
    var incomeGroups: [CategoryGroup] = []

    /// The currently selected transaction type tab.
    var selectedType: TransactionType = .expense

    /// Whether the view is currently loading data.
    var isLoading = false

    /// Current error, if any.
    var error: CategoryError?

    /// Whether to show an error alert.
    var showError = false

    /// The current search query entered by the user.
    var searchText = ""

    // MARK: - Dependencies

    private let getCategoriesUseCase: GetCategoriesUseCaseProtocol
    private let deleteCategoryUseCase: DeleteCategoryUseCaseProtocol
    private let reorderCategoriesUseCase: ReorderCategoriesUseCaseProtocol

    // MARK: - Initialization

    /// Creates a new category list view model.
    ///
    /// - Parameters:
    ///   - getCategoriesUseCase: Use case for fetching categories.
    ///   - deleteCategoryUseCase: Use case for deleting categories.
    ///   - reorderCategoriesUseCase: Use case for reordering categories.
    init(
        getCategoriesUseCase: GetCategoriesUseCaseProtocol,
        deleteCategoryUseCase: DeleteCategoryUseCaseProtocol,
        reorderCategoriesUseCase: ReorderCategoriesUseCaseProtocol
    ) {
        self.getCategoriesUseCase = getCategoriesUseCase
        self.deleteCategoryUseCase = deleteCategoryUseCase
        self.reorderCategoriesUseCase = reorderCategoriesUseCase
    }

    // MARK: - Computed Properties

    /// The category groups currently displayed, filtered by selected type and search text.
    var currentGroups: [CategoryGroup] {
        let groups = selectedType == .expense ? expenseGroups : incomeGroups
        guard !searchText.isEmpty else { return groups }
        return groups.filter { group in
            group.parent.localizedName.localizedCaseInsensitiveContains(searchText) ||
            group.children.contains { $0.localizedName.localizedCaseInsensitiveContains(searchText) }
        }
    }

    // MARK: - Actions

    /// Loads both expense and income categories from the repository as nested groups.
    func loadCategories() async {
        isLoading = true
        error = nil

        do {
            async let expenseTask = getCategoriesUseCase.executeNested(type: .expense, includeArchived: false)
            async let incomeTask = getCategoriesUseCase.executeNested(type: .income, includeArchived: false)
            expenseGroups = try await expenseTask
            incomeGroups = try await incomeTask
        } catch let categoryError as CategoryError {
            error = categoryError
            showError = true
        } catch {
            self.error = .categoryNotFound(UUID())
            showError = true
        }

        isLoading = false
    }

    /// Deletes a category by its ID, then reloads the list.
    ///
    /// - Parameter id: The unique identifier of the category to delete.
    func deleteCategory(_ id: UUID) async {
        do {
            try await deleteCategoryUseCase.execute(id: id)
            await loadCategories()
        } catch let categoryError as CategoryError {
            error = categoryError
            showError = true
        } catch {
            self.error = .categoryNotFound(id)
            showError = true
        }
    }

    /// Reorders the top-level categories within the current type by moving items at the
    /// source offsets to the destination position.
    ///
    /// The reordering is applied optimistically to the in-memory groups and then
    /// persisted asynchronously.
    ///
    /// - Parameters:
    ///   - source: Source indices to move.
    ///   - destination: Destination index.
    func reorderCategories(from source: IndexSet, to destination: Int) {
        var groups = selectedType == .expense ? expenseGroups : incomeGroups
        groups.move(fromOffsets: source, toOffset: destination)

        if selectedType == .expense {
            expenseGroups = groups
        } else {
            incomeGroups = groups
        }

        let orderedIDs = groups.map { $0.parent.id }
        Task {
            do {
                try await reorderCategoriesUseCase.execute(orderedIDs: orderedIDs, startingAt: 0)
            } catch let categoryError as CategoryError {
                error = categoryError
                showError = true
            } catch {
                // Silent failure for reorder operations
            }
        }
    }
}
