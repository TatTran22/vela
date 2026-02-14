---
description: Refactor code without changing behavior
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

Refactor: $ARGUMENTS

## Process
1. **Understand scope**: Read the code to be refactored, understand current behavior
2. **Run existing tests**: Ensure all tests pass BEFORE making changes
3. **Plan refactoring**: Identify what changes are needed, confirm behavior is preserved
4. **Implement changes** following this order:
   a. Extract protocols/interfaces if needed
   b. Rename types/methods for clarity
   c. Move code to appropriate modules
   d. Simplify complex logic
   e. Remove dead code
5. **Run tests again**: All existing tests MUST still pass
6. **Run linting**: `swiftlint lint --strict` and `swiftformat .`

## Agent Delegation
- **shared-core**: Refactoring in `Packages/FinanceCore/` (models, use cases, protocols)
- **data-architect**: Refactoring in `Packages/FinanceData/` (repositories, entities)
- **ui-designer**: Refactoring in `Packages/FinanceUI/` (components, design tokens)
- **ios-engineer**: Refactoring in `FinanceApp-iOS/` (iOS views, view models)
- **macos-engineer**: Refactoring in `FinanceApp-macOS/` (macOS views, view models)
- **test-engineer**: Updating tests after refactoring

## Rules
- **DO NOT change behavior** — refactoring must be behavior-preserving
- Every refactoring step must compile and pass tests
- Commit after each logical refactoring step
- If tests fail after a change, revert and try a different approach
- Follow conventions in `docs/CONVENTIONS.md`
