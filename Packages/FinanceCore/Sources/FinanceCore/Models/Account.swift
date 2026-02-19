import Foundation

/// Represents a financial account (bank, cash, credit card, etc.)
public struct Account: Identifiable, Sendable, Hashable, Codable {
    /// Unique identifier for the account.
    public let id: UUID

    /// Display name of the account.
    public var name: String

    /// Type of account (cash, bank, credit card, etc.).
    public var type: AccountType

    /// Currency used for this account.
    public var currency: CurrencyCode

    /// Initial balance when the account was created.
    public var initialBalance: Decimal

    /// Current balance of the account.
    public var balance: Decimal

    /// SF Symbol icon name for visual representation.
    public var iconName: String

    /// Color hex code for UI theming (e.g., "#007AFF").
    public var colorHex: String

    /// Sort order for displaying accounts in lists.
    public var sortOrder: Int

    /// Whether the account is hidden from main views.
    public var isHidden: Bool

    /// Whether the account is archived (no longer active).
    public var isArchived: Bool

    /// Optional note or description for the account.
    public var note: String?

    /// E-wallet provider if the account type is eWallet.
    public var eWalletProvider: EWalletProvider?

    /// Date when the account was created.
    public var createdAt: Date

    /// Date when the account was last updated.
    public var updatedAt: Date

    /// Soft delete timestamp. If set, the account is considered deleted.
    public var deletedAt: Date?

    /// Creates a new account.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - name: Display name of the account.
    ///   - type: Type of account.
    ///   - currency: Currency code. Defaults to VND.
    ///   - initialBalance: Initial balance. Defaults to 0.
    ///   - balance: Current balance. Defaults to 0.
    ///   - iconName: SF Symbol name. Defaults to "banknote".
    ///   - colorHex: Color hex code. Defaults to "#007AFF".
    ///   - sortOrder: Sort order. Defaults to 0.
    ///   - isHidden: Whether hidden. Defaults to false.
    ///   - isArchived: Whether archived. Defaults to false.
    ///   - note: Optional note.
    ///   - eWalletProvider: E-wallet provider if applicable.
    ///   - createdAt: Creation date. Defaults to current date.
    ///   - updatedAt: Last update date. Defaults to current date.
    ///   - deletedAt: Soft delete timestamp. Defaults to nil.
    public init(
        id: UUID = UUID(),
        name: String,
        type: AccountType,
        currency: CurrencyCode = .VND,
        initialBalance: Decimal = 0,
        balance: Decimal = 0,
        iconName: String = "banknote",
        colorHex: String = "#007AFF",
        sortOrder: Int = 0,
        isHidden: Bool = false,
        isArchived: Bool = false,
        note: String? = nil,
        eWalletProvider: EWalletProvider? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.currency = currency
        self.initialBalance = initialBalance
        self.balance = balance
        self.iconName = iconName
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isHidden = isHidden
        self.isArchived = isArchived
        self.note = note
        self.eWalletProvider = eWalletProvider
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

/// Types of financial accounts.
///
/// Represents the various account types supported by the application,
/// each with its own icon, color, and display characteristics.
public enum AccountType: String, Sendable, CaseIterable, Codable, Hashable {
    case cash
    case bank
    case creditCard
    case eWallet
    case savings
    case investment
    case loan
    case other

    /// Display name for the account type.
    public var displayName: String {
        switch self {
        case .cash: return "Cash"
        case .bank: return "Bank"
        case .creditCard: return "Credit Card"
        case .eWallet: return "E-Wallet"
        case .savings: return "Savings"
        case .investment: return "Investment"
        case .loan: return "Loan"
        case .other: return "Other"
        }
    }

    /// Default SF Symbol icon name for this account type.
    public var defaultIconName: String {
        switch self {
        case .cash: return "banknote"
        case .bank: return "building.columns"
        case .creditCard: return "creditcard"
        case .eWallet: return "wallet.pass"
        case .savings: return "chart.line.uptrend.xyaxis"
        case .investment: return "chart.pie"
        case .loan: return "doc.text"
        case .other: return "ellipsis.circle"
        }
    }

    /// Default color hex code for this account type.
    public var defaultColorHex: String {
        switch self {
        case .cash: return "#34C759"        // Green
        case .bank: return "#007AFF"        // Blue
        case .creditCard: return "#FF9500"  // Orange
        case .eWallet: return "#5856D6"     // Purple
        case .savings: return "#30B0C7"     // Teal
        case .investment: return "#AF52DE"  // Purple (darker)
        case .loan: return "#FF3B30"        // Red
        case .other: return "#8E8E93"       // Gray
        }
    }
}
