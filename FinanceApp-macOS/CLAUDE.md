# macOS Target Context

## macOS-Specific Notes
- Use `NavigationSplitView` with 3-column layout (sidebar, content, detail)
- Support keyboard shortcuts for all primary actions (Cmd+N, Cmd+S, Cmd+Delete, etc.)
- Menu bar integration for quick-add transactions
- Multi-window support via `WindowGroup` and `Window`
- Use `Settings` scene for preferences window
- AppKit integration via `NSViewRepresentable` when SwiftUI lacks macOS capability

## Layout
- Sidebar: Account list, navigation categories
- Content: Transaction/budget list with sorting and filtering
- Detail: Selected item detail with edit-in-place
- Minimum window size: 900x600
- Support full-screen and split-screen modes

## macOS Design Guidelines
- Follow Apple Human Interface Guidelines for macOS
- Use `Menu` and contextual menus (right-click) extensively
- Toolbar with customizable items via `.toolbar`
- Table views with sortable columns for transaction lists
- Drag-and-drop for categorization and file import (CSV, OFX)
- Touch Bar support if applicable

## Keyboard Shortcuts
```swift
.keyboardShortcut("n", modifiers: .command)         // New transaction
.keyboardShortcut("s", modifiers: .command)          // Save
.keyboardShortcut(.delete, modifiers: .command)      // Delete
.keyboardShortcut("f", modifiers: .command)          // Search/filter
.keyboardShortcut("i", modifiers: [.command, .shift]) // Import
.keyboardShortcut(",", modifiers: .command)           // Preferences
```

## Platform Differences from iOS
- No tab bar — use sidebar navigation instead
- Use `confirmationDialog` styled for macOS (appears as popover near source)
- File import/export via `fileImporter`/`fileExporter` modifiers
- Printing support via `PrintingView` for reports
- Status bar item for quick balance check (optional)
