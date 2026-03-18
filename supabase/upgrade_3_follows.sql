-- PAGEWALKER — UPGRADE 3: FRIEND SYSTEM & FOLLOWING
-- Run this in Supabase SQL editor.

create table if not exists follows (
  id uuid default gen_random_uuid() primary key,
  follower_id uuid references profiles(id) on delete cascade,
  following_id uuid references profiles(id) on delete cascade,
  created_at timestamptz default now(),
  unique (follower_id, following_id)
);

alter table follows enable row level security;

drop policy if exists "Users manage own follows" on follows;
create policy "Users manage own follows" on follows
for all
using (auth.uid() = follower_id);

drop policy if exists "Follows are public" on follows;
create policy "Follows are public" on follows
for select
using (true);

-- Optional stats view: follower/following counts + books read count.
create or replace view profile_stats as
select
  p.id,
  p.username,
  p.display_name,
  p.avatar_url,
  p.bio,
  p.location,
  p.instagram_handle,
  p.is_public,
  count(distinct f1.follower_id) as followers_count,
  count(distinct f2.following_id) as following_count,
  count(distinct ub.id) as books_read_count
from profiles p
left join follows f1 on f1.following_id = p.id
left join follows f2 on f2.follower_id = p.id
left join user_books ub on ub.user_id = p.id and ub.status = 'read'
group by p.id;

