import FinanceCore
import SwiftUI

/// Size variants for AccountIcon display
public enum AccountIconSize: Sendable {
    case small   // 28pt
    case medium  // 40pt
    case large   // 56pt

    /// The diameter of the circular icon background
    var dimension: CGFloat {
        switch self {
        case .small: return 28
        case .medium: return 40
        case .large: return 56
        }
    }

    /// The font size for the SF Symbol icon
    var iconFont: Font {
        switch self {
        case .small: return .caption
        case .medium: return .body
        case .large: return .title2
        }
    }
}

/// Displays an SF Symbol icon in a colored circular background.
///
/// AccountIcon is a foundational UI component for representing accounts visually.
/// It combines an SF Symbol icon with a customizable background color.
///
/// Example usage:
/// ```swift
/// AccountIcon(iconName: "banknote", colorHex: "#34C759", size: .medium)
/// AccountIcon(accountType: .cash, size: .large)
/// ```
public struct AccountIcon: View {
    private let iconName: String
    private let colorHex: String
    private let size: AccountIconSize

    /// Creates an account icon with custom icon name and color.
    ///
    /// - Parameters:
    ///   - iconName: SF Symbol name for the icon.
    ///   - colorHex: Hexadecimal color code (e.g., "#007AFF").
    ///   - size: Size variant for the icon. Defaults to .medium.
    public init(iconName: String, colorHex: String, size: AccountIconSize = .medium) {
        self.iconName = iconName
        self.colorHex = colorHex
        self.size = size
    }

    /// Creates an account icon using default values from an AccountType.
    ///
    /// This convenience initializer uses the account type's default icon and color.
    ///
    /// - Parameters:
    ///   - accountType: The account type to derive icon and color from.
    ///   - size: Size variant for the icon. Defaults to .medium.
    public init(accountType: AccountType, size: AccountIconSize = .medium) {
        self.iconName = accountType.defaultIconName
        self.colorHex = accountType.defaultColorHex
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: colorHex))
                .frame(width: size.dimension, height: size.dimension)
            Image(systemName: iconName)
                .font(size.iconFont)
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true) // Decorative element
    }
}

#Preview("All Sizes") {
    VStack(spacing: DesignTokens.Spacing.lg) {
        HStack(spacing: DesignTokens.Spacing.lg) {
            VStack {
                AccountIcon(accountType: .cash, size: .small)
                Text("Small")
                    .font(.caption)
            }
            VStack {
                AccountIcon(accountType: .bank, size: .medium)
                Text("Medium")
                    .font(.caption)
            }
            VStack {
                AccountIcon(accountType: .creditCard, size: .large)
                Text("Large")
                    .font(.caption)
            }
        }
    }
    .padding()
}

#Preview("All Account Types") {
    ScrollView {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            ForEach(AccountType.allCases, id: \.self) { type in
                HStack(spacing: DesignTokens.Spacing.md) {
                    AccountIcon(accountType: type, size: .medium)
                    Text(type.displayName)
                }
            }
        }
        .padding()
    }
}

#Preview("Custom Icons") {
    HStack(spacing: DesignTokens.Spacing.lg) {
        AccountIcon(iconName: "star.fill", colorHex: "#FFD700", size: .medium)
        AccountIcon(iconName: "heart.fill", colorHex: "#FF3B30", size: .medium)
        AccountIcon(iconName: "flame.fill", colorHex: "#FF9500", size: .medium)
    }
    .padding()
}
