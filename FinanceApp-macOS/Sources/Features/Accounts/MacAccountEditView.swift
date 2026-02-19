import FinanceCore
import FinanceData
import FinanceUI
import SwiftUI

/// macOS-style form for creating and editing accounts.
///
/// Presents a modal form with sections for account details including name, type,
/// currency, initial balance, and notes. Supports both creation and editing modes.
/// Save is always enabled — field-level errors appear inline after tapping Save.
struct MacAccountEditView: View {
    @State private var name = ""
    @State private var type: AccountType = .cash
    @State private var currency: CurrencyCode = .VND
    @State private var initialBalance = ""
    @State private var iconName = "banknote"
    @State private var colorHex = "#34C759"
    @State private var eWalletProvider: EWalletProvider?
    @State private var note = ""
    @State private var isSaving = false
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false

    /// Field-level validation errors, keyed by field name
    @State private var fieldErrors: [String: String] = [:]

    /// General error message (non-field-specific)
    @State private var errorMessage: String?

    /// The account being edited, or nil for creating a new account
    let editingAccount: Account?

    /// Use case for creating new accounts
    let createAccountUseCase: CreateAccountUseCaseProtocol

    /// Use case for updating existing accounts
    let updateAccountUseCase: UpdateAccountUseCaseProtocol

    /// Callback invoked after successful save
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    /// Whether this view is in editing mode (vs. creation mode)
    var isEditing: Bool { editingAccount != nil }

    init(
        account: Account? = nil,
        createAccountUseCase: CreateAccountUseCaseProtocol,
        updateAccountUseCase: UpdateAccountUseCaseProtocol,
        onSave: @escaping () -> Void
    ) {
        self.editingAccount = account
        self.createAccountUseCase = createAccountUseCase
        self.updateAccountUseCase = updateAccountUseCase
        self.onSave = onSave

        if let account {
            _name = State(initialValue: account.name)
            _type = State(initialValue: account.type)
            _currency = State(initialValue: account.currency)
            _initialBalance = State(initialValue: "\(account.initialBalance)")
            _iconName = State(initialValue: account.iconName)
            _colorHex = State(initialValue: account.colorHex)
            _eWalletProvider = State(initialValue: account.eWalletProvider)
            _note = State(initialValue: account.note ?? "")
        }
    }

    var body: some View {
        Form {
            // MARK: - General
            Section("General") {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Account Name", text: $name, prompt: Text("e.g. My Savings"))
                        .onChange(of: name) { _, _ in fieldErrors.removeValue(forKey: "name") }
                    if let error = fieldErrors["name"] {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Picker("Type", selection: $type) {
                    ForEach(AccountType.allCases, id: \.self) { t in
                        Label(t.displayName, systemImage: t.defaultIconName).tag(t)
                    }
                }
                .onChange(of: type) { _, newType in
                    iconName = newType.defaultIconName
                    colorHex = newType.defaultColorHex
                    eWalletProvider = newType == .eWallet ? .momo : nil
                }

                if type == .eWallet {
                    Picker("Provider", selection: Binding(
                        get: { eWalletProvider ?? .other },
                        set: { eWalletProvider = $0 }
                    )) {
                        ForEach(EWalletProvider.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                }
            }

            // MARK: - Appearance
            Section("Appearance") {
                HStack {
                    Text("Icon")
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

                HStack {
                    Text("Color")
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
                            Text("Choose Color")
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

            // MARK: - Currency
            Section("Currency") {
                Picker("Currency", selection: $currency) {
                    ForEach(CurrencyCode.allCases, id: \.self) { c in
                        Text("\(c.flag) \(c.rawValue) - \(c.name)").tag(c)
                    }
                }
            }

            // MARK: - Initial Balance
            if !isEditing {
                Section("Initial Balance") {
                    TextField("Initial Balance", text: $initialBalance, prompt: Text("0"))
                }
            }

            // MARK: - Notes
            Section("Notes") {
                TextEditor(text: $note)
                    .frame(height: 80)
                    .overlay(alignment: .topLeading) {
                        if note.isEmpty {
                            Text("Optional notes...")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
            }

            // MARK: - General Error
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(isEditing ? "Edit Account" : "New Account")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(isSaving)
                .keyboardShortcut("s", modifiers: .command)
            }
        }
        .frame(minWidth: 400, minHeight: 400)
    }

    // MARK: - Validation

    /// Validates all fields and populates fieldErrors. Returns true if valid.
    private func validate() -> Bool {
        fieldErrors.removeAll()

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            fieldErrors["name"] = "Account name is required"
        }

        return fieldErrors.isEmpty
    }

    // MARK: - Save

    /// Saves the account by creating or updating based on the editing mode.
    private func save() async {
        guard validate() else { return }

        isSaving = true
        errorMessage = nil

        do {
            let balance = Decimal(string: initialBalance) ?? 0
            if let existing = editingAccount {
                var updated = existing
                updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                updated.type = type
                updated.currency = currency
                updated.iconName = iconName
                updated.colorHex = colorHex
                updated.eWalletProvider = eWalletProvider
                updated.note = note.isEmpty ? nil : note
                updated.updatedAt = Date()
                _ = try await updateAccountUseCase.execute(updated, hasTransactions: false)
            } else {
                let account = Account(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    type: type,
                    currency: currency,
                    initialBalance: balance,
                    balance: balance,
                    iconName: iconName,
                    colorHex: colorHex,
                    note: note.isEmpty ? nil : note,
                    eWalletProvider: eWalletProvider
                )
                _ = try await createAccountUseCase.execute(account)
            }
            onSave()
            dismiss()
        } catch let error as AccountError {
            mapAccountError(error)
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    /// Maps AccountError to field-level or general error messages.
    private func mapAccountError(_ error: AccountError) {
        switch error {
        case .nameEmpty:
            fieldErrors["name"] = "Account name is required"
        case .nameAlreadyExists(_):
            fieldErrors["name"] = "An account with this name already exists"
        default:
            errorMessage = error.localizedDescription
        }
    }
}
