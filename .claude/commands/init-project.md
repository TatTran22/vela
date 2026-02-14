---
description: "Khởi tạo project FinanceApp — Xcode workspace, Swift Packages, cấu trúc thư mục, git setup"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Init: Project Setup

## Đọc Context Trước
1. `CLAUDE.md` — tech stack, module structure
2. `docs/ARCHITECTURE.md`

## Tasks

### 1. Xcode Workspace
- Create `FinanceApp.xcworkspace`
- iOS target: `FinanceApp-iOS` (iOS 17.0+, iPhone + iPad)
- macOS target: `FinanceApp-macOS` (macOS 14.0+)

### 2. Swift Packages
Create 3 local packages:

**Packages/FinanceCore/Package.swift**:
- Platforms: iOS 17, macOS 14
- Products: library "FinanceCore"
- Dependencies: none (pure Swift)
- Targets: FinanceCore, FinanceCoreTests

**Packages/FinanceData/Package.swift**:
- Platforms: iOS 17, macOS 14
- Products: library "FinanceData"
- Dependencies: FinanceCore (local)
- Targets: FinanceData, FinanceDataTests

**Packages/FinanceUI/Package.swift**:
- Platforms: iOS 17, macOS 14
- Products: library "FinanceUI"
- Dependencies: FinanceCore (local)
- Targets: FinanceUI, FinanceUITests

### 3. Directory Structure
```
FinanceApp-iOS/
  Sources/
    App/                  # @main, AppDelegate
    Features/
      Dashboard/          # Views, ViewModels
      Transactions/
      Accounts/
      Categories/
      Reports/
      Settings/
      Onboarding/
    Navigation/           # Router, NavigationPath
    Extensions/
  Resources/
    Assets.xcassets
    Localizable.xcstrings
  Widget/                 # WidgetKit extension

FinanceApp-macOS/
  Sources/
    App/
    Features/
      Dashboard/
      Transactions/
      Accounts/
      Categories/
      Reports/
      Settings/
    Navigation/
    Extensions/
  Resources/

Packages/FinanceCore/
  Sources/FinanceCore/
    Models/
    UseCases/
    Protocols/
    Utilities/
  Tests/FinanceCoreTests/

Packages/FinanceData/
  Sources/FinanceData/
    Entities/
    Repositories/
    DataStack/
    CloudKit/
  Tests/FinanceDataTests/

Packages/FinanceUI/
  Sources/FinanceUI/
    Components/
    Tokens/
    Extensions/
  Tests/FinanceUITests/
```

### 4. Base Configuration
- Swift 6.1 strict concurrency
- SwiftLint config (`.swiftlint.yml`)
- SwiftFormat config (`.swiftformat`)
- `.gitignore` for Xcode projects

### 5. App Entry Points
- iOS: `@main struct FinanceApp_iOS: App`
- macOS: `@main struct FinanceApp_macOS: App`
- Shared `ModelContainer` setup in each

### 6. Build Scripts
- `scripts/build.sh` — build both targets
- `scripts/test.sh` — run all package tests
- `scripts/lint.sh` — swiftlint + swiftformat check

### 7. Git Setup
- Initialize git repo (if not exists)
- Add `.gitignore`
- Initial commit: "chore: initialize project structure"

## Definition of Done
- [ ] Both iOS and macOS targets build successfully
- [ ] All 3 packages build and tests run (even if empty)
- [ ] SwiftLint passes with 0 errors
- [ ] Directory structure matches specification
- [ ] Scripts executable and working
