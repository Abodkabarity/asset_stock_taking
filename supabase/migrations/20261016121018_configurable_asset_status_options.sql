begin;

create table public.asset_status_options (
  value text primary key check (value=btrim(value) and length(value) between 1 and 80),
  label text not null check (label=btrim(label) and length(label) between 1 and 80),
  kind text not null check (kind in ('condition','operation')),
  is_active boolean not null default true,
  sort_order integer not null default 0 check (sort_order>=0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint asset_status_option_meaning check (
    (kind='operation' and value in ('Available','Maintenance','Checked Out','Reserved','Disposed','Lost','Sold','Assigned'))
    or (kind='condition' and lower(value) not in ('available','maintenance','under maintenance','in maintenance','checked out','reserved','disposed','lost','sold','assigned'))
  )
);
create unique index asset_status_value_case_unique on public.asset_status_options(lower(value));
create unique index asset_status_active_label_unique on public.asset_status_options(lower(label)) where is_active;

insert into public.asset_status_options(value,label,kind,sort_order) values
  ('Maintenance','Under Maintenance','operation',0),
  ('Damaged','Damaged','condition',1),
  ('Lost','Lost','operation',2),
  ('Disposed','Disposed','operation',3),
  ('Sold','Sold','operation',4),
  ('New','New','condition',5),
  ('Good','Good','condition',6),
  ('Assigned','Assigned','operation',7);

-- Public labels contain no asset or account data. Only active application
-- administrators may manage the catalog; removal is reversible retirement.
alter table public.asset_status_options enable row level security;
revoke all on table public.asset_status_options from anon, authenticated;
grant select on table public.asset_status_options to anon, authenticated;
grant insert,update on table public.asset_status_options to authenticated;
create policy asset_status_options_read on public.asset_status_options
  for select to anon, authenticated using (true);
create policy asset_status_options_admin_insert on public.asset_status_options
  for insert to authenticated with check ((select public.is_active_app_admin((select auth.uid()))));
create policy asset_status_options_admin_update on public.asset_status_options
  for update to authenticated
  using ((select public.is_active_app_admin((select auth.uid()))))
  with check ((select public.is_active_app_admin((select auth.uid()))));

create function public.asset_status_option_preserve_meaning()
returns trigger language plpgsql security invoker set search_path='' as $$
begin
  if new.value is distinct from old.value or new.kind is distinct from old.kind then
    raise exception 'A status meaning cannot be changed. Rename its label or add a new status.';
  end if;
  new.updated_at := now();
  return new;
end;
$$;
create trigger asset_status_option_preserve_meaning before update on public.asset_status_options
  for each row execute function public.asset_status_option_preserve_meaning();
revoke all on function public.asset_status_option_preserve_meaning() from public;

create trigger app_audit_trigger after insert or update or delete on public.asset_status_options
  for each row execute function public.capture_app_audit();

comment on table public.asset_status_options is
  'Configurable status labels. Stable values preserve physical condition and workflow semantics. is_active=false removes a choice without changing historical assets.';
commit;
