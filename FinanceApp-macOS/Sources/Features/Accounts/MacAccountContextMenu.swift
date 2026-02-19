import FinanceCore
import SwiftUI

/// View modifier for adding context menus to account rows.
///
/// Provides standard account operations including edit, archive, hide, and delete
/// via macOS context menu (right-click). Follows macOS conventions for menu structure
/// and destructive actions.
struct MacAccountContextMenu: ViewModifier {
    /// The account for which to display the context menu
    let account: Account

    /// Callback invoked when the edit action is selected
    let onEdit: () -> Void

    /// Callback invoked when the archive action is selected
    let onArchive: () -> Void

    /// Callback invoked when the hide action is selected
    let onHide: () -> Void

    /// Callback invoked when the delete action is selected
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        content.contextMenu {
            Button { onEdit() } label: {
                Label("Edit Account", systemImage: "pencil")
            }

            Divider()

            Button { onArchive() } label: {
                Label(
                    account.isArchived ? "Unarchive" : "Archive",
                    systemImage: account.isArchived ? "tray.and.arrow.up" : "archivebox"
                )
            }

            Button { onHide() } label: {
                Label(
                    account.isHidden ? "Show" : "Hide",
                    systemImage: account.isHidden ? "eye" : "eye.slash"
                )
            }

            Divider()

            Button(role: .destructive) { onDelete() } label: {
                Label("Delete Account", systemImage: "trash")
            }
        }
    }
}

extension View {
    /// Adds a context menu with standard account operations to the view.
    ///
    /// - Parameters:
    ///   - account: The account for which to display the context menu
    ///   - onEdit: Callback invoked when the edit action is selected
    ///   - onArchive: Callback invoked when the archive action is selected
    ///   - onHide: Callback invoked when the hide action is selected
    ///   - onDelete: Callback invoked when the delete action is selected
    /// - Returns: A view with the account context menu attached
    func accountContextMenu(
        account: Account,
        onEdit: @escaping () -> Void,
        onArchive: @escaping () -> Void,
        onHide: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        modifier(MacAccountContextMenu(
            account: account,
            onEdit: onEdit,
            onArchive: onArchive,
            onHide: onHide,
            onDelete: onDelete
        ))
    }
}
