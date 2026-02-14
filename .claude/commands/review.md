---
description: Review current code changes
allowed-tools: Read, Glob, Grep, Bash(git diff:*), Bash(git log:*)
---

Review all current code changes.

## Process
1. Run `git diff HEAD` to see all changes
2. Delegate to the **code-reviewer** agent with the following command:
   ```
   Use Task tool with subagent_type="code-reviewer"
   Prompt: "Review the current git diff for security issues, architecture compliance,
   code quality, test coverage, and performance concerns. Focus on finance-app specific
   rules: Decimal for money, no force unwraps, repository pattern compliance."
   ```
3. Check for:
   - Security issues (especially critical for a finance app)
   - Architecture compliance (MVVM + Clean Architecture)
   - Code quality (Swift conventions, naming, documentation)
   - Test coverage for new code
   - Performance concerns (SwiftUI body complexity, data queries)
   - Finance-specific rules (Decimal for money, proper rounding)
4. Generate a review report

## Severity Levels
- **CRITICAL**: Security vulnerabilities, data loss risks, money calculation errors
- **WARNING**: Architecture violations, missing tests, performance issues
- **SUGGESTION**: Code style, naming improvements, documentation gaps
- **NOTE**: Informational observations, nice-to-have improvements

## Output
Return a review report with findings grouped by severity:
CRITICAL, WARNING, SUGGESTION, NOTE
