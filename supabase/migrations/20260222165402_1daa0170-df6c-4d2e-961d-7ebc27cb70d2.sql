
create table public.admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  action text not null,
  details text,
  created_at timestamptz not null default now()
);

alter table public.admin_audit_log enable row level security;

create policy "Admins can read audit logs"
  on public.admin_audit_log for select
  using (public.has_role(auth.uid(), 'admin'));

create policy "Admins can insert audit logs"
  on public.admin_audit_log for insert
  with check (public.has_role(auth.uid(), 'admin'));
