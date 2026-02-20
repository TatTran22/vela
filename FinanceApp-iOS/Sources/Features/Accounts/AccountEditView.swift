import FinanceCore
import FinanceUI
import SwiftUI

/// View for creating or editing an account
///
/// Provides a form interface for entering account details.
/// Save is always enabled — field-level errors appear inline after tapping Save.
struct AccountEditView: View {
    @State private var viewModel: AccountEditViewModel
    @State private var showingColorPicker = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init(viewModel: AccountEditViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        Form {
            // Name section
            Section(AppStrings.accountEditSectionName) {
                VStack(alignment: .leading, spacing: 4) {
                    TextField(AppStrings.accountEditSectionName, text: $viewModel.name, prompt: Text(AppStrings.accountEditNamePlaceholder))
                        .onChange(of: viewModel.name) { _, _ in
                            viewModel.fieldErrors.removeValue(forKey: "name")
                        }
                    if let error = viewModel.fieldErrors["name"] {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            // Type section
            Section(AppStrings.accountEditSectionType) {
                Picker(AppStrings.accountEditSectionType, selection: $viewModel.type) {
                    ForEach(AccountType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.defaultIconName)
                            .tag(type)
                    }
                }
                .onChange(of: viewModel.type) { _, _ in
                    viewModel.updateIconAndColor()
                    if viewModel.type == .eWallet {
                        viewModel.eWalletProvider = .momo
                    } else {
                        viewModel.eWalletProvider = nil
                    }
                }

                if viewModel.type == .eWallet {
                    Picker(AppStrings.accountEditProvider, selection: Binding(
                        get: { viewModel.eWalletProvider ?? .other },
                        set: { viewModel.eWalletProvider = $0 }
                    )) {
                        ForEach(EWalletProvider.allCases, id: \.self) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                }
            }

            // Appearance section
            Section(AppStrings.accountEditSectionAppearance) {
                NavigationLink {
                    IconPicker(selectedIcon: $viewModel.iconName)
                } label: {
                    HStack {
                        Text(AppStrings.accountEditIcon)
                        Spacer()
                        Image(systemName: viewModel.iconName)
                            .font(.title3)
                            .foregroundStyle(Color(hex: viewModel.colorHex))
                    }
                }

                HStack {
                    Text(AppStrings.accountEditColor)
                    Spacer()
                    Button {
                        showingColorPicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: viewModel.colorHex))
                                .frame(width: 24, height: 24)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingColorPicker) {
                        VStack(spacing: 16) {
                            Text(AppStrings.accountEditChooseColor)
                                .font(.headline)
                                .padding(.top, 4)
                            
                            ColorPickerGrid(selectedColorHex: $viewModel.colorHex) { _ in
                                showingColorPicker = false
                            }
                            .frame(width: 280) // Optimized for mobile
                        }
                        .padding(20)
                        .presentationCompactAdaptation(.popover)
                    }
                }
            }

            // Currency section
            Section(AppStrings.accountEditSectionCurrency) {
                NavigationLink {
                    CurrencyPicker(selected: $viewModel.currency)
                } label: {
                    HStack {
                        Text(AppStrings.accountEditSectionCurrency)
                        Spacer()
                        Text("\(viewModel.currency.flag) \(viewModel.currency.rawValue)")
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(viewModel.isEditing)

                if viewModel.isEditing {
                    Text(AppStrings.accountEditCurrencyCannotChange)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Balance section
            if !viewModel.isEditing {
                Section(AppStrings.accountEditSectionBalance) {
                    TextField(AppStrings.accountEditSectionBalance, text: $viewModel.initialBalance, prompt: Text("0"))
                        .keyboardType(.decimalPad)

                    if viewModel.parsedBalance != 0 {
                        BalanceText(
                            amount: viewModel.parsedBalance,
                            currencyCode: viewModel.currency,
                            size: .medium
                        )
                        .foregroundStyle(.secondary)
                    }
                }
            }

            // Notes section
            Section(AppStrings.accountEditSectionNotes) {
                TextField(AppStrings.accountEditSectionNotes, text: $viewModel.note, prompt: Text(AppStrings.accountEditOptionalNotes), axis: .vertical)
                    .lineLimit(3...6)
            }
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
        .alert(AppStrings.error, isPresented: $viewModel.showError) {
            Button(AppStrings.ok) {}
        } message: {
            if let error = viewModel.generalError {
                Text(error)
            }
        }
    }
}
