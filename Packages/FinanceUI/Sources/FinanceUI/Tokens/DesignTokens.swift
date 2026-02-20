import SwiftUI

/// Design system tokens for consistent theming across the app.
///
/// All spacing, color, typography, corner radius, and shadow values are defined
/// here so that every view references the same source of truth.
public enum DesignTokens {

    // MARK: - Spacing

    public enum Spacing {
        public static let xxs: CGFloat = 2
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
        public static let xxxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    public enum CornerRadius {
        public static let sm: CGFloat = 4
        public static let md: CGFloat = 8
        public static let lg: CGFloat = 12
        public static let xl: CGFloat = 16
        public static let full: CGFloat = 9999
    }

    // MARK: - Colors

    /// Semantic color tokens that adapt to light/dark mode automatically.
    public enum Colors {
        // Transaction type colors
        /// Income / positive changes / goals achieved
        public static let income = Color.green
        /// Expense / negative changes / over budget
        public static let expense = Color.red
        /// Transfers / neutral actions
        public static let transfer = Color.blue

        // Status colors
        public static let success = Color.green
        public static let warning = Color.orange
        public static let error = Color.red
        public static let info = Color.blue

        // Text colors (use system semantic colors)
        public static let textPrimary = Color.primary
        public static let textSecondary = Color.secondary
        public static let textTertiary = Color(uiColorCompat: "tertiaryLabel")

        // Background colors
        public static let backgroundPrimary = Color(uiColorCompat: "systemBackground")
        public static let backgroundSecondary = Color(uiColorCompat: "secondarySystemBackground")
        public static let backgroundGrouped = Color(uiColorCompat: "systemGroupedBackground")

        /// Returns the appropriate color for a transaction type.
        public static func transactionColor(for type: TransactionTypeColorKey) -> Color {
            switch type {
            case .income: return income
            case .expense: return expense
            case .transfer: return transfer
            }
        }
    }

    // MARK: - Typography

    /// Font tokens matching the design system specification.
    public enum Typography {
        /// 34pt Bold Rounded — Dashboard total balance
        public static let heroAmount: Font = .system(.largeTitle, design: .rounded, weight: .bold)
        /// 28pt Bold Rounded — Card balances
        public static let largeAmount: Font = .system(.title, design: .rounded, weight: .bold)
        /// 20pt Semibold Rounded — List item amounts
        public static let amount: Font = .system(.title3, design: .rounded, weight: .semibold)
        /// 17pt Semibold Monospaced — Budget progress values
        public static let smallAmount: Font = .system(.body, weight: .semibold).monospacedDigit()

        /// 22pt Bold — Section headers
        public static let heading: Font = .system(.title2, weight: .bold)
        /// 17pt Semibold — Card titles, row titles
        public static let subheading: Font = .system(.headline, weight: .semibold)
        /// 17pt Regular — General text
        public static let body: Font = .system(.body)
        /// 15pt Regular — Supporting text
        public static let callout: Font = .system(.callout)
        /// 13pt Regular — Disclaimers, hints
        public static let footnote: Font = .system(.footnote)
        /// 12pt Regular — Timestamps, secondary info
        public static let caption: Font = .system(.caption)
        /// 11pt Regular — Smallest text
        public static let caption2: Font = .system(.caption2)
    }

    // MARK: - Shadow

    /// Shadow presets for elevation levels.
    public enum Shadow {
        /// Light shadow for cards resting on a surface.
        public static func card(_ scheme: ColorScheme = .light) -> ShadowStyle {
            ShadowStyle(
                color: scheme == .dark ? .clear : .black.opacity(0.06),
                radius: 2,
                x: 0,
                y: 1
            )
        }

        /// Medium shadow for elevated elements like selected cards.
        public static func elevated(_ scheme: ColorScheme = .light) -> ShadowStyle {
            ShadowStyle(
                color: scheme == .dark ? .black.opacity(0.3) : .black.opacity(0.1),
                radius: 8,
                x: 0,
                y: 4
            )
        }

        /// Strong shadow for floating elements like FABs and popovers.
        public static func floating(_ scheme: ColorScheme = .light) -> ShadowStyle {
            ShadowStyle(
                color: scheme == .dark ? .black.opacity(0.4) : .black.opacity(0.15),
                radius: 16,
                x: 0,
                y: 8
            )
        }
    }
}

// MARK: - Shadow Style

/// A value type that packages all shadow parameters together.
public struct ShadowStyle: Sendable {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat

    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

/// Applies a ``ShadowStyle`` as a view modifier.
extension View {
    public func shadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

// MARK: - Transaction Type Color Key

/// A lightweight enum used only for color lookups, so that DesignTokens does not
/// depend on the full ``TransactionType`` model from FinanceCore.
public enum TransactionTypeColorKey: Sendable {
    case income
    case expense
    case transfer
}

// MARK: - Cross-platform Color Helper

extension Color {
    /// Creates a Color from a UIKit/AppKit semantic color name.
    /// Falls back to `.clear` if the name is not recognised.
    init(uiColorCompat name: String) {
        #if canImport(UIKit)
        switch name {
        case "systemBackground":
            self.init(uiColor: .systemBackground)
        case "secondarySystemBackground":
            self.init(uiColor: .secondarySystemBackground)
        case "systemGroupedBackground":
            self.init(uiColor: .systemGroupedBackground)
        case "tertiaryLabel":
            self.init(uiColor: .tertiaryLabel)
        default:
            self = .clear
        }
        #elseif canImport(AppKit)
        switch name {
        case "systemBackground":
            self.init(nsColor: .windowBackgroundColor)
        case "secondarySystemBackground":
            self.init(nsColor: .controlBackgroundColor)
        case "systemGroupedBackground":
            self.init(nsColor: .windowBackgroundColor)
        case "tertiaryLabel":
            self.init(nsColor: .tertiaryLabelColor)
        default:
            self = .clear
        }
        #endif
    }
}
