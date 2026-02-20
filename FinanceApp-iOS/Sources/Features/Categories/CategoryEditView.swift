import FinanceCore
import FinanceUI
import SwiftUI

/// View for creating or editing a category.
///
/// Provides a form interface for entering category name, type, parent,
/// icon, and color. Shows a live preview card at the bottom.
struct CategoryEditView: View {
    @State private var viewModel: CategoryEditViewModel
    @State private var showingIconPicker = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Static Data

    private static let commonIcons = [
        "fork.knife", "car.fill", "bag.fill", "house.fill", "doc.text.fill",
        "gamecontroller.fill", "heart.fill", "book.fill", "person.fill",
        "banknote.fill", "gift.fill", "chart.line.uptrend.xyaxis", "briefcase.fill",
        "creditcard.fill", "airplane", "pawprint.fill", "graduationcap.fill",
        "cup.and.saucer.fill", "tshirt.fill", "dumbbell.fill", "stethoscope",
        "wrench.fill", "paintbrush.fill", "music.note", "film.fill",
        "globe", "star.fill", "bolt.fill", "leaf.fill", "flame.fill",
        "drop.fill", "pills.fill", "cart.fill"
    ]

    private static let colorPalette = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD",
        "#74B9FF", "#A29BFE", "#00B894", "#FDCB6E", "#6C5CE7", "#0984E3",
        "#636E72", "#FF7675", "#FD79A8", "#E17055"
    ]

    // MARK: - Initialization

    /// Creates a new category edit view.
    ///
    /// - Parameter viewModel: The view model managing form state and save logic.
    init(viewModel: CategoryEditViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        Form {
            nameSection
            typeSection
            parentSection
            appearanceSection
            previewSection
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(AppStrings.cancel) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Button(AppStrings.save) {
                        Task {
                            await viewModel.save()
                            if viewModel.didSave {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
        }
        .task {
            await viewModel.loadAvailableParents()
        }
        .onChange(of: viewModel.type) {
            Task { await viewModel.loadAvailableParents() }
            // Reset parent when type changes to avoid stale cross-type parentID
            viewModel.parentID = nil
        }
        .alert(AppStrings.error, isPresented: $viewModel.showError) {
            Button(AppStrings.ok) {}
        } message: {
            if let error = viewModel.generalError {
                Text(error)
            }
        }
        .sheet(isPresented: $showingIconPicker) {
            NavigationStack {
                iconPickerSheet
            }
        }
    }

    // MARK: - Form Sections

    private var nameSection: some View {
        Section(AppStrings.categoryEditName) {
            VStack(alignment: .leading, spacing: 4) {
                TextField(
                    AppStrings.categoryEditName,
                    text: $viewModel.name,
                    prompt: Text("e.g. Food & Dining")
                )
                .onChange(of: viewModel.name) { _, _ in
                    viewModel.fieldErrors.removeValue(forKey: "name")
                }
                if let nameError = viewModel.fieldErrors["name"] {
                    Text(nameError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var typeSection: some View {
        Section(AppStrings.categoryEditType) {
            Picker(AppStrings.categoryEditType, selection: $viewModel.type) {
                Text(AppStrings.categoryExpense).tag(TransactionType.expense)
                Text(AppStrings.categoryIncome).tag(TransactionType.income)
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.hasTransactions)

            if viewModel.hasTransactions {
                Text("Type cannot be changed while transactions exist.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var parentSection: some View {
        Section(AppStrings.categoryEditParent) {
            Picker(AppStrings.categoryEditParent, selection: $viewModel.parentID) {
                Text(AppStrings.categoryEditNoParent).tag(Optional<UUID>.none)
                ForEach(viewModel.availableParents) { parent in
                    HStack {
                        CategoryIcon(iconName: parent.iconName, colorHex: parent.colorHex, size: .small)
                        Text(parent.localizedName)
                    }
                    .tag(Optional(parent.id))
                }
            }
        }
    }

    private var appearanceSection: some View {
        Section(AppStrings.categoryEditIcon) {
            // Icon row
            Button {
                showingIconPicker = true
            } label: {
                HStack {
                    Text(AppStrings.categoryEditIcon)
                        .foregroundStyle(.primary)
                    Spacer()
                    CategoryIcon(iconName: viewModel.iconName, colorHex: viewModel.colorHex, size: .medium)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Select icon: \(viewModel.iconName)")

            // Color row
            VStack(alignment: .leading, spacing: 8) {
                Text(AppStrings.categoryEditColor)
                    .font(.body)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                    ForEach(Self.colorPalette, id: \.self) { hex in
                        Button {
                            viewModel.colorHex = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 30, height: 30)
                                .overlay {
                                    if viewModel.colorHex.uppercased() == hex.uppercased() {
                                        Circle()
                                            .strokeBorder(.white, lineWidth: 2)
                                            .padding(2)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Color \(hex)")
                        .accessibilityAddTraits(viewModel.colorHex.uppercased() == hex.uppercased() ? .isSelected : [])
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var previewSection: some View {
        Section(AppStrings.categoryEditPreview) {
            HStack(spacing: 12) {
                CategoryIcon(
                    iconName: viewModel.iconName,
                    colorHex: viewModel.colorHex,
                    size: .large
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.name.isEmpty ? "Category Name" : viewModel.name)
                        .font(.headline)
                        .foregroundStyle(viewModel.name.isEmpty ? .secondary : .primary)
                    Text(viewModel.type == .expense ? AppStrings.categoryExpense : AppStrings.categoryIncome)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Icon Picker Sheet

    private var iconPickerSheet: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 60)), count: 5), spacing: 16) {
                ForEach(Self.commonIcons, id: \.self) { iconName in
                    Button {
                        viewModel.iconName = iconName
                        showingIconPicker = false
                    } label: {
                        VStack(spacing: 6) {
                            CategoryIcon(
                                iconName: iconName,
                                colorHex: viewModel.colorHex,
                                size: .large
                            )
                            .overlay {
                                if viewModel.iconName == iconName {
                                    Circle()
                                        .strokeBorder(.white, lineWidth: 2)
                                }
                            }
                        }
                        .padding(4)
                        .background(
                            viewModel.iconName == iconName
                                ? Color(hex: viewModel.colorHex).opacity(0.15)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(iconName)
                    .accessibilityAddTraits(viewModel.iconName == iconName ? .isSelected : [])
                }
            }
            .padding()
        }
        .navigationTitle(AppStrings.categoryEditIcon)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(AppStrings.cancel) {
                    showingIconPicker = false
                }
            }
        }
    }
}
