---
description: Fix a bug by issue number
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

Fix issue #$ARGUMENTS following this process:

1. Read issue details (if gh CLI available: `gh issue view $ARGUMENTS`)
2. Investigate root cause by reading related code
3. Create branch: `fix/issue-$ARGUMENTS`
4. Write a regression test BEFORE fixing (TDD)
5. Fix the bug
6. Verify the regression test passes
7. Run full test suite
8. Commit with message: `fix: [description] (closes #$ARGUMENTS)`
