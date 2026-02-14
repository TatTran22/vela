---
description: Run the test suite and report results
allowed-tools: Read, Glob, Grep, Bash(swift test:*), Bash(xcodebuild:*)
---

Run the test suite and provide a comprehensive report.

## Process
1. Run unit tests for all packages:
   - `swift test --package-path Packages/FinanceCore`
   - `swift test --package-path Packages/FinanceData`
   - `swift test --package-path Packages/FinanceUI`
2. Run iOS UI tests if available
3. Run macOS UI tests if available
4. Collect and summarize results

## Coverage Targets
| Module | Min Coverage | Focus Areas |
|--------|-------------|-------------|
| FinanceCore | 90% | Use cases, financial calculations, validation |
| FinanceData | 80% | Repository CRUD, migrations, sync logic |
| FinanceUI | 70% | Component rendering, accessibility |
| iOS App | 60% | Navigation flows, critical user paths |
| macOS App | 60% | Navigation flows, keyboard shortcuts |

## Output
Return a test report including:
- **Summary**: Total tests run / passed / failed / skipped
- **Per-module results**: Breakdown by FinanceCore, FinanceData, FinanceUI, iOS, macOS
- **Failed test details**: Error messages and stack traces
- **Coverage report**: Current coverage vs targets (if available)
- **Missing coverage**: Areas that need more tests
- **Recommendations**: Specific test cases to add

## Success Criteria
- All tests pass (zero failures)
- No test is skipped without documented reason
- New code has corresponding tests
- Financial calculation tests cover edge cases (zero, negative, overflow)
