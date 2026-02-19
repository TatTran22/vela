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
            Section("Account Name") {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Account Name", text: $viewModel.name, prompt: Text("e.g. My Savings"))
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
            Section("Type") {
                Picker("Account Type", selection: $viewModel.type) {
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
                    Picker("Provider", selection: Binding(
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
            Section("Appearance") {
                NavigationLink {
                    IconPicker(selectedIcon: $viewModel.iconName)
                } label: {
                    HStack {
                        Text("Icon")
                        Spacer()
                        Image(systemName: viewModel.iconName)
                            .font(.title3)
                            .foregroundStyle(Color(hex: viewModel.colorHex))
                    }
                }

                HStack {
                    Text("Color")
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
                            Text("Choose Color")
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
            Section("Currency") {
                NavigationLink {
                    CurrencyPicker(selected: $viewModel.currency)
                } label: {
                    HStack {
                        Text("Currency")
                        Spacer()
                        Text("\(viewModel.currency.flag) \(viewModel.currency.rawValue)")
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(viewModel.isEditing)

                if viewModel.isEditing {
                    Text("Currency cannot be changed after account creation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Balance section
            if !viewModel.isEditing {
                Section("Initial Balance") {
                    TextField("Initial Balance", text: $viewModel.initialBalance, prompt: Text("0"))
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
            Section("Notes") {
                TextField("Notes", text: $viewModel.note, prompt: Text("Optional notes..."), axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Button("Save") {
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
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            if let error = viewModel.generalError {
                Text(error)
            }
        }
    }
}
