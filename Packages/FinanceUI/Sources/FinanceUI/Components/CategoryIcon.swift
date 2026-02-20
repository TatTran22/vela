import SwiftUI

/// Size variants for CategoryIcon display.
public enum CategoryIconSize: Sendable {
    case small   // 24pt
    case medium  // 32pt
    case large   // 44pt

    /// The diameter of the circular background.
    var dimension: CGFloat {
        switch self {
        case .small: return 24
        case .medium: return 32
        case .large: return 44
        }
    }

    /// The font size for the SF Symbol icon.
    var iconFont: Font {
        switch self {
        case .small: return .system(size: 11)
        case .medium: return .system(size: 14)
        case .large: return .system(size: 20)
        }
    }
}

/// Displays an SF Symbol inside a colored circular background.
///
/// `CategoryIcon` is used wherever a category needs a compact visual indicator —
/// transaction rows, pickers, budget cards, and more.
///
/// Example usage:
/// ```swift
/// CategoryIcon(iconName: "fork.knife", colorHex: "#FF9500", size: .medium)
/// CategoryIcon.placeholder(size: .small)
/// ```
public struct CategoryIcon: View {
    private let iconName: String
    private let colorHex: String
    private let size: CategoryIconSize

    /// Creates a category icon with a specific SF Symbol and color.
    ///
    /// - Parameters:
    ///   - iconName: SF Symbol name for the icon.
    ///   - colorHex: Hexadecimal color code for the circle background.
    ///   - size: Size variant. Defaults to `.medium`.
    public init(iconName: String, colorHex: String, size: CategoryIconSize = .medium) {
        self.iconName = iconName
        self.colorHex = colorHex
        self.size = size
    }

    /// Creates a placeholder icon for unknown or unassigned categories.
    ///
    /// - Parameter size: Size variant. Defaults to `.medium`.
    /// - Returns: A `CategoryIcon` with a question mark icon and gray background.
    public static func placeholder(size: CategoryIconSize = .medium) -> CategoryIcon {
        CategoryIcon(iconName: "questionmark", colorHex: "#8E8E93", size: size)
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
        .accessibilityHidden(true)
    }
}

// MARK: - Previews

#Preview("All Sizes") {
    HStack(spacing: DesignTokens.Spacing.lg) {
        VStack {
            CategoryIcon(iconName: "fork.knife", colorHex: "#FF9500", size: .small)
            Text("Small").font(.caption2)
        }
        VStack {
            CategoryIcon(iconName: "fork.knife", colorHex: "#FF9500", size: .medium)
            Text("Medium").font(.caption2)
        }
        VStack {
            CategoryIcon(iconName: "fork.knife", colorHex: "#FF9500", size: .large)
            Text("Large").font(.caption2)
        }
    }
    .padding()
}

#Preview("Category Examples") {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
        HStack(spacing: DesignTokens.Spacing.md) {
            CategoryIcon(iconName: "fork.knife", colorHex: "#FF9500")
            Text("Food & Drink")
        }
        HStack(spacing: DesignTokens.Spacing.md) {
            CategoryIcon(iconName: "house.fill", colorHex: "#5856D6")
            Text("Housing")
        }
        HStack(spacing: DesignTokens.Spacing.md) {
            CategoryIcon(iconName: "car.fill", colorHex: "#007AFF")
            Text("Transport")
        }
        HStack(spacing: DesignTokens.Spacing.md) {
            CategoryIcon.placeholder()
            Text("Unknown")
        }
    }
    .padding()
}

#Preview("Dark Mode") {
    HStack(spacing: DesignTokens.Spacing.lg) {
        CategoryIcon(iconName: "heart.fill", colorHex: "#FF2D55", size: .large)
        CategoryIcon(iconName: "briefcase.fill", colorHex: "#34C759", size: .large)
        CategoryIcon.placeholder(size: .large)
    }
    .padding()
    .background(.background)
    .preferredColorScheme(.dark)
}
