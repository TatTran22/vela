import SwiftUI

/// A loading indicator with optional message text.
///
/// `LoadingView` provides two styles: a simple progress spinner for general
/// use, and a skeleton placeholder row for list loading states.
///
/// Example usage:
/// ```swift
/// LoadingView(message: "Loading transactions…")
/// LoadingView.skeleton(rows: 5)
/// ```
public struct LoadingView: View {
    private let message: String?

    /// Creates a loading view with an optional message.
    ///
    /// - Parameter message: Text displayed below the spinner. Defaults to `nil`.
    public init(message: String? = nil) {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            ProgressView()
                .controlSize(.large)

            if let message {
                Text(message)
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.xxl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message ?? "Loading")
    }
}

// MARK: - Skeleton Placeholder

/// A shimmering placeholder row that mimics a transaction list item.
public struct SkeletonRow: View {
    @State private var isAnimating = false

    public init() {}

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Icon placeholder
            Circle()
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 40, height: 40)

            // Text placeholder
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 120, height: 14)

                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 80, height: 10)
            }

            Spacer()

            // Amount placeholder
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 90, height: 14)
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
        .accessibilityHidden(true)
    }
}

extension LoadingView {
    /// Creates a list of skeleton placeholder rows.
    ///
    /// - Parameter rows: Number of placeholder rows to display. Defaults to 5.
    /// - Returns: A view with shimmer-animated skeleton rows.
    public static func skeleton(rows: Int = 5) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { _ in
                SkeletonRow()
                Divider()
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
}

// MARK: - Previews

#Preview("Spinner") {
    LoadingView(message: "Loading transactions…")
}

#Preview("Spinner Only") {
    LoadingView()
}

#Preview("Skeleton Rows") {
    LoadingView.skeleton(rows: 5)
}

#Preview("Dark Mode") {
    VStack(spacing: DesignTokens.Spacing.xxl) {
        LoadingView(message: "Syncing…")
        Divider()
        LoadingView.skeleton(rows: 3)
    }
    .preferredColorScheme(.dark)
}
