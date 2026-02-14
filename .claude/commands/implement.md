---
description: Implement a feature according to the existing plan
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

Implement the feature: $ARGUMENTS

## Process
1. Read the plan in `docs/plans/` for this feature
2. Create a feature branch: `feature/[feature-name]`
3. Reference relevant skills before coding:
   - `swiftui-patterns` — for UI implementation
   - `finance-domain` — for financial calculations
   - `coredata-cloudkit` — for data layer changes
   - `error-handling` — for error types and handling
   - `apple-guidelines` — for platform UX compliance
4. Implement in the following order:
   a. Models and Protocols first (FinanceCore)
   b. Data layer (FinanceData)
   c. Shared UI components (FinanceUI)
   d. Platform-specific views (iOS/macOS)
5. Write tests alongside the implementation
6. Run the full test suite after completion
7. Run swiftlint and swiftformat

## Agent Delegation
Delegate to specialized agents based on which modules are affected:
- **shared-core** agent: Models, protocols, use cases in `Packages/FinanceCore/`
- **data-architect** agent: Repository, entities, migrations in `Packages/FinanceData/`
- **ui-designer** agent: Shared components in `Packages/FinanceUI/`
- **ios-engineer** agent: iOS views and view models in `FinanceApp-iOS/`
- **macos-engineer** agent: macOS views and view models in `FinanceApp-macOS/`
- **test-engineer** agent: Tests across all modules
- **code-reviewer** agent: Final review before PR

When a feature touches multiple modules, delegate each module to its agent in parallel where possible.

## Rules
- Commit frequently with meaningful messages
- Every commit must build successfully
- Do not skip tests
- Follow conventions in CLAUDE.md and `docs/CONVENTIONS.md`
