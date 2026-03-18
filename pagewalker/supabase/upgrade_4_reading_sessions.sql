-- PAGEWALKER — UPGRADE 4: READING TIMER
-- Run this in Supabase SQL editor.

create table if not exists reading_sessions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references profiles(id) on delete cascade,
  book_id text references books(id),
  started_at timestamptz not null,
  ended_at timestamptz,
  duration_seconds int,
  pages_read int,
  created_at timestamptz default now()
);

alter table reading_sessions enable row level security;

drop policy if exists "Users manage own sessions" on reading_sessions;
create policy "Users manage own sessions" on reading_sessions
for all
using (auth.uid() = user_id);

