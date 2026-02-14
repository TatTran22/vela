---
description: Create a Pull Request for current changes
allowed-tools: Bash(git:*), Bash(gh:*), Bash(swiftlint:*), Bash(swift test:*), Read, Glob, Grep
---

Create a Pull Request for the current branch.

## Process
1. Run `swiftlint lint --strict` — fix any errors
2. Run `swiftformat .` — format code
3. Run `swift test` for all packages
4. Stage and commit any uncommitted changes
5. Push the branch to remote
6. Create a PR with `gh pr create`:
   - Title: Conventional commit format
   - Body: Description of changes, screenshots if UI change
   - Appropriate labels
   - Link related issues

## PR Template
```
## What
[Brief description of changes]

## Why
[Reason for changes, link to issue]

## How
[Technical approach]

## Testing
[How it was tested, new test cases]

## Checklist
- [ ] Tests pass
- [ ] Lint clean
- [ ] Documentation updated
- [ ] No sensitive data exposed
```
