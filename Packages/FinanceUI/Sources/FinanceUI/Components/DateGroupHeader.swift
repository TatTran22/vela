import FinanceCore
import SwiftUI

/// A section header for a date-grouped transaction list.
///
/// `DateGroupHeader` renders the date of a transaction group on the left and a
/// summary of the group's income and expense totals on the right. The date is
/// displayed as a relative label ("Hom nay" or "Hom qua") for today and
/// yesterday, or as a full weekday/date string for earlier dates.
///
/// The totals use compact currency formatting so they remain readable even for
/// very large numbers. Income is shown in green with a leading `+` sign;
/// expense is shown in red with a leading `-` sign. A total of zero is
/// omitted for cleaner display.
///
/// Example usage:
/// ```swift
/// DateGroupHeader(
///     date: Date(),
///     income: 5_000_000,
///     expense: 200_000,
///     currencyCode: .VND
/// )
/// ```
public struct DateGroupHeader: View {
    private let date: Date
    private let income: Decimal
    private let expense: Decimal
    private let currencyCode: CurrencyCode

    /// Creates a date group header.
    ///
    /// - Parameters:
    ///   - date: The date this group represents. Used for both the label and
    ///     relative formatting.
    ///   - income: Total income for transactions on this date.
    ///   - expense: Total expense for transactions on this date.
    ///   - currencyCode: Currency code used to format the totals.
    public init(
        date: Date,
        income: Decimal,
        expense: Decimal,
        currencyCode: CurrencyCode
    ) {
        self.date = date
        self.income = income
        self.expense = expense
        self.currencyCode = currencyCode
    }

    public var body: some View {
        HStack(alignment: .center) {
            dateLabel

            Spacer()

            totalsView
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(Color.secondary.opacity(0.1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Subviews

    private var dateLabel: some View {
        Text(formattedDate)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
    }

    private var totalsView: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            if income > 0 {
                Text("+\(formattedAmount(income))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.Colors.income)
            }

            if expense > 0 {
                Text("-\(formattedAmount(expense))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.Colors.expense)
            }
        }
    }

    // MARK: - Formatting

    private var formattedDate: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Hom nay"
        }

        if calendar.isDateInYesterday(date) {
            return "Hom qua"
        }

        // Within 6 days: "Thu Hai, 10/02/2026"
        if let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day,
           daysAgo < 7 {
            return fullDateString(date)
        }

        return fullDateString(date)
    }

    private func fullDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "EEEE, dd/MM/yyyy"
        // Capitalise first letter
        let raw = formatter.string(from: date)
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }

    private func formattedAmount(_ amount: Decimal) -> String {
        CurrencyFormatter(currencyCode: currencyCode).formatCompact(amount)
    }

    private var accessibilityLabel: String {
        var parts: [String] = [formattedDate]
        let formatter = CurrencyFormatter(currencyCode: currencyCode)
        if income > 0 {
            parts.append("income \(formatter.format(income))")
        }
        if expense > 0 {
            parts.append("expense \(formatter.format(expense))")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Previews

#Preview("Today") {
    DateGroupHeader(
        date: Date(),
        income: 5_000_000,
        expense: 200_000,
        currencyCode: .VND
    )
}

#Preview("Yesterday") {
    DateGroupHeader(
        date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
        income: 0,
        expense: 350_000,
        currencyCode: .VND
    )
}

#Preview("Earlier Date") {
    DateGroupHeader(
        date: Calendar.current.date(byAdding: .day, value: -9, to: Date()) ?? Date(),
        income: 10_000_000,
        expense: 1_500_000,
        currencyCode: .VND
    )
}

#Preview("Income Only") {
    DateGroupHeader(
        date: Date(),
        income: 8_000_000,
        expense: 0,
        currencyCode: .VND
    )
}

#Preview("Expense Only") {
    DateGroupHeader(
        date: Date(),
        income: 0,
        expense: 450_000,
        currencyCode: .VND
    )
}

#Preview("In List Context") {
    List {
        Section {
            DateGroupHeader(
                date: Date(),
                income: 5_000_000,
                expense: 200_000,
                currencyCode: .VND
            )
            .listRowInsets(EdgeInsets())

            Text("Transaction row 1")
                .padding(.horizontal)
            Text("Transaction row 2")
                .padding(.horizontal)
        }

        Section {
            DateGroupHeader(
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                income: 0,
                expense: 350_000,
                currencyCode: .VND
            )
            .listRowInsets(EdgeInsets())

            Text("Transaction row 3")
                .padding(.horizontal)
        }
    }
    .listStyle(.plain)
}

#Preview("Dark Mode") {
    VStack(spacing: 0) {
        DateGroupHeader(
            date: Date(),
            income: 5_000_000,
            expense: 200_000,
            currencyCode: .VND
        )
        Divider()
        DateGroupHeader(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            income: 1_000_000,
            expense: 800_000,
            currencyCode: .VND
        )
    }
    .preferredColorScheme(.dark)
}
