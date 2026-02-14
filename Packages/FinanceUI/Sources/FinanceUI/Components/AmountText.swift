import FinanceCore
import SwiftUI

/// Displays a formatted monetary amount with color coding
public struct AmountText: View {
    private let amount: Decimal
    private let currencyCode: String
    private let type: TransactionType?

    public init(
        amount: Decimal,
        currencyCode: String = "VND",
        type: TransactionType? = nil
    ) {
        self.amount = amount
        self.currencyCode = currencyCode
        self.type = type
    }

    public var body: some View {
        Text(formatted)
            .foregroundStyle(color)
            .monospacedDigit()
    }

    private var formatted: String {
        CurrencyFormatter(currencyCode: currencyCode).format(amount)
    }

    private var color: Color {
        switch type {
        case .income:
            .green
        case .expense:
            .red
        case .transfer, .none:
            .primary
        }
    }
}
