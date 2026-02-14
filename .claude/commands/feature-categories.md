---
description: "Triển khai feature Categories — F1.6 Hệ thống danh mục 2 cấp với defaults tiếng Việt"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: Categories

## Feature Spec References
- F1.6: Hệ thống danh mục (Category → Sub-category)

## Đọc Context Trước
1. `CLAUDE.md`
2. `FinanceApp-Feature-Specification.md` → F1.6
3. `docs/DATA-MODEL.md`
4. `docs/DESIGN-SYSTEM.md`

## Tasks

### FinanceCore
1. `CategoryType` enum: income, expense
2. `Category` model:
   - id: UUID, name: String, localizedName: String
   - type: CategoryType, parent: Category? (for sub-categories)
   - icon: String (SF Symbol name), color: String (hex)
   - sortOrder: Int, isDefault: Bool, isArchived: Bool
3. `SubCategory` — child of Category, same structure
4. Default expense categories (Vietnamese):
   - Ăn uống (Cơm, Café/Trà sữa, Ăn vặt, Nhậu)
   - Nhà ở (Tiền nhà, Điện, Nước, Internet, Gas)
   - Di chuyển (Xăng, Grab/Taxi, Gửi xe, Bảo dưỡng xe)
   - Mua sắm (Quần áo, Đồ gia dụng, Điện tử)
   - Giải trí (Phim, Game, Du lịch, Thể thao)
   - Sức khỏe (Thuốc, Khám bệnh, Gym)
   - Giáo dục (Học phí, Sách, Khóa học)
   - Gia đình (Biếu bố mẹ, Con cái, Thú cưng)
   - Tài chính (Bảo hiểm, Đầu tư, Trả nợ, Phí ngân hàng)
   - Khác
5. Default income categories (Vietnamese):
   - Lương, Thưởng, Freelance, Đầu tư, Cho thuê
   - Quà/Biếu, Hoàn tiền, Khác
6. `CreateCategoryUseCase`:
   - Validate: name not empty, unique within type+parent
   - Assign next sortOrder
7. `UpdateCategoryUseCase`:
   - Cannot change type if transactions exist
8. `DeleteCategoryUseCase`:
   - Cannot delete if transactions exist → prompt reassign
   - Soft delete default categories
9. `GetCategoriesUseCase`:
   - Grouped by type (income/expense)
   - Include sub-categories nested
   - Sorted by sortOrder
10. `ReorderCategoriesUseCase`:
    - Update sortOrder for batch of categories
11. `SeedDefaultCategoriesUseCase`:
    - Called on first launch / onboarding
    - Locale-aware: vi → Vietnamese names, en → English names

### FinanceData
12. `CategoryEntity` @Model
    - Indexes: (type), (parent), (type, sortOrder)
    - Relationship: parent ↔ children (one-to-many)
    - Relationship: transactions (one-to-many)
13. `CategoryRepositoryImpl`:
    - fetchByType(_ type: CategoryType) → [Category]
    - fetchWithTransactionCount() → [(Category, Int)]
    - seedDefaults(locale: Locale)
    - reorder(_ categories: [UUID], sortOrders: [Int])

### FinanceUI
14. `CategoryIcon` — SF Symbol with colored background circle
15. `CategoryPicker`:
    - Grid layout (3 columns), top 6 recent + "Xem tất cả"
    - Segmented: Income / Expense
    - Search bar
16. `CategoryBadge` — compact icon + name for inline display

### iOS
17. `CategoryListView`:
    - Grouped by type (Income / Expense sections)
    - Each category shows icon + name + transaction count
    - Tap → sub-categories list
    - Swipe-to-edit, swipe-to-archive
    - Drag-to-reorder
18. `CategoryEditView`:
    - Name input (+ localized name)
    - Type picker (income/expense) — locked if has transactions
    - Parent category picker (optional, for sub-category)
    - Icon picker (SF Symbols grid, searchable)
    - Color picker (preset palette + custom)
    - Preview card
19. `CategoryDetailView`:
    - Category info + total spent/earned
    - Transaction list filtered by this category
    - Sub-categories breakdown

### macOS
20. List/Detail layout in NavigationSplitView sidebar
21. Inline editing (double-click name to rename)
22. Right-click context menu (Edit, Archive, Delete, Add Sub-category)

### Tests
23. CreateCategory — validation, duplicate check, sortOrder assignment
24. DeleteCategory — block if has transactions, soft delete defaults
25. SeedDefaults — correct count, Vietnamese names, English fallback
26. Reorder — sortOrder updates correctly
27. SubCategory — parent-child relationship, cascade archive
28. CategoryPicker — filter by type, recent categories
