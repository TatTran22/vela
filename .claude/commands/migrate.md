---
description: Create and execute a data schema migration
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

Schema migration: $ARGUMENTS

## Process
1. **Review current schema**: Read existing SwiftData/CoreData models in `Packages/FinanceData/`
2. **Reference skill**: Load `coredata-cloudkit` skill for migration patterns
3. **Plan migration**:
   a. Document what changes are needed (add/remove/rename properties, new entities)
   b. Determine migration type: lightweight vs custom `SchemaMigrationPlan`
   c. Identify impact on CloudKit sync
4. **Create versioned schema**:
   a. Create new `VersionedSchema` conformance
   b. Add migration stage to `SchemaMigrationPlan`
   c. Update `ModelContainer` configuration
5. **Update repository layer**: Modify repository implementations for new schema
6. **Update domain models**: Update models in `Packages/FinanceCore/` if needed
7. **Write migration tests**:
   a. Test migration from previous schema version
   b. Test CRUD operations with new schema
   c. Verify CloudKit compatibility
8. **Run full test suite**: Ensure nothing is broken

## Agent Delegation
- **data-architect**: Primary agent — schema design, migration code, CloudKit sync
- **shared-core**: Update domain models if schema changes affect them
- **test-engineer**: Write migration tests and verify existing tests

## Rules
- ALWAYS create a `VersionedSchema` — never modify existing schema in place
- Test migration with sample data before merging
- CloudKit constraints: no unique constraints, optional relationships, default values
- Document the migration in commit message with before/after schema
- Backup strategy: ensure rollback is possible
