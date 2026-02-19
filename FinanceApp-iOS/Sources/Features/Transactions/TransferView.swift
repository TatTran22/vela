import FinanceCore
import FinanceUI
import SwiftUI

/// Sheet view for creating a transfer between two accounts.
///
/// Shows source and destination account pickers with an arrow between them,
/// a QuickNumpad for amount entry, optional cross-currency exchange rate field,
/// an optional fee field, date picker, and note field. A Save button persists
/// the transfer via the view model.
struct TransferView: View {
    @State private var viewModel: TransferViewModel
    @State private var showNumpad = true
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    /// Creates a transfer view.
    /// - Parameter viewModel: The view model managing transfer state.
    init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                accountSelectionSection
                amountSection
                if viewModel.needsExchangeRate {
                    exchangeRateSection
                }
                optionalFieldsSection
                saveButton
                Spacer(minLength: 24)
            }
            .padding()
        }
        .navigationTitle("Transfer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .accessibilityLabel("Cancel and dismiss the transfer form.")
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .onChange(of: viewModel.didSave) { _, saved in
            if saved { dismiss() }
        }
        .task {
            await viewModel.loadAccounts()
        }
    }

    // MARK: - Account Selection

    private var accountSelectionSection: some View {
        VStack(spacing: 12) {
            Text("From / To")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 16) {
                // Source account
                accountPicker(
                    label: "From",
                    selection: $viewModel.sourceAccount,
                    options: viewModel.accounts
                )

                // Arrow
                VStack {
                    Image(systemName: "arrow.down")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .accessibilityHidden(true)

                // Destination account
                accountPicker(
                    label: "To",
                    selection: $viewModel.destinationAccount,
                    options: viewModel.availableDestinations
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func accountPicker(
        label: String,
        selection: Binding<Account?>,
        options: [Account]
    ) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            if options.isEmpty {
                Text("No account")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Menu {
                    ForEach(options) { account in
                        Button {
                            selection.wrappedValue = account
                        } label: {
                            Label {
                                VStack(alignment: .leading) {
                                    Text(account.name)
                                    Text(CurrencyFormatter(currencyCode: account.currency)
                                        .format(account.balance))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: account.iconName)
                            }
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        if let selected = selection.wrappedValue {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: selected.colorHex).opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: selected.iconName)
                                    .foregroundStyle(Color(hex: selected.colorHex))
                            }
                            Text(selected.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                            Text(CurrencyFormatter(currencyCode: selected.currency)
                                .formatCompact(selected.balance))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("Select")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .accessibilityLabel("\(label) account: \(selection.wrappedValue?.name ?? "Not selected"). Tap to change.")
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Amount

    private var amountSection: some View {
        VStack(spacing: 0) {
            // Parsed amount display
            let formatter = CurrencyFormatter(currencyCode: viewModel.sourceAccount?.currency ?? .VND)
            let displayAmount = viewModel.parsedAmount > 0
                ? formatter.format(viewModel.parsedAmount)
                : "0"

            HStack {
                Text("Amount")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showNumpad.toggle()
                    }
                } label: {
                    Image(systemName: showNumpad ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(showNumpad ? "Collapse numpad." : "Expand numpad.")
            }
            .padding(.horizontal)
            .padding(.top, 12)

            Text(displayAmount)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.blue)
                .monospacedDigit()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .accessibilityLabel("Transfer amount: \(displayAmount)")

            if showNumpad {
                QuickNumpad(expression: $viewModel.amountExpression) { result in
                    viewModel.parsedAmount = result
                } onDone: {
                    withAnimation { showNumpad = false }
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Exchange Rate

    private var exchangeRateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exchange Rate")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. 24500", text: $viewModel.exchangeRate)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Exchange rate from \(viewModel.sourceAccount?.currency.rawValue ?? "source") to \(viewModel.destinationAccount?.currency.rawValue ?? "destination").")
                }

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("You receive")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    let dstFormatter = CurrencyFormatter(currencyCode: viewModel.destinationAccount?.currency ?? .VND)
                    Text(dstFormatter.format(viewModel.destinationAmount))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                        .monospacedDigit()
                        .accessibilityLabel("Destination amount: \(dstFormatter.format(viewModel.destinationAmount))")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Optional Fields

    private var optionalFieldsSection: some View {
        VStack(spacing: 16) {
            // Fee
            HStack {
                Image(systemName: "percent")
                    .foregroundStyle(.orange)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Fee (optional)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("0", text: $viewModel.fee)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Transfer fee.")
                }
            }
            Divider().padding(.leading, 36)

            // Date
            DatePicker(
                "Date",
                selection: $viewModel.date,
                displayedComponents: [.date, .hourAndMinute]
            )
            .accessibilityLabel("Transfer date and time.")

            Divider().padding(.leading, 36)

            // Note
            HStack(alignment: .top) {
                Image(systemName: "note.text")
                    .foregroundStyle(.orange)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Note (optional)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Add a note", text: $viewModel.note, axis: .vertical)
                        .lineLimit(3)
                        .accessibilityLabel("Transfer note.")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            Task { await viewModel.save() }
        } label: {
            Group {
                if viewModel.isSaving {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text("Transfer")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(viewModel.isSaving ? Color.blue.opacity(0.6) : Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(viewModel.isSaving)
        .accessibilityLabel(viewModel.isSaving ? "Saving transfer." : "Save transfer.")
    }
}
