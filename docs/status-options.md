# Physical status options

Setup → Statuses manages physical status names for Add Asset, Add Inventory and
Edit Asset. Add and Edit dialogs contain only Status name; there is no type or
operation selection. All choices, including Under Maintenance, Lost, Disposed,
Sold and Assigned, are physical statuses in this catalog.

Choosing a catalog status writes only `asset_stock_taking.status`. New assets
start with operational availability Available; editing a physical status keeps
the asset's current operation. Maintenance, checkout, reservation and disposal
pages continue to manage `operational_status` and their records independently.
Operational labels never use the editable physical-status catalog.

`asset_status_options.value` remains stable; `label` is the editable display
name. Deleting retires an option and offers Undo. Existing values and labels
remain available for historical records. Existing legacy physical statuses such
as Very Good remain editable without reappearing in new-asset choices.

RLS permits reading these configuration labels. Only active, permanent
application administrators can add, rename or retire options. The database
retains a compatibility `kind` column fixed to condition, with no UI/API choice.
Audit records and optimistic condition revisions remain in force.

The physical-only migration was applied on 2026-10-17 to
`bdfzhhqzqigkjvguxkgp`. Before/after fingerprints confirmed that the 915 asset
statuses, workflow states and condition revisions did not change. A rollback
transaction verified workflow-like physical names, maintenance start and
completion without changing the physical status. Legacy offline JSON without an
operational-status field remains readable; modern records preserve all physical
status names exactly. Older write clients must use explicit operation fields and
condition revisions rather than relying on status-name translation.

```powershell
node tool/verify_status_catalog_migration.mjs
flutter test --no-pub test/status_catalog_test.dart test/asset_status_separation_test.dart test/web_asset_state_repository_test.dart
flutter test --no-pub tool/capture_status_setup.dart
flutter build web --no-pub --no-wasm-dry-run
```

The PostgreSQL fixture uses the test-only PGlite installation described in
`asset-condition-migration.md`. Actual-widget previews with sample data are
saved to `build/status_catalog/setup_statuses.png`, `status_edit_dialog.png`
and `status_dropdown.png`.
