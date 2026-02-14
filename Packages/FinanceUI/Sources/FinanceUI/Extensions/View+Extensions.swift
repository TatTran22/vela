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
