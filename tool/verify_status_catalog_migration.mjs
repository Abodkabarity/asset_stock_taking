import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { PGlite } from '../build/status-db-validation/node_modules/@electric-sql/pglite/dist/index.js';

const db = new PGlite();
await db.exec(`
  create role anon; create role authenticated;
  create schema auth;
  create function auth.uid() returns uuid language sql stable as $$
    select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid;
  $$;
  grant usage on schema auth to authenticated;
  create function auth.jwt() returns jsonb language sql stable as $$
    select jsonb_build_object('is_anonymous',coalesce(nullif(current_setting('request.jwt.claim.is_anonymous',true),'')::boolean,false));
  $$;
  create table public.app_users(user_id uuid primary key,role text,is_active boolean);
  insert into public.app_users values
    ('00000000-0000-0000-0000-000000000001','admin',true),
    ('00000000-0000-0000-0000-000000000002','admin',false),
    ('00000000-0000-0000-0000-000000000003','user',true);
  create function public.is_active_app_admin(check_user_id uuid) returns boolean
    language sql stable security definer set search_path='' as $$
      select exists(select 1 from public.app_users where user_id=check_user_id and role='admin' and is_active);
  $$;
  create table public.app_audit_log (payload jsonb);
  create function public.capture_app_audit() returns trigger
    language plpgsql security definer set search_path='' as $$
    begin insert into public.app_audit_log values(to_jsonb(new)); return new; end; $$;
  create table public.asset_stock_taking(status text,operational_status text,condition_revision bigint not null default 0,legacy_status_before_separation text);
  insert into public.asset_stock_taking(status,operational_status) values('Good','Maintenance');
  create function public.asset_preserve_physical_condition() returns trigger language plpgsql as $$ begin return new; end $$;
  create trigger asset_preserve_physical_condition before insert or update on public.asset_stock_taking for each row execute function public.asset_preserve_physical_condition();
`);
await db.exec(await readFile(new URL('../supabase/migrations/20261016121018_configurable_asset_status_options.sql', import.meta.url),'utf8'));
await db.exec(await readFile(new URL('../supabase/migrations/20261016122106_restrict_status_catalog_to_permanent_admins.sql', import.meta.url),'utf8'));
await db.exec(await readFile(new URL('../supabase/migrations/20261017064826_simplify_catalog_to_physical_statuses.sql', import.meta.url),'utf8'));
assert.deepEqual((await db.query('select label from public.asset_status_options order by sort_order')).rows.map(row=>row.label),
  ['Under Maintenance','Damaged','Lost','Disposed','Sold','New','Good','Assigned']);
await db.exec('set role anon');
assert.equal((await db.query('select count(*)::int n from public.asset_status_options')).rows[0].n,8);
await assert.rejects(db.exec("insert into public.asset_status_options(value,label,kind) values('Fake','Fake','condition')"), /permission denied/);
await db.exec("reset role; set role authenticated; select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000003',false)");
await assert.rejects(db.exec("insert into public.asset_status_options(value,label,kind) values('Fake','Fake','condition')"), /row-level security/);
assert.equal((await db.query("update public.asset_status_options set label='Hijacked' where value='Good' returning value")).rows.length,0);
await db.exec("select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',false)");
assert.equal((await db.query("update public.asset_status_options set label='Hijacked' where value='Good' returning value")).rows.length,0);
await db.exec("select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',false)");
await db.exec("select set_config('request.jwt.claim.is_anonymous','true',false)");
assert.equal((await db.query("update public.asset_status_options set label='Hijacked' where value='Good' returning value")).rows.length,0);
await db.exec("select set_config('request.jwt.claim.is_anonymous','false',false)");
await db.exec("insert into public.asset_status_options(value,label,kind) values('Refurbished','Refurbished','condition')");
await db.exec("update public.asset_status_options set label='Excellent' where value='Good'");
await assert.rejects(db.exec("update public.asset_status_options set value='Different' where value='Good'"), /meaning cannot be changed/);
await assert.rejects(db.exec("update public.asset_status_options set kind='operation' where value='Good'"), /meaning cannot be changed/);
await assert.rejects(db.exec("insert into public.asset_status_options(value,label,kind) values('good','Duplicate','condition')"), /duplicate key/);
await assert.rejects(db.exec("insert into public.asset_status_options(value,label,kind) values('Wrong operation','Wrong operation','operation')"), /check constraint/);
await db.exec("update public.asset_status_options set is_active=false where value='Good'");
assert.equal((await db.query("select count(*)::int n from public.asset_status_options where is_active")).rows[0].n,8);
assert.equal((await db.query("select label from public.asset_status_options where value='Good'")).rows[0].label,'Excellent');
await db.exec("update public.asset_status_options set is_active=true where value='Good'; reset role");
assert.deepEqual((await db.query('select status,operational_status from public.asset_stock_taking')).rows,[{status:'Good',operational_status:'Maintenance'}]);
assert.ok((await db.query('select count(*)::int n from public.app_audit_log')).rows[0].n>=4);
assert.equal((await db.query("select count(*)::int n from public.asset_status_options where kind<>'condition'")).rows[0].n,0);
for (const status of ['Maintenance','Disposed','Sold','Lost','Assigned','Under Maintenance','Reserved']) {
  await db.query('update public.asset_stock_taking set status=$1,condition_revision=condition_revision+1',[status]);
  assert.deepEqual((await db.query('select status,operational_status from public.asset_stock_taking')).rows,[{status,operational_status:'Maintenance'}]);
}
await assert.rejects(db.exec("update public.asset_stock_taking set status='Good'"),/explicit confirmation/);
await db.exec("insert into public.asset_stock_taking(status,operational_status) values('Disposed','Available')");
assert.equal((await db.query("select operational_status from public.asset_stock_taking where status='Disposed'")).rows[0].operational_status,'Available');
await db.close();
console.log('Status catalog verified: exact seed choices, public read, admin-only CRUD, immutable meanings, case-insensitive uniqueness, reversible deletion and physical-only names independent of operations.');
