import FinanceCore
import FinanceUI
import SwiftUI

/// Sheet for manually adjusting an account's balance
///
/// Allows entering a positive or negative adjustment amount and previews the resulting balance.
struct BalanceAdjustSheet: View {
    let account: Account
    let onAdjust: (Decimal) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var adjustmentAmount = ""
    @State private var isProcessing = false

    // MARK: - Computed Properties

    private var parsedAdjustment: Decimal {
        Decimal(string: adjustmentAmount) ?? 0
    }

    private var newBalance: Decimal {
        account.balance + parsedAdjustment
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section(AppStrings.balanceAdjustCurrentBalance) {
                    BalanceText(
                        amount: account.balance,
                        currencyCode: account.currency,
                        size: .large
                    )
                }

                Section(AppStrings.balanceAdjustAdjustmentAmount) {
                    TextField(AppStrings.balanceAdjustAmountPlaceholder, text: $adjustmentAmount)
                        .keyboardType(.decimalPad)

                    Text(AppStrings.balanceAdjustHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if parsedAdjustment != 0 {
                    Section(AppStrings.balanceAdjustNewBalance) {
                        HStack {
                            BalanceText(
                                amount: newBalance,
                                currencyCode: account.currency,
                                size: .medium
                            )

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: parsedAdjustment > 0 ? "arrow.up" : "arrow.down")
                                    .foregroundStyle(parsedAdjustment > 0 ? .green : .red)
                                    .font(.caption)

                                Text(CurrencyFormatter(currencyCode: account.currency).format(abs(parsedAdjustment)))
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle(AppStrings.balanceAdjustTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isProcessing {
                        ProgressView()
                    } else {
                        Button(AppStrings.apply) {
                            Task {
                                isProcessing = true
                                await onAdjust(parsedAdjustment)
                                dismiss()
                            }
                        }
                        .disabled(adjustmentAmount.isEmpty || parsedAdjustment == 0 || isProcessing)
                    }
                }
            }
        }
    }
}
