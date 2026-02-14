---
description: Create a detailed plan for a new feature
---

I need you to create an implementation plan for the following feature: $ARGUMENTS

## Process
1. Read `docs/ARCHITECTURE.md` to understand the current architecture
2. Read `docs/DATA-MODEL.md` if the feature involves data
3. Search for existing code related to this feature
4. Identify affected modules (FinanceCore, FinanceData, FinanceUI, iOS, macOS)
5. Reference relevant skills for domain knowledge:
   - `finance-domain` — financial concepts and calculations
   - `swiftui-patterns` — UI patterns and navigation
   - `coredata-cloudkit` — data persistence and sync
   - `error-handling` — error types and handling patterns
   - `ci-cd-integration` — CI/CD considerations
   - `apple-guidelines` — platform design guidelines

## Required Output
Return a plan that includes:
- **Feature description**: User story and acceptance criteria
- **Impact analysis**: Which modules need changes
- **Detailed tasks**: Break down into subtasks, estimate complexity
- **Agent assignment**: Which agent handles each task (shared-core, data-architect, ui-designer, ios-engineer, macos-engineer, test-engineer)
- **Implementation order**: Dependencies between tasks
- **Risks**: Points that need attention
- **Test plan**: Test cases to write

Save the plan to `docs/plans/[feature-name].md`
