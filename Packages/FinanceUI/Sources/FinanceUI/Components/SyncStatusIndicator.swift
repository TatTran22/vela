import SwiftUI

/// The possible sync states for CloudKit synchronization.
public enum SyncStatus: Sendable {
    case synced
    case syncing
    case offline
    case error
}

/// A compact indicator showing the current CloudKit sync status.
///
/// Displays a colored dot with optional label text. The syncing state
/// includes a rotation animation.
///
/// Example usage:
/// ```swift
/// SyncStatusIndicator(status: .synced)
/// SyncStatusIndicator(status: .syncing, showLabel: true)
/// ```
public struct SyncStatusIndicator: View {
    private let status: SyncStatus
    private let showLabel: Bool

    @State private var isRotating = false

    /// Creates a sync status indicator.
    ///
    /// - Parameters:
    ///   - status: The current sync status.
    ///   - showLabel: Whether to show a text label next to the dot. Defaults to `false`.
    public init(status: SyncStatus, showLabel: Bool = false) {
        self.status = status
        self.showLabel = showLabel
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            statusIcon

            if showLabel {
                Text(label)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(color)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .synced:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(color)

        case .syncing:
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 12))
                .foregroundStyle(color)
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isRotating)
                .onAppear { isRotating = true }

        case .offline:
            Image(systemName: "circle")
                .font(.system(size: 12))
                .foregroundStyle(color)

        case .error:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(color)
        }
    }

    // MARK: - Properties

    private var color: Color {
        switch status {
        case .synced: return DesignTokens.Colors.success
        case .syncing: return DesignTokens.Colors.info
        case .offline: return .gray
        case .error: return DesignTokens.Colors.error
        }
    }

    private var label: String {
        switch status {
        case .synced: return "Synced"
        case .syncing: return "Syncing"
        case .offline: return "Offline"
        case .error: return "Error"
        }
    }

    private var accessibilityLabel: String {
        switch status {
        case .synced: return "Sync status: synced"
        case .syncing: return "Sync status: syncing in progress"
        case .offline: return "Sync status: offline"
        case .error: return "Sync status: error"
        }
    }
}

// MARK: - Previews

#Preview("All States") {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
        SyncStatusIndicator(status: .synced, showLabel: true)
        SyncStatusIndicator(status: .syncing, showLabel: true)
        SyncStatusIndicator(status: .offline, showLabel: true)
        SyncStatusIndicator(status: .error, showLabel: true)
    }
    .padding()
}

#Preview("Dots Only") {
    HStack(spacing: DesignTokens.Spacing.md) {
        SyncStatusIndicator(status: .synced)
        SyncStatusIndicator(status: .syncing)
        SyncStatusIndicator(status: .offline)
        SyncStatusIndicator(status: .error)
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
        SyncStatusIndicator(status: .synced, showLabel: true)
        SyncStatusIndicator(status: .syncing, showLabel: true)
        SyncStatusIndicator(status: .offline, showLabel: true)
        SyncStatusIndicator(status: .error, showLabel: true)
    }
    .padding()
    .background(.background)
    .preferredColorScheme(.dark)
}
