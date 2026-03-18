-- PAGEWALKER — UPGRADE 5: ACHIEVEMENTS & BADGES
-- Run this in Supabase SQL editor.

create table if not exists achievements (
  id text primary key,
  name text not null,
  description text not null,
  icon text not null,
  category text not null, -- 'reading', 'social', 'streak', 'special'
  threshold int
);

create table if not exists user_achievements (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references profiles(id) on delete cascade,
  achievement_id text references achievements(id),
  unlocked_at timestamptz default now(),
  unique (user_id, achievement_id)
);

alter table user_achievements enable row level security;

drop policy if exists "Users see own achievements" on user_achievements;
create policy "Users see own achievements" on user_achievements
for all
using (auth.uid() = user_id);

drop policy if exists "Achievements are public" on user_achievements;
create policy "Achievements are public" on user_achievements
for select
using (true);

insert into achievements (id, name, description, icon, category, threshold) values
('first_book', 'First Chapter', 'Log your very first book', '📖', 'reading', 1),
('books_5', 'Bookworm', 'Read 5 books', '🐛', 'reading', 5),
('books_10', 'Page Turner', 'Read 10 books', '📚', 'reading', 10),
('books_25', 'Story Collector', 'Read 25 books', '🗃️', 'reading', 25),
('books_50', 'Literary Legend', 'Read 50 books', '🏛️', 'reading', 50),
('books_100', 'Century Reader', 'Read 100 books', '💯', 'reading', 100),
('streak_7', 'Week Warrior', '7 day reading streak', '🔥', 'streak', 7),
('streak_30', 'Monthly Maven', '30 day reading streak', '🌙', 'streak', 30),
('streak_100', 'Unstoppable', '100 day reading streak', '⚡', 'streak', 100),
('god_tier_1', 'Picky Reader', 'Give your first God Tier rating', '✨', 'reading', 1),
('god_tier_5', 'Selective Soul', '5 God Tier books', '👑', 'reading', 5),
('first_review', 'Book Critic', 'Write your first review', '🖋️', 'social', 1),
('reviews_10', 'Vocal Reader', 'Write 10 reviews', '📣', 'social', 10),
('first_follow', 'Book Friend', 'Follow your first reader', '🤝', 'social', 1),
('followers_10', 'Rising Star', 'Get 10 followers', '🌟', 'social', 10),
('scanner_1', 'Scan Master', 'Scan your first book barcode', '🔎', 'special', 1),
('night_owl', 'Night Owl', 'Log a reading session after midnight', '🦉', 'special', 1),
('speed_reader', 'Speed Reader', 'Read a book in under 24 hours', '💨', 'special', 1),
('dnf_3', 'No Regrets', 'DNF 3 books — life is too short!', '🧨', 'reading', 3),
('tbr_20', 'TBR Hoarder', 'Add 20 books to your TBR', '🧺', 'reading', 20)
on conflict (id) do nothing;

