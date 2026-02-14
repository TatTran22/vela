---
description: "Tạo hoặc cập nhật documentation — API docs, architecture docs, README, changelogs"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Docs: Generate/Update Documentation

## Đọc Context Trước
1. `CLAUDE.md`
2. Existing docs in `docs/` directory

## Modes

### Mode 1: Update API Docs
Scan all public APIs in Packages/ and ensure:
- Every public type has `///` doc comment
- Every public method has `///` doc comment with parameters and returns
- Every public property has `///` doc comment
- Generate summary in `docs/API-SPEC.md`

### Mode 2: Update Architecture Docs
Review current codebase and update:
- `docs/ARCHITECTURE.md` — module diagram, dependencies, data flow
- `docs/DATA-MODEL.md` — current entities, relationships, indexes

### Mode 3: Generate Changelog
Based on git log since last tag:
- Group by: Features, Fixes, Improvements, Breaking Changes
- Output as `CHANGELOG.md` entry

### Mode 4: Update README
- Project overview, setup instructions
- Build & run instructions
- Testing instructions
- Contributing guidelines

## Rules
- Write documentation in English
- Use Markdown format
- Include code examples where helpful
- Keep docs concise — reference code instead of duplicating
- Update existing docs rather than creating new files
