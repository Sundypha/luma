# Drift schema fixtures

Committed SQLite files under `test/fixtures/` mirror shipped schema versions so migration tests can open real on-disk files.

## Regenerating `ptrack_v1.sqlite`

When bumping `ptrackSupportedSchemaVersion` / `schemaVersion`, add a new fixture rather than editing old files in place (keeps history of what each version looked like).

1. Update `PtrackDatabase` schema and migrations.
2. From `packages/ptrack_data`:

   ```bash
   fvm dart run tool/create_v1_fixture.dart
   ```

   Adjust `tool/create_v1_fixture.dart` (or add `create_v2_fixture.dart`) so the SQL matches the Drift-generated `CREATE TABLE` for that version.

3. Run `fvm dart run build_runner build --delete-conflicting-outputs` if table definitions changed.
4. Commit the new binary under `test/fixtures/`.

## Schema dumps (optional)

For larger bumps, you can export SQL with `sqlite3 .schema` from a DB created by the app at that version and align the fixture script with that output.
