-- Apply to the application's project bdfzhhqzqigkjvguxkgp before deploying.
-- Existing policies/grants remain in force; all trigger functions are invokers.
begin;

alter table public.asset_stock_taking
  add column if not exists operational_status text not null default 'Available',
  add column if not exists condition_revision bigint not null default 0,
  add column if not exists legacy_status_before_separation text;
alter table if exists public.asset_stock_taking_deleted
  add column if not exists operational_status text not null default 'Available';

-- A physical condition is restored only from evidence captured by the operation
-- that replaced it. Never guess Good for an unrecorded historical condition.
with recovery as (
  select a.id, a.status as legacy_status,
    (select e.condition from (
      select c.original_status as condition, c.checked_out_at as evidence_at
      from public.asset_checkouts c
      where c.item_code=a.item_code and not c.is_checked_in
        and lower(trim(a.status)) in ('checked out','assigned')
      union all
      select r.original_status, r.reserved_at
      from public.asset_reservations r
      where r.item_code=a.item_code and r.is_active
        and lower(trim(a.status))='reserved'
      union all
      select last_event.metadata->>'previous_status', last_event.created_at
      from lateral (
        select l.metadata,l.created_at from public.asset_activity_log l
        where l.item_code=a.item_code and (
          (lower(trim(a.status)) in ('maintenance','under maintenance','in maintenance')
            and l.action in ('maintenance','maintenance_status')) or
          (lower(trim(a.status))='disposed' and l.action in ('dispose','dispose_status')))
        order by l.created_at desc,l.id desc limit 1
      ) last_event
      union all
      select last_change.old_data->>'status', last_change.occurred_at
      from lateral (
        select l.old_data,l.occurred_at from public.app_audit_log l
        where l.entity_table='asset_stock_taking' and l.operation='UPDATE'
          and l.item_code=a.item_code
          and lower(trim(l.new_data->>'status'))=lower(trim(a.status))
          and (l.old_data->>'status') is distinct from (l.new_data->>'status')
          and lower(trim(a.status)) in
            ('available','maintenance','under maintenance','in maintenance',
             'checked out','reserved','disposed','lost','sold','assigned')
        order by l.occurred_at desc,l.id desc limit 1
      ) last_change
    ) e where nullif(trim(e.condition),'') is not null
      and lower(trim(e.condition)) not in
        ('available','maintenance','under maintenance','in maintenance','checked out',
         'reserved','disposed','lost','sold','assigned','unknown')
      order by e.evidence_at desc limit 1) as recovered_condition
  from public.asset_stock_taking a where a.legacy_status_before_separation is null
)
update public.asset_stock_taking a set
  legacy_status_before_separation=r.legacy_status,
  operational_status=case lower(trim(r.legacy_status))
    when 'maintenance' then 'Maintenance' when 'under maintenance' then 'Maintenance'
    when 'in maintenance' then 'Maintenance' when 'checked out' then 'Checked Out'
    when 'reserved' then 'Reserved' when 'disposed' then 'Disposed'
    when 'lost' then 'Lost' when 'sold' then 'Sold' when 'assigned' then 'Assigned'
    else 'Available' end,
  status=case when lower(trim(r.legacy_status)) in
    ('available','maintenance','under maintenance','in maintenance','checked out',
     'reserved','disposed','lost','sold','assigned')
    then coalesce(r.recovered_condition,'Unknown')
    else coalesce(nullif(trim(r.legacy_status),''),'Unknown') end
from recovery r where a.id=r.id;

alter table public.asset_stock_taking add constraint asset_operational_status_check
  check (operational_status in
    ('Available','Maintenance','Checked Out','Reserved','Disposed','Lost','Sold','Assigned'));
create index if not exists asset_operational_location_idx
  on public.asset_stock_taking (operational_status,location);

-- Older clients may still send Maintenance/Disposed as "status". Preserve the
-- physical condition and translate those writes into the separate workflow field.
create or replace function public.asset_preserve_physical_condition()
returns trigger language plpgsql security invoker set search_path='' as $$
declare mapped text;
begin
  mapped := case lower(trim(new.status))
    when 'available' then 'Available'
    when 'maintenance' then 'Maintenance' when 'under maintenance' then 'Maintenance'
    when 'in maintenance' then 'Maintenance' when 'checked out' then 'Checked Out'
    when 'reserved' then 'Reserved' when 'disposed' then 'Disposed'
    when 'lost' then 'Lost' when 'sold' then 'Sold' when 'assigned' then 'Assigned'
    else null end;
  if mapped is not null then
    new.operational_status := mapped;
    if tg_op='UPDATE' then new.status := old.status;
    else new.status := 'Unknown'; end if;
  end if;
  new.status := coalesce(nullif(trim(new.status),''),'Unknown');
  if tg_op='UPDATE' then
    new.legacy_status_before_separation := old.legacy_status_before_separation;
    if new.status is distinct from old.status then
      if new.condition_revision<>old.condition_revision+1 then
        raise exception 'Physical condition changed or requires explicit confirmation. Refresh and inspect the asset before saving.';
      end if;
    else new.condition_revision := old.condition_revision; end if;
    if old.operational_status in ('Disposed','Sold')
        and new.operational_status is distinct from old.operational_status then
      raise exception 'Disposed or sold assets cannot be reactivated by an ordinary workflow';
    end if;
    if pg_catalog.pg_trigger_depth()=1
        and new.operational_status is distinct from old.operational_status
        and new.operational_status in ('Maintenance','Disposed')
        and old.operational_status<>'Available' then
      raise exception 'Complete the current asset operation before maintenance or disposal';
    end if;
  end if;
  return new;
