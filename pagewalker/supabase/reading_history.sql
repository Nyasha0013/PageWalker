-- Unified book reading history (sync across devices).
create table if not exists public.reading_history (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles (id) on delete cascade not null,
  book_id text not null,
  book_title text not null,
  book_author text,
  source text not null,
  last_read_at timestamptz default now(),
  scroll_position float default 0,
  is_finished boolean default false,
  unique (user_id, book_id)
);

alter table public.reading_history enable row level security;

create policy "Users manage own reading history"
  on public.reading_history
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
