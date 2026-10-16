begin;
alter policy asset_status_options_admin_insert on public.asset_status_options
  with check (
    (select public.is_active_app_admin((select auth.uid())))
    and (select (auth.jwt()->>'is_anonymous')::boolean) is not true
  );
alter policy asset_status_options_admin_update on public.asset_status_options
  using (
    (select public.is_active_app_admin((select auth.uid())))
    and (select (auth.jwt()->>'is_anonymous')::boolean) is not true
  )
  with check (
    (select public.is_active_app_admin((select auth.uid())))
    and (select (auth.jwt()->>'is_anonymous')::boolean) is not true
  );
commit;
