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

-- ── Events table ─────────────────────────────────────────────────
create table public.events (
  id          text primary key,
  title       text not null,
  type        text not null default 'event'
    check (type in ('event', 'holiday', 'personal', 'holy')),
  date        text not null,
  icon        text default '✦',
  description text default '',
  added_by    text,
  added_at    timestamptz default now()
);

alter table public.events enable row level security;

-- All authenticated users can read events
create policy "Authenticated users can read events"
  on public.events for select
  using (auth.role() = 'authenticated');

-- Only admin and ceo can insert/update/delete
create policy "Editors can insert events"
  on public.events for insert
  with check (
    exists (select 1 from public.profiles where id = auth.uid() and role in ('admin','ceo'))
  );

create policy "Editors can update events"
  on public.events for update
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role in ('admin','ceo'))
  );

create policy "Editors can delete events"
  on public.events for delete
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role in ('admin','ceo'))
  );

-- ── Attachments table ────────────────────────────────────────────
create table public.attachments (
  id           uuid primary key default gen_random_uuid(),
  event_id     text references public.events on delete cascade,
  name         text not null,
  mime_type    text,
  size_bytes   bigint,
  storage_path text not null
);

alter table public.attachments enable row level security;

create policy "Authenticated users can read attachments"
  on public.attachments for select
  using (auth.role() = 'authenticated');

create policy "Editors can insert attachments"
  on public.attachments for insert
  with check (
    exists (select 1 from public.profiles where id = auth.uid() and role in ('admin','ceo'))
  );

create policy "Editors can delete attachments"
  on public.attachments for delete
  using (
    exists (select 1 from public.profiles where id = auth.uid() and role in ('admin','ceo'))
  );

-- ── Storage bucket ───────────────────────────────────────────────
-- Run this separately or create manually in Dashboard → Storage
insert into storage.buckets (id, name, public)
  values ('event-attachments', 'event-attachments', false)
  on conflict do nothing;

create policy "Authenticated users can read files"
  on storage.objects for select
  using (bucket_id = 'event-attachments' and auth.role() = 'authenticated');

create policy "Editors can upload files"
  on storage.objects for insert
  with check (
    bucket_id = 'event-attachments' and
    exists (select 1 from public.profiles where id = auth.uid() and role in ('admin','ceo'))
  );

create policy "Editors can delete files"
  on storage.objects for delete
  using (
    bucket_id = 'event-attachments' and
    exists (select 1 from public.profiles where id = auth.uid() and role in ('admin','ceo'))
  );
