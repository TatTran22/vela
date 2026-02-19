import SwiftUI

extension View {
    /// Applies a card-style background with rounded corners and shadow
    public func cardStyle() -> some View {
        self
            .padding(DesignTokens.Spacing.lg)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

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
