# FinanceApp — Personal Finance Management Application

## Overview
A cross-platform personal finance management application (macOS + iOS), built with
Swift/SwiftUI. Data syncs via CloudKit. Priority is macOS and iOS development first;
other platforms (iPadOS, watchOS) will be added later.

## Tech Stack
- **Language**: Swift 6.1+, strict concurrency
- **UI Framework**: SwiftUI (primary), AppKit integration when needed on macOS
- **Data**: SwiftData + CoreData (migration path), CloudKit sync
- **Architecture**: MVVM + Clean Architecture, Swift Packages for modularization
- **Dependency Injection**: Swift native (protocol-based), no 3rd party DI
- **Networking**: URLSession + async/await
- **Testing**: XCTest, Swift Testing framework, XCUITest
- **CI/CD**: Xcode Cloud or GitHub Actions
- **Min deployment**: iOS 17.0, macOS 14.0

## Module Structure
- `Packages/FinanceCore/` — Business logic, models, use cases (platform-agnostic)
- `Packages/FinanceData/` — Repository, CoreData/SwiftData stack, CloudKit sync
- `Packages/FinanceUI/` — Shared SwiftUI components, design system
- `FinanceApp-iOS/` — iOS app target
- `FinanceApp-macOS/` — macOS app target

## Common Commands
```bash
# Build all
xcodebuild -scheme FinanceApp-iOS -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild -scheme FinanceApp-macOS -destination 'platform=macOS'

# Test
swift test --package-path Packages/FinanceCore
swift test --package-path Packages/FinanceData
swift test --package-path Packages/FinanceUI

# Lint
swiftlint lint --strict

# Format
swiftformat . --config .swiftformat
```

## Code Rules

### Swift Conventions
- Use Swift strict concurrency (`Sendable`, actors when needed)
- All public APIs must have documentation comments (`///`)
- Naming: camelCase for properties/methods, PascalCase for types
- Prefer value types (struct, enum) over reference types (class)
- Use `Result` type or `throws` for error handling, DO NOT use optionals to hide errors
- No force unwraps (`!`) except `IBOutlet` — use `guard let` or `if let`

### Architecture Rules
- Views MUST NOT contain business logic — only bind to ViewModel
- ViewModels are `@Observable` classes, inject dependencies via init
- Use Cases are protocol + implementation, single responsibility
- Repository pattern for data access — DO NOT call CoreData directly from ViewModel
- Navigation uses `NavigationStack` + `NavigationPath` (iOS), `NavigationSplitView` (macOS)

### File Organization
- 1 main type per file
- File name = type name (e.g., `TransactionListView.swift`)
- Group by feature, not by file type
- Each feature folder: View, ViewModel, Models (if needed)

### Git Workflow
- Branch naming: `feature/`, `fix/`, `refactor/`, `chore/`
- Commit messages in English, conventional commits format
- PRs must have description, linked issue, and passing tests

## References
- Detailed architecture: `docs/ARCHITECTURE.md`
- Data model: `docs/DATA-MODEL.md`
- Design system: `docs/DESIGN-SYSTEM.md`
- Coding conventions: `docs/CONVENTIONS.md`

## Agent Team Configuration
When working with multiple agents, use the following role definitions:
- **ios-engineer**: Focus on `/FinanceApp-iOS/`. SwiftUI, iOS-specific APIs.
- **macos-engineer**: Focus on `/FinanceApp-macOS/`. AppKit integration, macOS UX.
- **shared-core**: Focus on `/Packages/`. Platform-agnostic business logic.
- **data-architect**: Focus on `/Packages/FinanceData/`. CoreData, CloudKit, migrations.
- **test-engineer**: Tests in all `/Tests/` directories.
- **code-reviewer**: Review security, performance, adherence to conventions.
- **ui-designer**: Focus on `/Packages/FinanceUI/`. Design system, reusable components.
