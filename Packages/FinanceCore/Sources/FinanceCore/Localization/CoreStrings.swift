import Foundation

/// Type-safe accessors for localized strings in the FinanceCore module.
public enum CoreStrings {
    // MARK: - Transaction Type

    /// "Income" / "Thu nhập"
    public static var transactionTypeIncome: String {
        String(localized: "transaction.type.income", bundle: .module)
    }

    /// "Expense" / "Chi tiêu"
    public static var transactionTypeExpense: String {
        String(localized: "transaction.type.expense", bundle: .module)
    }

    /// "Transfer" / "Chuyển khoản"
    public static var transactionTypeTransfer: String {
        String(localized: "transaction.type.transfer", bundle: .module)
    }

    // MARK: - Account Type

    /// "Cash" / "Tiền mặt"
    public static var accountTypeCash: String {
        String(localized: "account.type.cash", bundle: .module)
    }

    /// "Bank" / "Ngân hàng"
    public static var accountTypeBank: String {
        String(localized: "account.type.bank", bundle: .module)
    }

    /// "Credit Card" / "Thẻ tín dụng"
    public static var accountTypeCreditCard: String {
        String(localized: "account.type.creditCard", bundle: .module)
    }

    /// "E-Wallet" / "Ví điện tử"
    public static var accountTypeEWallet: String {
        String(localized: "account.type.eWallet", bundle: .module)
    }

    /// "Savings" / "Tiết kiệm"
    public static var accountTypeSavings: String {
        String(localized: "account.type.savings", bundle: .module)
    }

    /// "Investment" / "Đầu tư"
    public static var accountTypeInvestment: String {
        String(localized: "account.type.investment", bundle: .module)
    }

    /// "Loan" / "Khoản vay"
    public static var accountTypeLoan: String {
        String(localized: "account.type.loan", bundle: .module)
    }

    /// "Other" / "Khác"
    public static var accountTypeOther: String {
        String(localized: "account.type.other", bundle: .module)
    }

    // MARK: - E-Wallet Provider

    /// "MoMo"
    public static var ewalletMomo: String {
        String(localized: "ewallet.provider.momo", bundle: .module)
    }

    /// "ZaloPay"
    public static var ewalletZalopay: String {
        String(localized: "ewallet.provider.zalopay", bundle: .module)
    }

    /// "VNPay"
    public static var ewalletVnpay: String {
        String(localized: "ewallet.provider.vnpay", bundle: .module)
    }

    /// "Other" / "Khác"
    public static var ewalletOther: String {
        String(localized: "ewallet.provider.other", bundle: .module)
    }

    // MARK: - Currency Names

    /// Returns the localized name for a currency code.
    public static func currencyName(_ code: String) -> String {
        let key = String.LocalizationValue(stringLiteral: "currency.name.\(code)")
        return String(localized: key, bundle: .module)
    }

    // MARK: - Date

    /// "Today" / "Hôm nay"
    public static var dateToday: String {
        String(localized: "date.today", bundle: .module)
    }

    /// "Yesterday" / "Hôm qua"
    public static var dateYesterday: String {
        String(localized: "date.yesterday", bundle: .module)
    }

    /// "%lld days ago" / "%lld ngày trước"
    public static func dateDaysAgo(_ count: Int) -> String {
        String(localized: "date.daysAgo", bundle: .module).replacingOccurrences(of: "%lld", with: "\(count)")
    }
}
