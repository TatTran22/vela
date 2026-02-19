import FinanceCore
import FinanceUI
import SwiftUI

/// A 3-step sheet for quickly entering a new income or expense transaction.
///
/// **Step 1 — Amount**: Type toggle (Income/Expense), QuickNumpad, Next button.
/// **Step 2 — Category**: CategoryPicker, Back/Next buttons.
/// **Step 3 — Review**: Summary with expandable detail section (note, date, account).
struct QuickInputView: View {
    @State private var viewModel: QuickInputViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    /// Creates a quick-input view.
    /// - Parameter viewModel: The view model driving the input flow.
    init(viewModel: QuickInputViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            stepContent
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .accessibilityLabel("Cancel and dismiss the entry form.")
            }
            if viewModel.currentStep != .amount {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { viewModel.previousStep() }
                        .accessibilityLabel("Go back to the previous step.")
                }
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
            await viewModel.loadData()
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .amount:
            amountStep
        case .category:
            categoryStep
        case .review:
            reviewStep
        }
    }

    // MARK: - Step 1: Amount

    private var amountStep: some View {
        VStack(spacing: 0) {
            // Type toggle
            typeSegment
                .padding(.horizontal)
                .padding(.top, 16)

            // Parsed amount display
            amountDisplay
                .padding(.top, 12)

            Spacer(minLength: 8)

            // Numpad
            QuickNumpad(expression: $viewModel.amountExpression) { result in
                viewModel.parsedAmount = result
            } onDone: {
                viewModel.nextStep()
            }

            // Next button
            nextButton(label: "Next: Choose Category") {
                viewModel.nextStep()
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    private var typeSegment: some View {
        Picker("Transaction Type", selection: $viewModel.transactionType) {
            Text(TransactionType.expense.displayName).tag(TransactionType.expense)
            Text(TransactionType.income.displayName).tag(TransactionType.income)
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Select transaction type.")
    }

    private var amountDisplay: some View {
        let formatter = CurrencyFormatter(currencyCode: .VND)
        let displayAmount = viewModel.parsedAmount > 0
            ? formatter.format(viewModel.parsedAmount)
            : "0"
        return Text(displayAmount)
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .foregroundStyle(viewModel.transactionType == .expense ? .red : .green)
            .monospacedDigit()
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityLabel("Amount: \(displayAmount)")
    }

    // MARK: - Step 2: Category

    private var categoryStep: some View {
        VStack(spacing: 0) {
            CategoryPicker(
                categories: viewModel.categories,
                recentCategoryIDs: viewModel.recentCategoryIDs,
                transactionType: viewModel.transactionType
            ) { category in
                viewModel.selectedCategory = category
                viewModel.nextStep()
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Step 3: Review

    private var reviewStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                reviewSummaryCard

                if viewModel.showDetails {
                    detailsSection
                } else {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.showDetails = true
                        }
                    } label: {
                        Label("Add Details", systemImage: "chevron.down")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                    .accessibilityLabel("Expand to add details like note, date, and account.")
                }

                saveButton

                Spacer(minLength: 24)
            }
            .padding()
        }
    }

    private var reviewSummaryCard: some View {
        VStack(spacing: 16) {
            // Amount with type color
            let formatter = CurrencyFormatter(currencyCode: .VND)
            let sign = viewModel.transactionType == .expense ? "-" : "+"
            Text("\(sign)\(formatter.format(viewModel.parsedAmount))")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(viewModel.transactionType == .expense ? .red : .green)
                .monospacedDigit()
                .accessibilityLabel("Amount: \(formatter.format(viewModel.parsedAmount))")

            Divider()

            // Category row
            HStack {
                Label {
                    Text(viewModel.selectedCategory?.name ?? "No category")
                        .foregroundStyle(.primary)
                } icon: {
                    if let cat = viewModel.selectedCategory {
                        ZStack {
                            Circle()
                                .fill(Color(hex: cat.colorHex))
                                .frame(width: 32, height: 32)
                            Image(systemName: cat.iconName)
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                    } else {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text("Category")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Category: \(viewModel.selectedCategory?.name ?? "None")")

            // Account row
            HStack {
                Image(systemName: viewModel.selectedAccount?.iconName ?? "banknote")
                    .foregroundStyle(.blue)
                Text(viewModel.selectedAccount?.name ?? "No account selected")
                    .foregroundStyle(.primary)
                Spacer()
                Text("Account")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Account: \(viewModel.selectedAccount?.name ?? "None")")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            // Note field
            VStack(alignment: .leading, spacing: 4) {
                Text("Note")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Optional note", text: $viewModel.note, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3)
                    .accessibilityLabel("Transaction note.")
            }

            // Date picker
            DatePicker(
                "Date",
                selection: $viewModel.date,
                displayedComponents: [.date, .hourAndMinute]
            )
            .accessibilityLabel("Transaction date and time.")

            // Account picker
            if !viewModel.accounts.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Account")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Account", selection: $viewModel.selectedAccount) {
                        ForEach(viewModel.accounts) { account in
                            Text(account.name).tag(Optional(account))
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Select account.")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

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
                    Text("Save Transaction")
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
        .accessibilityLabel(viewModel.isSaving ? "Saving transaction." : "Save transaction.")
    }

    // MARK: - Helpers

    private var navigationTitle: String {
        switch viewModel.currentStep {
        case .amount:
            return "Amount"
        case .category:
            return "Category"
        case .review:
            return "Review"
        }
    }

    private func nextButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel(label)
    }
}
