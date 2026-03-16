-- ═══════════════════════════════════════════════════════════════
--  Vindow Almanac — Supabase Schema
--  Run once in: Supabase Dashboard → SQL Editor → New query
-- ═══════════════════════════════════════════════════════════════

-- ── Profiles table ──────────────────────────────────────────────
create table public.profiles (
  id    uuid references auth.users on delete cascade primary key,
  email text,
  role  text not null default 'guest'
    check (role in ('admin', 'ceo', 'guest'))
);

-- ── Row-level security ──────────────────────────────────────────
alter table public.profiles enable row level security;

-- Any authenticated user can read their own profile
create policy "Users can read own profile"
  on public.profiles for select
  using (auth.uid() = id);

-- Admins can read all profiles
create policy "Admins can read all profiles"
  on public.profiles for select
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

-- Admins can update any profile's role
create policy "Admins can update roles"
  on public.profiles for update
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'admin'
    )
  );

-- ── Auto-create profile on signup ───────────────────────────────
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
