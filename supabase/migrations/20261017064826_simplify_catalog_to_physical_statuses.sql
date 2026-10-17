begin;

alter table public.asset_status_options drop constraint asset_status_option_meaning;
create or replace function public.asset_status_option_preserve_meaning()
returns trigger language plpgsql security invoker set search_path='' as $$
begin
  if new.value is distinct from old.value or new.kind<>'condition' then
    raise exception 'A status meaning cannot be changed. Rename its label or add a new status.';
  end if;
  new.updated_at := now();
  return new;
end;
$$;
update public.asset_status_options set kind='condition' where kind<>'condition';
alter table public.asset_status_options alter column kind set default 'condition';
alter table public.asset_status_options add constraint asset_status_option_meaning check (kind='condition');

-- All status names are physical, even when a name matches a workflow state.
-- Workflow pages continue to write operational_status independently.
create or replace function public.asset_preserve_physical_condition()
returns trigger language plpgsql security invoker set search_path='' as $$
begin
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
comment on table public.asset_status_options is
  'Physical status names only. Renaming changes labels, retirement removes choices, and workflow availability stays independent.';
commit;
