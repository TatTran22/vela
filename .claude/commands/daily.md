---
description: Generate a daily progress report
allowed-tools: Read, Glob, Grep, Bash(git log:*), Bash(git diff:*), Bash(git branch:*)
---

Generate a daily development progress report.

## Gather Information
1. `git log --since="24 hours ago" --oneline` — recent commits
2. `git branch -a` — active branches
3. `git diff --stat HEAD~5` — change summary
4. Check `docs/plans/` — progress on features in development
5. Check open issues if available

## Output Format
```
# Daily Report — [Date]

## Completed
- [Completed features/tasks with commit references]

## In Progress
- [Features/tasks in progress] — [% complete]
- Branch: [branch name] — [status]

## Blockers
- [Current issues/blockers]
- [Dependencies waiting on]

## Metrics
- Commits today: [count]
- Files changed: [count]
- Lines added/removed: +[added] / -[removed]
- Test status: [passing/failing] ([count] tests)

## Questions / Decisions Needed
- [Technical decisions that need user input]
- [Architecture choices pending]

## Next
- [Upcoming plans for next session]
- [Priority items]
```
