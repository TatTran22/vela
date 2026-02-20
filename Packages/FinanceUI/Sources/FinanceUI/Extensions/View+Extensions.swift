import SwiftUI

// MARK: - Card Style

extension View {
    /// Applies a card-style background with rounded corners and shadow.
    public func cardStyle() -> some View {
        self
            .padding(DesignTokens.Spacing.lg)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Typography Modifiers

extension View {
    /// Applies the hero amount typography style.
    public func financeHeroAmount() -> some View {
        self.font(DesignTokens.Typography.heroAmount)
            .monospacedDigit()
    }

    /// Applies the heading typography style.
    public func financeHeading() -> some View {
        self.font(DesignTokens.Typography.heading)
    }

    /// Applies the body typography style.
    public func financeBody() -> some View {
        self.font(DesignTokens.Typography.body)
    }

    /// Applies the caption typography style.
    public func financeCaption() -> some View {
        self.font(DesignTokens.Typography.caption)
    }
}

// MARK: - Platform Adaptations (iOS)

#if canImport(UIKit)
extension View {
    /// Triggers haptic feedback of the specified type.
    ///
    /// - Parameter type: The feedback style to use.
    public func hapticFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) -> some View {
        self.modifier(HapticFeedbackModifier(type: type))
    }
}

/// A modifier that fires a haptic feedback notification when it appears.
private struct HapticFeedbackModifier: ViewModifier {
    let type: UINotificationFeedbackGenerator.FeedbackType

    func body(content: Content) -> some View {
        content.onAppear {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(type)
        }
    }
}
#endif

// MARK: - Platform Adaptations (macOS)

#if os(macOS)
extension View {
    /// Applies a consistent toolbar style for macOS windows.
    public func financeToolbarStyle() -> some View {
        self.toolbarBackgroundVisibility(.visible, for: .windowToolbar)
    }
}
#endif

// MARK: - Adaptive Presentation

extension View {
    /// Presents content as a sheet on compact sizes and a popover on regular sizes.
    ///
    /// - Parameters:
    ///   - isPresented: Binding controlling presentation.
    ///   - content: The content to present.
    public func adaptiveSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(AdaptiveSheetModifier(isPresented: isPresented, sheetContent: content))
    }
}

/// Presents as a sheet on compact width and popover on regular width.
private struct AdaptiveSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    @ViewBuilder var sheetContent: () -> SheetContent

    @Environment(\.horizontalSizeClass) private var sizeClass

    func body(content: Content) -> some View {
        #if os(iOS)
        if sizeClass == .regular {
            content.popover(isPresented: $isPresented) {
                sheetContent()
            }
        } else {
            content.sheet(isPresented: $isPresented) {
                sheetContent()
            }
        }
        #else
        content.sheet(isPresented: $isPresented) {
            sheetContent()
        }
        #endif
    }
}

// MARK: - Color Hex Extensions

extension Color {
    /// Creates a color from a hexadecimal string.
    ///
    /// Supports both 6-digit (#RRGGBB) and 8-digit (#RRGGBBAA) hex formats.
    /// The hash symbol (#) is optional.
    ///
    /// - Parameter hex: The hexadecimal color string (e.g., "#FF5733" or "FF5733").
    /// - Returns: A Color instance, or white if the hex string is invalid.
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Converts a SwiftUI Color to a hexadecimal string.
    ///
    /// - Returns: A hex string (e.g., "#FF5733"), or nil if conversion fails.
    public func toHex() -> String? {
        #if canImport(UIKit)
        typealias NativeColor = UIColor
        #elseif canImport(AppKit)
        typealias NativeColor = NSColor
        #endif

        let color = NativeColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        #if canImport(UIKit)
        guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        #elseif canImport(AppKit)
        guard let rgbColor = color.usingColorSpace(.sRGB) else { return nil }
        rgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif

        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0
        return String(format: "#%06X", rgb)
    }
}
