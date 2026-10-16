# Physical condition and operational availability

`asset_stock_taking.status` now describes physical condition (for example Good,
Damaged or New). `operational_status` independently describes availability:
Available, Maintenance, Checked Out, Reserved, Disposed, Lost, Sold or Assigned.
The registry, details, filters, mobile cards and Excel export show both values.
Completing maintenance, checking in or releasing a reservation never sets the
physical condition to Good. An inspection can explicitly change the condition.

## Rollout order

1. Confirm access to the application project **bdfzhhqzqigkjvguxkgp**. Do not
   substitute a similarly named project. Inspect its current schema, policies,
   triggers and status distribution before applying this migration. The local
   test fixture is not a verification of production schema or RLS policies.
2. Back up the database. The migration expects the existing application tables:
   `asset_stock_taking`, `asset_checkouts`, `asset_reservations`,
   `asset_maintenance`, `asset_activity_log` and `app_audit_log`, including their existing columns.
   The deleted-assets table is optional. Resolve any conflicting triggers first.
3. Apply `supabase/migrations/20261016100108_separate_asset_condition_and_operations.sql`
   through the normal migration mechanism. It runs in one transaction.
4. Verify the aggregates below, review Supabase security/performance advisors,
   and exercise maintenance, checkout, reservation and disposal using a test
   account under the real RLS policies.
5. Deploy the web/mobile changes only after the database migration succeeds.
   Pushing to `master` deploys GitHub Pages automatically. Keep this change on
   its feature branch until the database prerequisite is satisfied.

New workflow actions detect a missing `operational_status` column before writing.
Older clients sending a workflow marker through `status` are translated by the
database trigger without overwriting the physical condition. Physical changes
from older clients are rejected until those clients support condition revisions.
The upgraded mobile sync omits operational state, preventing stale offline data
from resetting server workflows. Unknown legacy conditions are not uploaded over
a condition recovered on the server.

Repeated offline condition edits retain their original server revision and one
pending change flag. Upload advances the revision once; the next download clears
the local flag. Unknown rows are uploaded separately so PostgREST's union of batch
keys cannot turn an omitted condition into a null write.

## Historical data and inspection

The migration retains the original value in the immutable
`legacy_status_before_separation` column. A physical condition overwritten by
an operation is recovered only from the corresponding active checkout or
reservation snapshot, the latest matching maintenance/disposal activity, or the
latest audit record of a transition into that operational state.
Missing evidence becomes `Unknown`, displayed as **Needs review**. Never bulk
replace these unknown conditions with Good.

`condition_revision` provides optimistic concurrency protection. An explicit
condition edit must filter by the revision the user inspected and submit that
revision plus one. Stale condition writes fail. Workflow writes do not increment
this revision and never restore an outdated `original_status` snapshot.

Workflow record triggers lock the parent asset and update operational status in
the same transaction. A conflicting new operation is rejected. Closing one of
several open maintenance jobs keeps the asset in Maintenance. Disposed/Sold
assets cannot be reactivated by ordinary workflow updates. Reserved transfers
use `asset_transfer_reservation` to change location and release the reservation
atomically. Functions use invoker rights and keep existing table policies in force.

Read-only verification queries:

```sql
select status, operational_status, count(*)
from public.asset_stock_taking
group by status, operational_status
order by status, operational_status;

select count(*) as needs_inspection
from public.asset_stock_taking where status = 'Unknown';

select count(*) as mixed_status_values
from public.asset_stock_taking
where lower(trim(status)) in
  ('available', 'maintenance', 'under maintenance', 'in maintenance',
   'checked out', 'reserved', 'disposed', 'lost', 'sold', 'assigned');
```

## Local verification

```powershell
flutter test --no-pub test/asset_status_separation_test.dart test/web_asset_state_repository_test.dart test/transfer_asset_picker_dialog_test.dart test/branch_dropdown_test.dart test/transfer_excel_service_test.dart tool/capture_asset_states.dart
flutter build web --no-pub --no-wasm-dry-run

# Test-only PostgreSQL/WASM dependency; nothing is added to the app runtime.
npm install --prefix build/status-db-validation @electric-sql/pglite@0.5.10
node tool/verify_asset_status_migration.mjs
```

The PostgreSQL fixture checks recovery, conflict rollback, condition revisions,
multiple maintenance jobs, invoker rights and atomic reserved transfers. The
widget capture uses sample data and the actual `AssetStateBadges` widget; its
output is `build/asset_states/condition_and_availability.png`.

## Production verification — 2026-10-16

Applied through the Supabase SQL Editor after the owner signed in to the correct
project (the connector was authenticated to a different account). The existing
table columns, types, constraints, grants, audit triggers and policies were
inspected first. This SQL Editor application does not create a CLI migration
history entry; do not blindly reapply the file to this project.

The pre-migration registry contained 915 assets: 910 with physical conditions,
four Maintenance and one Checked Out. Audit evidence restored one Maintenance
asset to Damaged. Four conditions require inspection. Legacy operational states
were retained, including older records that have no matching active workflow;
those records were not silently made Available.

A real PostgreSQL transaction using `SET LOCAL ROLE authenticated` verified
maintenance/completion, checkout/check-in, reservation, atomic reserved transfer
and disposal against the existing schema and audit triggers. It rolled back all
test changes. Local verification passed 33 Flutter tests and 23 PostgreSQL checks,
and the release web build succeeded. Static analysis reported existing warnings
and informational lints, with no compile errors.

Post-migration aggregates confirmed all 915 assets remain, all 910 pre-existing
physical conditions are unchanged, no workflow markers remain in `status`, and
no rollback-test records remain. Advisor Center still reports the existing RLS
and other project configuration findings; this migration does not change the
project's access model or repair unrelated security settings.
