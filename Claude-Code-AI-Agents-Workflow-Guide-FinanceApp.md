# Hướng Dẫn Thiết Lập Workflow Claude Code AI Agents
## Ứng Dụng Quản Lý Tài Chính Cá Nhân — macOS & iOS

---

## Mục Lục

1. [Tổng Quan Kiến Trúc Agent](#1-tổng-quan-kiến-trúc-agent)
2. [Cấu Trúc Thư Mục Dự Án](#2-cấu-trúc-thư-mục-dự-án)
3. [CLAUDE.md — Bộ Nhớ Dự Án](#3-claudemd--bộ-nhớ-dự-án)
4. [settings.json — Cấu Hình Hệ Thống](#4-settingsjson--cấu-hình-hệ-thống)
5. [Subagents — Đội Ngũ Agent Chuyên Biệt](#5-subagents--đội-ngũ-agent-chuyên-biệt)
6. [Slash Commands — Lệnh Tùy Chỉnh](#6-slash-commands--lệnh-tùy-chỉnh)
7. [Skills — Kỹ Năng Chuyên Sâu](#7-skills--kỹ-năng-chuyên-sâu)
8. [Hooks — Tự Động Hóa](#8-hooks--tự-động-hóa)
9. [MCP Servers — Kết Nối Bên Ngoài](#9-mcp-servers--kết-nối-bên-ngoài)
10. [Workflow Vận Hành Hàng Ngày](#10-workflow-vận-hành-hàng-ngày)
11. [Agent Teams — Phát Triển Song Song](#11-agent-teams--phát-triển-song-song)
12. [Mẹo & Lưu Ý Quan Trọng](#12-mẹo--lưu-ý-quan-trọng)

---

## 1. Tổng Quan Kiến Trúc Agent

### Hệ Thống Phân Tầng

```
BẠN (Product Owner / Tech Lead)
 │
 ├─ Claude Code (Main Agent - Orchestrator)
 │   ├─ Đọc CLAUDE.md để hiểu dự án
 │   ├─ Đọc settings.json để biết quyền hạn
 │   ├─ Phân phối task cho subagents
 │   └─ Tổng hợp kết quả
 │
 ├─ Subagent: ios-engineer      ← SwiftUI, iOS native
 ├─ Subagent: macos-engineer    ← macOS AppKit/SwiftUI
 ├─ Subagent: shared-core       ← Swift Package logic dùng chung
 ├─ Subagent: data-architect    ← CoreData, CloudKit, schema
 ├─ Subagent: code-reviewer     ← Review code, security audit
 ├─ Subagent: test-engineer     ← Unit test, UI test, integration
 └─ Subagent: ui-designer       ← Design system, SwiftUI components
```

### Nguyên Tắc Hoạt Động

- **Main Agent** là người điều phối (orchestrator) — nhận yêu cầu từ bạn, phân tích, và giao việc cho subagent phù hợp.
- **Subagents** chạy trong context window riêng biệt, có prompt chuyên biệt, và trả kết quả về cho Main Agent.
- **Subagents không thể spawn subagent khác** — nếu cần chuỗi công việc, Main Agent sẽ chain các subagent tuần tự.
- **Agent Teams** cho phép chạy nhiều agent song song trên các git worktree khác nhau.

---

## 2. Cấu Trúc Thư Mục Dự Án

```
FinanceApp/
├── CLAUDE.md                          # Bộ nhớ chính của dự án
├── CLAUDE.local.md                    # Ghi chú cá nhân (gitignored)
├── .mcp.json                          # MCP server config
│
├── .claude/
│   ├── settings.json                  # Hooks, permissions, env
│   ├── settings.local.json            # Override cá nhân (gitignored)
│   │
│   ├── agents/                        # Subagents chuyên biệt
│   │   ├── ios-engineer.md
│   │   ├── macos-engineer.md
│   │   ├── shared-core.md
│   │   ├── data-architect.md
│   │   ├── code-reviewer.md
│   │   ├── test-engineer.md
│   │   └── ui-designer.md
│   │
│   ├── commands/                      # Slash commands
│   │   ├── plan.md                    # /plan — lập kế hoạch feature
│   │   ├── implement.md               # /implement — triển khai feature
│   │   ├── review.md                  # /review — review code
│   │   ├── test.md                    # /test — chạy test suite
│   │   ├── pr.md                      # /pr — tạo pull request
│   │   ├── fix-issue.md               # /fix-issue — sửa bug
│   │   └── daily.md                   # /daily — báo cáo hàng ngày
│   │
│   └── skills/                        # Skills chuyên sâu
│       ├── swiftui-patterns/
│       │   └── SKILL.md
│       ├── coredata-cloudkit/
│       │   └── SKILL.md
│       ├── finance-domain/
│       │   └── SKILL.md
│       └── apple-guidelines/
│           └── SKILL.md
│
├── Packages/
│   ├── FinanceCore/                   # Swift Package — business logic
│   │   ├── Sources/
│   │   └── Tests/
│   ├── FinanceUI/                     # Swift Package — shared UI
│   │   ├── Sources/
│   │   └── Tests/
│   └── FinanceData/                   # Swift Package — data layer
│       ├── Sources/
│       └── Tests/
│
├── FinanceApp-iOS/                    # iOS app target
│   ├── App/
│   ├── Views/
│   └── Resources/
│
├── FinanceApp-macOS/                  # macOS app target
│   ├── App/
│   ├── Views/
│   └── Resources/
│
├── docs/
│   ├── ARCHITECTURE.md                # Kiến trúc tổng quan
│   ├── DATA-MODEL.md                  # Mô hình dữ liệu
│   ├── API-SPEC.md                    # API specification
│   ├── DESIGN-SYSTEM.md              # Design tokens & components
│   └── CONVENTIONS.md                 # Coding conventions
│
└── scripts/
    ├── build.sh
    ├── test.sh
    └── lint.sh
```

---

## 3. CLAUDE.md — Bộ Nhớ Dự Án

Đây là file quan trọng nhất. Claude Code đọc file này đầu tiên khi bắt đầu session.

### File: `CLAUDE.md`

```markdown
# FinanceApp — Ứng Dụng Quản Lý Tài Chính Cá Nhân

## Tổng Quan
Ứng dụng quản lý tài chính cá nhân đa nền tảng (macOS + iOS), xây dựng bằng
Swift/SwiftUI. Dữ liệu đồng bộ qua CloudKit. Ưu tiên phát triển macOS và iOS
trước, các nền tảng khác (iPadOS, watchOS) sẽ bổ sung sau.

## Tech Stack
- **Ngôn ngữ**: Swift 6.1+, strict concurrency
- **UI Framework**: SwiftUI (primary), AppKit integration khi cần trên macOS
- **Data**: SwiftData + CoreData (migration path), CloudKit sync
- **Architecture**: MVVM + Clean Architecture, Swift Packages cho module hóa
- **Dependency Injection**: Swift native (protocol-based), không dùng 3rd party DI
- **Networking**: URLSession + async/await
- **Testing**: XCTest, Swift Testing framework, XCUITest
- **CI/CD**: Xcode Cloud hoặc GitHub Actions
- **Min deployment**: iOS 17.0, macOS 14.0

## Cấu Trúc Module
- `Packages/FinanceCore/` — Business logic, models, use cases (platform-agnostic)
- `Packages/FinanceData/` — Repository, CoreData/SwiftData stack, CloudKit sync
- `Packages/FinanceUI/` — Shared SwiftUI components, design system
- `FinanceApp-iOS/` — iOS app target
- `FinanceApp-macOS/` — macOS app target

## Lệnh Thường Dùng
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

## Quy Tắc Code

### Swift Conventions
- Sử dụng Swift strict concurrency (`Sendable`, actors khi cần)
- Tất cả public API phải có documentation comment (`///`)
- Naming: camelCase cho properties/methods, PascalCase cho types
- Ưu tiên value types (struct, enum) hơn reference types (class)
- Sử dụng `Result` type hoặc `throws` cho error handling, KHÔNG dùng optional
  để che error
- Không force unwrap (`!`) trừ `IBOutlet` — dùng `guard let` hoặc `if let`

### Architecture Rules
- Views KHÔNG chứa business logic — chỉ binding đến ViewModel
- ViewModels là `@Observable` class, inject dependencies qua init
- Use Cases là protocol + implementation, single responsibility
- Repository pattern cho data access — KHÔNG gọi CoreData trực tiếp từ ViewModel
- Navigation dùng `NavigationStack` + `NavigationPath` (iOS), `NavigationSplitView` (macOS)

### File Organization
- 1 type chính per file
- File name = type name (VD: `TransactionListView.swift`)
- Group theo feature, không theo loại file
- Mỗi feature folder: View, ViewModel, Models (nếu cần)

### Git Workflow
- Branch naming: `feature/`, `fix/`, `refactor/`, `chore/`
- Commit message tiếng Anh, conventional commits format
- PR phải có description, linked issue, và tests pass

## Tham Khảo
- Kiến trúc chi tiết: `docs/ARCHITECTURE.md`
- Mô hình dữ liệu: `docs/DATA-MODEL.md`
- Design system: `docs/DESIGN-SYSTEM.md`
- Coding conventions: `docs/CONVENTIONS.md`

## Agent Team Configuration
Khi làm việc với nhiều agents, sử dụng role definitions sau:
- **ios-engineer**: Focus `/FinanceApp-iOS/`. SwiftUI, iOS-specific APIs.
- **macos-engineer**: Focus `/FinanceApp-macOS/`. AppKit integration, macOS UX.
- **shared-core**: Focus `/Packages/`. Platform-agnostic business logic.
- **data-architect**: Focus `/Packages/FinanceData/`. CoreData, CloudKit, migrations.
- **test-engineer**: Tests trong tất cả `/Tests/` directories.
- **code-reviewer**: Review security, performance, adherence to conventions.
- **ui-designer**: Focus `/Packages/FinanceUI/`. Design system, reusable components.
```

### File: `FinanceApp-iOS/CLAUDE.md` (Context bổ sung cho thư mục con)

```markdown
# iOS Target Context

## Đặc Thù iOS
- Sử dụng `NavigationStack` cho navigation (KHÔNG dùng NavigationView deprecated)
- Support Dynamic Type, Dark Mode, và VoiceOver
- Widget Extension cho iOS widgets (WidgetKit)
- App Intents cho Shortcuts và Siri

## Design Guidelines
- Tuân thủ Apple Human Interface Guidelines cho iOS
- Bottom tab bar cho navigation chính
- Sheet presentation cho create/edit flows
- Swipe actions cho list items (delete, archive)
```

---

## 4. settings.json — Cấu Hình Hệ Thống

### File: `.claude/settings.json`

```json
{
  "permissions": {
    "allow": [
      "Bash(swift build:*)",
      "Bash(swift test:*)",
      "Bash(xcodebuild:*)",
      "Bash(swiftlint:*)",
      "Bash(swiftformat:*)",
      "Bash(git add:*)",
      "Bash(git status:*)",
      "Bash(git commit:*)",
      "Bash(git branch:*)",
      "Bash(git checkout:*)",
      "Bash(git log:*)",
      "Bash(git diff:*)",
      "Bash(git push:*)",
      "Bash(git pull:*)",
      "Bash(git stash:*)",
      "Bash(git merge:*)",
      "Bash(cat:*)",
      "Bash(ls:*)",
      "Bash(find:*)",
      "Bash(grep:*)",
      "Bash(wc:*)",
      "Bash(head:*)",
      "Bash(tail:*)",
      "Bash(mkdir:*)",
      "Bash(cp:*)",
      "Bash(mv:*)",
      "Bash(gh pr:*)",
      "Bash(gh issue:*)",
      "Read",
      "Write",
      "Edit",
      "Glob",
      "Grep"
    ],
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Read(./**/Credentials.swift)",
      "Bash(rm -rf:*)",
      "Bash(sudo:*)",
      "Bash(curl:*)",
      "Bash(wget:*)"
    ]
  },
  "env": {
    "DEVELOPER_DIR": "/Applications/Xcode.app/Contents/Developer",
    "PROJECT_ROOT": "${CLAUDE_PROJECT_DIR}"
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "branch=$(git branch --show-current 2>/dev/null); [ \"$branch\" != \"main\" ] && [ \"$branch\" != \"master\" ] || { echo '{\"block\": true, \"message\": \"Cannot edit on main/master branch. Create a feature branch first.\"}' >&2; exit 2; }",
            "timeout": 5
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write(*.swift)|Edit(*.swift)",
        "hooks": [
          {
            "type": "command",
            "command": "swiftformat \"$CLAUDE_FILE_PATH\" --config .swiftformat 2>/dev/null || true",
            "timeout": 15
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Claude Code task completed\" with title \"FinanceApp\"'",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

### File: `~/.claude/settings.json` (Global — áp dụng mọi dự án)

```json
{
  "permissions": {
    "allow": [
      "Bash(git status:*)",
      "Bash(git log:*)",
      "Bash(git diff:*)",
      "Read",
      "Glob",
      "Grep"
    ]
  },
  "env": {
    "LANG": "en_US.UTF-8"
  }
}
```

---

## 5. Subagents — Đội Ngũ Agent Chuyên Biệt

Mỗi subagent là một file `.md` trong `.claude/agents/` với YAML frontmatter để cấu hình.

### File: `.claude/agents/ios-engineer.md`

```markdown
---
name: ios-engineer
description: >
  iOS development specialist. Use for building iOS-specific UI, 
  navigation, iOS system integrations (WidgetKit, App Intents, 
  notifications), and iOS-specific SwiftUI patterns. Focus on 
  FinanceApp-iOS/ directory.
tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
model: sonnet
memory: project
---

You are a senior iOS engineer specializing in SwiftUI and modern iOS development.

## Your Responsibilities
- Build iOS-specific views and navigation flows
- Implement iOS system integrations (WidgetKit, App Intents, StoreKit)
- Ensure iOS HIG compliance
- Handle iOS-specific lifecycle (scenes, background tasks)

## Key Constraints
- Target: iOS 17.0+
- Use `NavigationStack`, NOT deprecated `NavigationView`
- All views must support Dynamic Type, Dark Mode, VoiceOver
- Use `@Observable` macro (NOT `ObservableObject`)
- Follow MVVM pattern — Views only bind to ViewModels
- Import shared code from `FinanceCore`, `FinanceUI`, `FinanceData` packages

## Working Directory Focus
- Primary: `FinanceApp-iOS/`
- Reference: `Packages/FinanceUI/` for shared components
- Reference: `Packages/FinanceCore/` for business logic protocols

## Before Writing Code
1. Read the relevant feature's existing code
2. Check `docs/DESIGN-SYSTEM.md` for design tokens
3. Check `docs/CONVENTIONS.md` for naming patterns
4. Verify imports from shared packages exist

## Code Style
- Vietnamese comments for complex business logic, English for code documentation
- Every public API needs `///` doc comments
- Prefer composition over inheritance
- Use Swift's structured concurrency (async/await, actors)
```

### File: `.claude/agents/macos-engineer.md`

```markdown
---
name: macos-engineer
description: >
  macOS development specialist. Use for building macOS-specific UI, 
  menu bar integration, keyboard shortcuts, multi-window support, 
  and macOS-specific patterns. Focus on FinanceApp-macOS/ directory.
tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
model: sonnet
memory: project
---

You are a senior macOS engineer with deep expertise in SwiftUI for macOS and AppKit integration.

## Your Responsibilities
- Build macOS-specific views with `NavigationSplitView` patterns
- Implement macOS features: menu bar, keyboard shortcuts, toolbar
- Handle multi-window and sidebar navigation
- AppKit integration when SwiftUI is insufficient (NSViewRepresentable)

## Key Constraints
- Target: macOS 14.0+
- Use `NavigationSplitView` for 2/3 column layouts
- Support keyboard navigation and shortcuts (`.keyboardShortcut()`)
- Respect macOS conventions: menu bar items, preferences window
- Implement proper window management

## macOS-Specific Patterns
- Settings/Preferences: Use `Settings` scene (SwiftUI native)
- Toolbar: Use `.toolbar` modifier with proper placement
- Sidebar: `NavigationSplitView` with `.navigationSplitViewStyle(.balanced)`
- Table views: Use `Table` for macOS data grids
- Drag and drop: Native macOS D&D for import/export
```

### File: `.claude/agents/shared-core.md`

```markdown
---
name: shared-core
description: >
  Platform-agnostic business logic engineer. Use for building shared 
  models, use cases, domain logic, and protocols that both iOS and 
  macOS targets consume. Focus on Packages/ directory.
tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
model: sonnet
memory: project
---

You are a domain-driven design expert building the shared core of a finance application.

## Your Responsibilities
- Define domain models (Transaction, Account, Budget, Category, etc.)
- Implement use cases as protocol + implementation pairs
- Build repository protocols for data access abstraction
- Create shared utilities and extensions
- Ensure all code is platform-agnostic (no UIKit/AppKit imports)

## Module Structure
- `FinanceCore`: Models, Use Cases, Protocols, Business Rules
- `FinanceData`: Repository implementations, CoreData/SwiftData stack
- `FinanceUI`: Shared SwiftUI components, design tokens

## Key Constraints
- ZERO platform-specific imports (no UIKit, AppKit, SwiftUI only in FinanceUI)
- All models must be `Sendable` and `Codable`
- Use cases follow single responsibility principle
- Repository pattern with protocol abstraction
- Comprehensive unit tests for all business logic

## Domain Model Guidelines
- Use value types (struct) for models
- Use enums for finite states (TransactionType, AccountType)
- Amount handling: Use `Decimal` type, NEVER `Double` for money
- Date handling: Always use `Date` with explicit `Calendar` and `TimeZone`
- Currency: ISO 4217 codes, support multi-currency
```

### File: `.claude/agents/data-architect.md`

```markdown
---
name: data-architect
description: >
  Data layer specialist. Use for CoreData/SwiftData schema design, 
  migrations, CloudKit sync setup, data persistence optimization, 
  and query performance. Focus on Packages/FinanceData/.
tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
model: sonnet
memory: project
---

You are a data architecture expert specializing in Apple's persistence frameworks.

## Your Responsibilities
- Design and evolve CoreData/SwiftData schema
- Implement CloudKit sync with conflict resolution
- Write data migrations (lightweight and heavy)
- Optimize fetch requests and batch operations
- Design caching strategies

## Key Constraints
- Primary persistence: SwiftData (with CoreData compatibility layer)
- Sync: CloudKit (CKContainer with private database)
- All operations must be async and Sendable-safe
- Batch operations for import/export (> 100 records)
- Support offline-first: full functionality without network

## Data Schema Principles
- Normalize where it reduces duplication
- Denormalize where it improves read performance
- Every entity needs: `id` (UUID), `createdAt`, `updatedAt`
- Soft delete with `deletedAt` field for CloudKit sync
- Indexes on frequently queried fields

## CloudKit Sync Rules
- Use `NSPersistentCloudKitContainer`
- Handle `.conflictMerge` policy
- Monitor sync status with `NSPersistentCloudKitContainer.Event`
- Test with CloudKit Dashboard
```

### File: `.claude/agents/code-reviewer.md`

```markdown
---
name: code-reviewer
description: >
  Code review specialist. Use for reviewing PRs, auditing security, 
  checking performance, and ensuring code quality standards. 
  Read-only access — does not modify code directly.
tools:
  - Read
  - Glob
  - Grep
model: sonnet
memory: project
---

You are a meticulous senior code reviewer for a finance application.

## Your Review Checklist

### Security (Critical for Finance App)
- [ ] No hardcoded secrets, API keys, or credentials
- [ ] Input validation on all user inputs
- [ ] SQL injection prevention (parameterized queries)
- [ ] Keychain usage for sensitive data storage
- [ ] Certificate pinning for network requests
- [ ] No sensitive data in logs or crash reports
- [ ] Biometric authentication where needed

### Swift Quality
- [ ] No force unwraps (`!`) except IBOutlets
- [ ] Proper error handling (no empty catch blocks)
- [ ] Memory management: no retain cycles (weak/unowned where needed)
- [ ] Swift concurrency: Sendable compliance, no data races
- [ ] Appropriate access control (internal by default, public when needed)

### Architecture
- [ ] MVVM compliance: no business logic in Views
- [ ] Dependency injection via init (no service locators)
- [ ] Single responsibility per type
- [ ] Protocol abstraction for testability

### Performance
- [ ] No N+1 query problems
- [ ] Lazy loading for large lists
- [ ] Image caching
- [ ] Background thread for heavy computation
- [ ] Proper use of `@State`, `@Binding`, `@Environment`

### Finance-Specific
- [ ] Decimal type for all monetary values
- [ ] Explicit currency handling
- [ ] Rounding rules documented and consistent
- [ ] Date/timezone handling correct

## Output Format
Provide review as categorized findings:
🔴 CRITICAL — Must fix before merge
🟡 WARNING — Should fix, can be follow-up
🟢 SUGGESTION — Nice to have improvements
📝 NOTE — Informational observations
```

### File: `.claude/agents/test-engineer.md`

```markdown
---
name: test-engineer
description: >
  Testing specialist. Use for writing unit tests, UI tests, 
  integration tests, and test infrastructure. Focus on all 
  Tests/ directories.
tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
model: sonnet
memory: project
---

You are a test engineering expert focused on comprehensive test coverage.

## Testing Strategy

### Unit Tests (FinanceCore, FinanceData)
- Test every public API
- Test edge cases: empty data, max values, currency boundaries
- Test error paths
- Use AAA pattern: Arrange, Act, Assert
- Mock dependencies using protocols

### UI Tests (FinanceApp-iOS, FinanceApp-macOS)  
- Critical user flows: add transaction, view balance, create budget
- Accessibility testing
- Dark mode / light mode
- Dynamic Type sizes

### Integration Tests
- CoreData CRUD operations
- CloudKit sync simulation
- Data migration between schema versions

## Test Patterns
```swift
// Preferred test structure
@Test("Transaction amount should be positive for income")
func incomeTransactionAmount() throws {
    // Arrange
    let account = Account.mock()
    
    // Act
    let transaction = Transaction(
        amount: Decimal(100),
        type: .income,
        account: account
    )
    
    // Assert
    #expect(transaction.amount > 0)
    #expect(transaction.type == .income)
}
```

## Key Constraints
- Use Swift Testing framework (preferred) alongside XCTest
- Test file naming: `[TypeName]Tests.swift`
- Minimum 80% coverage for FinanceCore
- All bug fixes must include regression test
- Mock data factory: use `.mock()` static methods
```

### File: `.claude/agents/ui-designer.md`

```markdown
---
name: ui-designer
description: >
  Design system and UI component specialist. Use for creating 
  reusable SwiftUI components, design tokens, theming, and 
  ensuring visual consistency across iOS and macOS.
  Focus on Packages/FinanceUI/.
tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
model: sonnet
memory: project
---

You are a design system engineer building a cohesive UI library for a finance app.

## Your Responsibilities
- Define and maintain design tokens (colors, typography, spacing)
- Build reusable SwiftUI components
- Ensure cross-platform consistency (iOS + macOS)
- Implement adaptive layouts
- Accessibility compliance (VoiceOver, Dynamic Type)

## Design Token Structure
```swift
// Colors
enum FinanceColors {
    static let income = Color("Income")       // Green
    static let expense = Color("Expense")     // Red  
    static let transfer = Color("Transfer")   // Blue
    static let background = Color("Background")
    static let cardBackground = Color("CardBackground")
}

// Typography  
enum FinanceTypography {
    static let largeAmount = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let amount = Font.system(.title2, design: .rounded, weight: .semibold)
    static let body = Font.body
    static let caption = Font.caption
}

// Spacing
enum FinanceSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}
```

## Component Guidelines
- Every component supports Dark Mode
- Every component supports Dynamic Type
- Add `.accessibilityLabel()` and `.accessibilityHint()`
- Use `@Environment(\.colorScheme)` for conditional styling
- Preview with multiple configurations
```

---

## 6. Slash Commands — Lệnh Tùy Chỉnh

Slash commands cho phép bạn kích hoạt workflow đã định nghĩa sẵn bằng `/command-name`.

### File: `.claude/commands/plan.md`

```markdown
---
description: Lập kế hoạch chi tiết cho một feature mới
---

Tôi cần bạn lập kế hoạch triển khai feature sau: $ARGUMENTS

## Quy Trình
1. Đọc `docs/ARCHITECTURE.md` để hiểu kiến trúc hiện tại
2. Đọc `docs/DATA-MODEL.md` nếu feature liên quan đến dữ liệu
3. Tìm kiếm code hiện có liên quan đến feature này
4. Xác định các module bị ảnh hưởng (FinanceCore, FinanceData, FinanceUI, iOS, macOS)

## Output Yêu Cầu
Trả về kế hoạch bao gồm:
- **Mô tả feature**: User story và acceptance criteria
- **Phân tích tác động**: Modules nào cần thay đổi
- **Tasks chi tiết**: Chia nhỏ thành subtasks, ước lượng độ phức tạp
- **Thứ tự triển khai**: Dependencies giữa các tasks
- **Rủi ro**: Những điểm cần lưu ý
- **Test plan**: Các test cases cần viết

Lưu kế hoạch vào `docs/plans/[feature-name].md`
```

### File: `.claude/commands/implement.md`

```markdown
---
description: Triển khai feature theo kế hoạch đã lập
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

Triển khai feature: $ARGUMENTS

## Quy Trình
1. Đọc kế hoạch trong `docs/plans/` cho feature này
2. Tạo feature branch: `feature/[feature-name]`
3. Triển khai theo thứ tự trong kế hoạch:
   a. Models và Protocols trước (FinanceCore)
   b. Data layer (FinanceData) 
   c. Shared UI components (FinanceUI)
   d. Platform-specific views (iOS/macOS)
4. Viết tests song song với implementation
5. Chạy full test suite sau khi hoàn thành
6. Chạy swiftlint và swiftformat

## Rules
- Commit thường xuyên với meaningful messages
- Mỗi commit phải build thành công
- Không skip tests
- Follow conventions trong CLAUDE.md
```

### File: `.claude/commands/review.md`

```markdown
---
description: Review code changes hiện tại
allowed-tools: Read, Glob, Grep, Bash(git diff:*), Bash(git log:*)
---

Review tất cả thay đổi code hiện tại.

## Quy Trình
1. Chạy `git diff HEAD` để xem tất cả thay đổi
2. Sử dụng code-reviewer subagent để review chuyên sâu
3. Kiểm tra:
   - Security issues (đặc biệt quan trọng cho finance app)
   - Architecture compliance
   - Code quality
   - Test coverage cho code mới
   - Performance concerns
4. Tạo review report

## Output
Trả về review report theo format của code-reviewer agent:
🔴 CRITICAL, 🟡 WARNING, 🟢 SUGGESTION, 📝 NOTE
```

### File: `.claude/commands/pr.md`

```markdown
---
description: Tạo Pull Request cho thay đổi hiện tại
allowed-tools: Bash(git:*), Bash(gh:*), Bash(swiftlint:*), Bash(swift test:*), Read, Glob, Grep
---

Tạo Pull Request cho branch hiện tại.

## Quy Trình
1. Chạy `swiftlint lint --strict` — fix nếu có lỗi
2. Chạy `swiftformat .` — format code
3. Chạy `swift test` cho tất cả packages
4. Stage và commit tất cả thay đổi chưa commit
5. Push branch lên remote
6. Tạo PR với `gh pr create`:
   - Title: Conventional commit format
   - Body: Mô tả thay đổi, screenshots nếu UI change
   - Labels phù hợp
   - Link issues liên quan

## PR Template
```
## What
[Mô tả ngắn gọn thay đổi]

## Why  
[Lý do thay đổi, link issue]

## How
[Approach kỹ thuật]

## Testing
[Cách đã test, test cases mới]

## Checklist
- [ ] Tests pass
- [ ] Lint clean
- [ ] Documentation updated
- [ ] No sensitive data exposed
```
```

### File: `.claude/commands/fix-issue.md`

```markdown
---
description: Sửa bug theo issue number
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

Sửa issue #$ARGUMENTS theo quy trình sau:

1. Đọc issue details (nếu có gh CLI: `gh issue view $ARGUMENTS`)
2. Tìm hiểu root cause bằng cách đọc code liên quan
3. Tạo branch: `fix/issue-$ARGUMENTS`
4. Viết regression test TRƯỚC KHI sửa (TDD)
5. Fix bug
6. Verify regression test pass
7. Chạy full test suite
8. Commit với message: `fix: [description] (closes #$ARGUMENTS)`
```

### File: `.claude/commands/daily.md`

```markdown
---
description: Tổng hợp báo cáo tiến độ hàng ngày
allowed-tools: Read, Glob, Grep, Bash(git log:*), Bash(git diff:*), Bash(git branch:*)
---

Tạo báo cáo tiến độ phát triển hôm nay.

## Thu Thập Thông Tin
1. `git log --since="24 hours ago" --oneline` — commits gần đây
2. `git branch -a` — branches đang active
3. `git diff --stat HEAD~5` — summary thay đổi
4. Kiểm tra `docs/plans/` — tiến độ features đang triển khai
5. Kiểm tra open issues nếu có

## Output Format
```
# Daily Report — [Date]

## Completed
- [Feature/task đã hoàn thành]

## In Progress  
- [Feature/task đang làm] — [% hoàn thành]

## Blockers
- [Vấn đề đang gặp]

## Next
- [Kế hoạch tiếp theo]
```
```

---

## 7. Skills — Kỹ Năng Chuyên Sâu

Skills được Claude tự động phát hiện và sử dụng khi phù hợp với task. Mỗi skill là một thư mục chứa `SKILL.md`.

### File: `.claude/skills/swiftui-patterns/SKILL.md`

```markdown
---
name: swiftui-patterns
description: >
  SwiftUI best practices and patterns for finance app. Use when 
  building SwiftUI views, handling navigation, state management, 
  or creating adaptive layouts for iOS and macOS.
---

# SwiftUI Patterns for FinanceApp

## Navigation

### iOS Navigation
```swift
NavigationStack(path: $router.path) {
    TransactionListView()
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .transactionDetail(let id):
                TransactionDetailView(transactionId: id)
            case .addTransaction:
                AddTransactionView()
            case .accountDetail(let id):
                AccountDetailView(accountId: id)
            }
        }
}
```

### macOS Navigation  
```swift
NavigationSplitView(columnVisibility: $visibility) {
    SidebarView()
} content: {
    ContentListView(selection: $selectedItem)
} detail: {
    DetailView(item: selectedItem)
}
.navigationSplitViewStyle(.balanced)
```

## State Management Pattern
```swift
@Observable
final class TransactionListViewModel {
    private let getTransactionsUseCase: GetTransactionsUseCaseProtocol
    
    var transactions: [Transaction] = []
    var isLoading = false
    var error: AppError?
    
    init(getTransactionsUseCase: GetTransactionsUseCaseProtocol) {
        self.getTransactionsUseCase = getTransactionsUseCase
    }
    
    func loadTransactions() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            transactions = try await getTransactionsUseCase.execute()
        } catch {
            self.error = AppError(from: error)
        }
    }
}
```

## Reusable Component Pattern
```swift
struct AmountText: View {
    let amount: Decimal
    let type: TransactionType
    let style: AmountStyle
    
    var body: some View {
        Text(amount, format: .currency(code: "VND"))
            .font(style.font)
            .foregroundStyle(type.color)
            .accessibilityLabel("\(type.accessibilityPrefix) \(amount)")
    }
}
```

## Cross-Platform Conditional
```swift
struct AdaptiveLayout: View {
    var body: some View {
        #if os(iOS)
        TabView { /* iOS tab layout */ }
        #elseif os(macOS)
        NavigationSplitView { /* macOS sidebar layout */ }
        #endif
    }
}
```
```

### File: `.claude/skills/coredata-cloudkit/SKILL.md`

```markdown
---
name: coredata-cloudkit
description: >
  CoreData and CloudKit patterns for data persistence and sync. 
  Use when working on data models, migrations, sync logic, 
  or query optimization.
---

# CoreData + CloudKit Patterns

## SwiftData Model Definition
```swift
@Model
final class TransactionEntity {
    @Attribute(.unique) var id: UUID
    var amount: Decimal
    var note: String
    var date: Date
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?  // Soft delete for CloudKit sync
    
    @Relationship(deleteRule: .nullify)
    var category: CategoryEntity?
    
    @Relationship(deleteRule: .nullify)
    var account: AccountEntity?
    
    init(id: UUID = UUID(), amount: Decimal, note: String, date: Date) {
        self.id = id
        self.amount = amount
        self.note = note
        self.date = date
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

## Repository Pattern
```swift
protocol TransactionRepository: Sendable {
    func getAll(filter: TransactionFilter?) async throws -> [Transaction]
    func getById(_ id: UUID) async throws -> Transaction?
    func save(_ transaction: Transaction) async throws
    func delete(_ id: UUID) async throws
    func batchImport(_ transactions: [Transaction]) async throws
}
```

## CloudKit Sync Monitoring
```swift
final class SyncMonitor: ObservableObject {
    @Published var syncStatus: SyncStatus = .idle
    
    func startMonitoring() {
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil, queue: .main
        ) { notification in
            guard let event = notification.userInfo?[
                NSPersistentCloudKitContainer.eventNotificationUserInfoKey
            ] as? NSPersistentCloudKitContainer.Event else { return }
            
            self.syncStatus = SyncStatus(from: event)
        }
    }
}
```

## Performance: Batch Operations
- For > 100 records: use `NSBatchInsertRequest` 
- Use `fetchBatchSize` on fetch requests (default 20)
- Create compound indexes for common query patterns
- Use `NSFetchedResultsController` for list views
```

### File: `.claude/skills/finance-domain/SKILL.md`

```markdown
---
name: finance-domain
description: >
  Personal finance domain knowledge. Use when implementing 
  financial calculations, budgeting logic, transaction categorization,
  or reporting features.
---

# Finance Domain Knowledge

## Core Concepts

### Transaction Types
- **Income**: Salary, freelance, investment returns, gifts
- **Expense**: Bills, shopping, food, transport, entertainment
- **Transfer**: Between own accounts (NOT income or expense)

### Account Types
- **Cash**: Physical cash tracking
- **Bank**: Checking/savings accounts
- **Credit Card**: Credit accounts (negative = owed)
- **Investment**: Stocks, bonds, crypto
- **Loan**: Mortgages, personal loans (negative balance)

## Financial Calculations

### CRITICAL: Money Handling
```swift
// ALWAYS use Decimal for money — NEVER Double
let amount: Decimal = 1_000_000  // ✅
let amount: Double = 1_000_000   // ❌ floating point errors

// Rounding for display
let rounded = NSDecimalNumber(decimal: amount)
    .rounding(accordingToBehavior: NSDecimalNumberHandler(
        roundingMode: .bankers,
        scale: 0,  // VND has 0 decimal places
        raiseOnExactness: false,
        raiseOnOverflow: false,
        raiseOnUnderflow: false,
        raiseOnDivideByZero: true
    ))
```

### Budget Tracking
```
Budget Remaining = Budget Amount - Sum(Expenses in Period)
Budget Usage % = Sum(Expenses) / Budget Amount * 100
Daily Average Spending = Sum(Expenses in Month) / Days Elapsed
Projected Month Spend = Daily Average * Days in Month
```

### Net Worth Calculation
```
Net Worth = Sum(Asset Accounts) - Sum(Liability Accounts)
Assets = Cash + Bank + Investment (positive balances)
Liabilities = Credit Card debt + Loans (negative balances)
```

## Vietnamese Currency (VND)
- ISO code: VND
- Symbol: ₫
- Decimal places: 0 (no cents)
- Number format: 1.000.000 ₫ (dot as thousands separator)
- Use `Locale(identifier: "vi_VN")` for formatting
```

### File: `.claude/skills/apple-guidelines/SKILL.md`

```markdown
---
name: apple-guidelines
description: >
  Apple Human Interface Guidelines and App Store requirements. 
  Use when designing UI, handling app review requirements, 
  privacy policies, or platform-specific UX patterns.
---

# Apple Guidelines for Finance App

## App Store Requirements for Finance Apps
- Privacy policy required (handles financial data)
- Data encryption at rest and in transit
- Biometric auth option for accessing financial data
- No third-party analytics tracking financial data without consent
- Clear data deletion option (GDPR, App Privacy)

## iOS HIG Key Points
- Tab bar: max 5 tabs, most important features
- Suggested tabs: Dashboard, Transactions, Budget, Accounts, Settings
- Use SF Symbols for icons (consistent with system)
- Sheets for creation flows, push for detail views
- Swipe actions: Delete (destructive, red), Archive, etc.
- Pull to refresh for synced data

## macOS HIG Key Points
- Sidebar navigation (NavigationSplitView)
- Keyboard shortcuts for common actions (⌘N new, ⌘S save)
- Menu bar integration
- Toolbar for contextual actions
- Support standard macOS window behaviors (resize, full screen)

## Accessibility Checklist
- VoiceOver labels on all interactive elements
- Dynamic Type support (no fixed font sizes)
- Sufficient color contrast (4.5:1 minimum)
- Don't use color alone to convey information
- Support Bold Text setting
- Reduce Motion support
```

---

## 8. Hooks — Tự Động Hóa

Hooks đã được định nghĩa trong `settings.json` ở phần 4. Dưới đây là giải thích chi tiết:

### Các Hook Events Hữu Ích

| Event | Khi Nào | Ứng Dụng |
|-------|---------|-----------|
| `PreToolUse` | Trước khi agent dùng tool | Block edit trên main branch |
| `PostToolUse` | Sau khi agent dùng tool | Auto-format code sau khi edit |
| `Notification` | Agent cần thông báo | Desktop notification khi xong |
| `Stop` | Session kết thúc | Cleanup, summary |
| `SubagentStop` | Subagent hoàn thành | Log kết quả subagent |

### Hook Nâng Cao: Auto-lint + Auto-test

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write(*.swift)|Edit(*.swift)",
        "hooks": [
          {
            "type": "command",
            "command": "swiftformat \"$CLAUDE_FILE_PATH\" --config .swiftformat 2>/dev/null; swiftlint lint --path \"$CLAUDE_FILE_PATH\" --quiet 2>/dev/null || true",
            "timeout": 30
          }
        ]
      },
      {
        "matcher": "Write(*Tests.swift)|Edit(*Tests.swift)",
        "hooks": [
          {
            "type": "command",
            "command": "swift test --filter \"$(basename \"$CLAUDE_FILE_PATH\" .swift)\" 2>/dev/null || true",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

---

## 9. MCP Servers — Kết Nối Bên Ngoài

### File: `.mcp.json`

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "./"],
      "env": {}
    }
  }
}
```

### MCP Servers Hữu Ích Cho Dự Án

| Server | Mục Đích |
|--------|----------|
| `server-github` | Quản lý issues, PRs, reviews |
| `server-filesystem` | Mở rộng file access |
| `server-memory` | Lưu trữ kiến thức dài hạn |
| `server-sqlite` | Query database trực tiếp |
| `server-brave-search` | Tra cứu tài liệu Apple |

---

## 10. Workflow Vận Hành Hàng Ngày

### Workflow 1: Phát Triển Feature Mới

```
Bước 1: Lập kế hoạch
> /plan Thêm tính năng scan hóa đơn bằng camera

Bước 2: Review kế hoạch (đọc file trong docs/plans/)
> Hãy xem lại kế hoạch và điều chỉnh nếu cần

Bước 3: Triển khai
> /implement scan-receipt

Bước 4: Review code
> /review

Bước 5: Tạo PR
> /pr
```

### Workflow 2: Sửa Bug

```
> /fix-issue 42
```
(Claude tự động: đọc issue → tạo branch → viết test → fix → verify → commit)

### Workflow 3: Phát Triển Song Song (Agent Teams)

```
Tôi cần triển khai feature budget tracking. Hãy spawn các agent song song:
1. shared-core: Tạo Budget model và BudgetUseCase trong FinanceCore
2. data-architect: Tạo BudgetEntity schema và migration trong FinanceData  
3. ui-designer: Tạo BudgetCard và BudgetProgressBar components trong FinanceUI

Sau khi cả 3 hoàn thành, tiếp tục với:
4. ios-engineer: Build BudgetListView và BudgetDetailView cho iOS
5. macos-engineer: Build Budget section trong macOS sidebar

Cuối cùng:
6. test-engineer: Viết comprehensive tests
7. code-reviewer: Review toàn bộ thay đổi
```

### Workflow 4: Daily Standup

```
> /daily
```

### Workflow 5: Khi Cần Nghiên Cứu

```
Tôi cần tìm hiểu cách tốt nhất để implement recurring transactions.
Hãy spawn một subagent để research:
- Các pattern phổ biến cho recurring transactions
- Cách handle timezones cho scheduled transactions
- Best practices từ các app finance nổi tiếng
Tổng hợp findings và đề xuất approach cho dự án của chúng ta.
```

---

## 11. Agent Teams — Phát Triển Song Song

### Cách Sử Dụng Git Worktrees cho Parallel Development

```bash
# Tạo worktrees cho mỗi feature song song
git worktree add ../finance-feature-budget feature/budget-tracking
git worktree add ../finance-feature-reports feature/report-generation
git worktree add ../finance-feature-import feature/data-import

# Terminal 1: Budget feature
cd ../finance-feature-budget
claude  # Start Claude Code session cho budget

# Terminal 2: Reports feature  
cd ../finance-feature-reports
claude  # Start Claude Code session cho reports

# Terminal 3: Import feature
cd ../finance-feature-import
claude  # Start Claude Code session cho import
```

### Agent Teams Trong Cùng Session

Khi bạn mô tả task phức tạp, Claude Code tự động spawn agent teams:

```
Tôi cần refactor toàn bộ data layer để chuyển từ CoreData sang SwiftData.
Đây là task lớn, hãy chia ra các agents:

1. Agent "Schema": Convert tất cả NSManagedObject subclasses sang @Model
2. Agent "Repository": Update tất cả repository implementations  
3. Agent "Migration": Viết migration logic từ CoreData sang SwiftData
4. Agent "Tests": Update tất cả data layer tests

Các agents nên làm việc song song nhưng Agent "Migration" cần đợi 
Agent "Schema" hoàn thành trước.
```

---

## 12. Mẹo & Lưu Ý Quan Trọng

### Chi Phí Token
- Subagents tiêu tốn token riêng — spawn có chọn lọc
- Agent Teams chạy song song = nhiều token cùng lúc
- Nên dùng `model: sonnet` cho subagents (rẻ hơn Opus, đủ tốt cho hầu hết task)
- Chỉ dùng `model: opus` cho code-reviewer hoặc architectural decisions

### Context Management
- CLAUDE.md nên ngắn gọn, tập trung — không nhồi nhét quá nhiều
- Dùng `docs/` folder cho tài liệu chi tiết, reference khi cần
- Subagents giúp giữ main context sạch (output verbose không ảnh hưởng)
- Nếu context gần đầy, bắt đầu session mới

### Khi Agent Gặp Vấn Đề
- Nếu agent đi sai hướng: interrupt và redirect cụ thể
- Nếu code không build: cung cấp error message chính xác
- Nếu agent quên conventions: nhắc đọc lại CLAUDE.md hoặc docs cụ thể
- Dùng `--resume` flag để tiếp tục session bị gián đoạn

### Cấu Trúc Prompt Hiệu Quả
```
[Mục tiêu rõ ràng]
Tạo TransactionListView hiển thị danh sách giao dịch theo ngày.

[Constraints]
- Sử dụng NavigationStack (iOS) / NavigationSplitView (macOS)
- Group by date, sort mới nhất trước
- Hỗ trợ pull-to-refresh và infinite scroll

[Reference]
- Xem design trong docs/DESIGN-SYSTEM.md
- Model Transaction đã có trong Packages/FinanceCore/Sources/Models/

[Acceptance Criteria]
- Hiển thị amount, category icon, note, time
- Swipe-to-delete với confirmation
- Empty state khi chưa có transaction
```

### Security Cho Finance App
- KHÔNG BAO GIỜ hardcode API keys hay secrets
- Dùng Keychain cho sensitive data
- Đảm bảo `.env` files nằm trong `permissions.deny`
- Code review agent luôn check security issues
- Enable biometric authentication cho app access

### File `.gitignore` Nên Có

```gitignore
# Claude Code personal files
CLAUDE.local.md
.claude/settings.local.json

# Secrets
.env
.env.*
secrets/

# Xcode
*.xcuserdata
*.xcworkspace/xcuserdata/
DerivedData/

# Swift Package Manager
.build/
Packages/*/build/
```

---

## Checklist Khởi Tạo Dự Án

- [ ] Cài Claude Code: `npm install -g @anthropic-ai/claude-code`
- [ ] Tạo thư mục dự án và init git
- [ ] Tạo `CLAUDE.md` theo template ở phần 3
- [ ] Tạo `.claude/settings.json` theo phần 4
- [ ] Tạo các subagent files trong `.claude/agents/` theo phần 5
- [ ] Tạo slash commands trong `.claude/commands/` theo phần 6
- [ ] Tạo skills trong `.claude/skills/` theo phần 7
- [ ] Cấu hình `.mcp.json` nếu cần external tools
- [ ] Tạo `docs/ARCHITECTURE.md`, `DATA-MODEL.md`, etc.
- [ ] Tạo `.gitignore` với entries cho Claude Code
- [ ] Chạy `claude` và test với `/plan Test feature đầu tiên`
- [ ] Cài plugins hữu ích: `/plugin marketplace add anthropics/skills`

---

*Tài liệu này được tạo dựa trên Claude Code documentation chính thức (code.claude.com/docs) và best practices từ cộng đồng, cập nhật tháng 2/2026.*
