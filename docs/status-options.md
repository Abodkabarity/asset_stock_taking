# Status options

Setup → Statuses manages the options in the web Add Asset, Add Inventory and
Edit Asset forms. The initial order is Under Maintenance, Damaged, Lost,
Disposed, Sold, New, Good and Assigned.

`asset_status_options.value` is a stable meaning; `label` is the editable display
name. Physical conditions and operational states remain separate on assets.
Choosing an operational state reveals a physical-condition field and preserves
that condition. Changing a physical condition on an asset already in a workflow
does not release it from that workflow. A busy asset cannot start another
operation from the edit form; its expected operation is checked when saving.
Operational selections use an atomic batch insert because older bulk-creation
RPCs omit the operational-status column.

Deleting an option sets `is_active=false`. New selectors omit it; existing assets
and audit history retain their values and labels. Undo restores the option.
Older values such as Very Good are retained when editing existing records and
are not added back to new-asset choice lists. Empty configuration is handled
without silently restoring the default choices.

The catalog contains public configuration labels. RLS permits reading them;
only active, permanent application administrators can add, rename or retire
options. Canonical value/type changes are blocked by a database trigger.
Edits are recorded through the existing application audit trigger.

Both catalog migrations were applied to project `bdfzhhqzqigkjvguxkgp` on
2026-10-16. CRUD was verified using an authenticated administrator inside a
transaction that was rolled back. The local PostgreSQL fixture verifies public
read, admin/non-admin/inactive/anonymous authorization, immutable meanings,
uniqueness, retirement/restoration and unchanged asset records.

```powershell
node tool/verify_status_catalog_migration.mjs
flutter test --no-pub test/status_catalog_test.dart
flutter test --no-pub tool/capture_status_setup.dart
flutter build web --no-pub --no-wasm-dry-run
```

The PostgreSQL fixture uses the test-only PGlite installation described in
`asset-condition-migration.md`. Widget captures use sample configuration and are
saved to `build/status_catalog/setup_statuses.png` and `status_dropdown.png`.