end;
$$;
create trigger asset_preserve_physical_condition
  before insert or update on public.asset_stock_taking
  for each row execute function public.asset_preserve_physical_condition();

-- Lock the same asset before starting any workflow. A concurrent checkout,
-- reservation or maintenance cannot claim an asset already in another workflow.
create or replace function public.asset_guard_workflow_start()
returns trigger language plpgsql security invoker set search_path='' as $$
declare current_state text; starts_work boolean := false;
begin
  if tg_op='UPDATE' and new.item_code is distinct from old.item_code then
    raise exception 'The item code of an existing workflow cannot be changed';
  end if;
  select a.operational_status into current_state from public.asset_stock_taking a
    where a.item_code=new.item_code for update;
  if tg_table_name='asset_checkouts' then
    starts_work := not new.is_checked_in and
      (tg_op='INSERT' or old.is_checked_in);
  elsif tg_table_name='asset_reservations' then
    starts_work := new.is_active and (tg_op='INSERT' or not old.is_active);
  else
    starts_work := lower(trim(new.status)) not in ('completed','closed','done') and
      (tg_op='INSERT' or lower(trim(old.status)) in ('completed','closed','done'));
  end if;
  if starts_work and (current_state is null or
      (current_state<>'Available' and not
        (tg_table_name='asset_maintenance' and current_state='Maintenance'))) then
    raise exception 'Asset is no longer available for this operation. Refresh and try again.';
  end if;
  return new;
end;
$$;

-- This runs in the same transaction as the workflow record. Completing one
-- maintenance job keeps Maintenance while another job is still open.
create or replace function public.asset_refresh_operational_status()
returns trigger language plpgsql security invoker set search_path='' as $$
declare code text; current_state text; next_state text;
begin
  if tg_op='DELETE' then code := old.item_code; else code := new.item_code; end if;
  select a.operational_status into current_state from public.asset_stock_taking a
    where a.item_code=code for update;
  if not found or current_state in ('Disposed','Sold','Lost') then return null; end if;
  if exists(select 1 from public.asset_checkouts c where c.item_code=code and not c.is_checked_in) then
    next_state := 'Checked Out';
  elsif exists(select 1 from public.asset_reservations r where r.item_code=code and r.is_active) then
    next_state := 'Reserved';
  elsif exists(select 1 from public.asset_maintenance m where m.item_code=code
        and lower(trim(m.status)) not in ('completed','closed','done')) then
    next_state := 'Maintenance';
  else next_state := 'Available'; end if;
  update public.asset_stock_taking set operational_status=next_state
    where item_code=code and operational_status is distinct from next_state;
  return null;
end;
$$;

create trigger asset_checkout_guard before insert or update on public.asset_checkouts
  for each row execute function public.asset_guard_workflow_start();
create trigger asset_reservation_guard before insert or update on public.asset_reservations
  for each row execute function public.asset_guard_workflow_start();
create trigger asset_maintenance_guard before insert or update on public.asset_maintenance
  for each row execute function public.asset_guard_workflow_start();
create trigger asset_checkout_state after insert or update or delete on public.asset_checkouts
  for each row execute function public.asset_refresh_operational_status();
create trigger asset_reservation_state after insert or update or delete on public.asset_reservations
  for each row execute function public.asset_refresh_operational_status();
create trigger asset_maintenance_state after insert or update or delete on public.asset_maintenance
  for each row execute function public.asset_refresh_operational_status();
revoke all on function public.asset_preserve_physical_condition() from public;
revoke all on function public.asset_guard_workflow_start() from public;
revoke all on function public.asset_refresh_operational_status() from public;

-- Location change and reservation release must succeed together. Neither step
-- writes the physical condition or restores an old condition snapshot.
create or replace function public.asset_transfer_reservation(p_reservation_id bigint)
returns void language plpgsql security invoker set search_path='' as $$
declare reservation public.asset_reservations; current_state text;
begin
  select * into reservation from public.asset_reservations
    where id=p_reservation_id and is_active for update;
  if not found then raise exception 'Reservation is no longer active'; end if;
  if nullif(trim(reservation.target_location),'') is null then
    raise exception 'Reservation has no destination';
  end if;
  select operational_status into current_state from public.asset_stock_taking
    where item_code=reservation.item_code for update;
  if current_state is distinct from 'Reserved' then
    raise exception 'Asset is no longer reserved for this operation';
  end if;
  update public.asset_stock_taking set location=trim(reservation.target_location),project_name=''
    where item_code=reservation.item_code;
  update public.asset_reservations set is_active=false,released_at=now(),resolution='transferred'
    where id=reservation.id;
end;
$$;
revoke all on function public.asset_transfer_reservation(bigint) from public;
grant execute on function public.asset_transfer_reservation(bigint) to authenticated;

comment on column public.asset_stock_taking.status is
  'Physical condition only. Never overwritten by checkout, reservation, maintenance or disposal.';
comment on column public.asset_stock_taking.operational_status is
  'Workflow state. Updated atomically by workflow triggers; independent of physical condition.';
comment on column public.asset_stock_taking.legacy_status_before_separation is
  'Immutable pre-separation snapshot for audit and manual recovery of Unknown conditions.';
commit;
