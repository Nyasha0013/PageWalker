-- Pagewalker Book Clubs (Prompt 2 of Feature Pack)
-- Run this in Supabase SQL editor.

CREATE TABLE IF NOT EXISTS book_clubs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  cover_emoji TEXT DEFAULT '📚',
  created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
  current_book_id TEXT REFERENCES books(id),
  invite_code TEXT UNIQUE DEFAULT substring(gen_random_uuid()::text, 1, 8),
  is_private BOOLEAN DEFAULT TRUE,
  max_members INT DEFAULT 20,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS book_club_members (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  club_id UUID REFERENCES book_clubs(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT CHECK (role IN ('admin', 'member')) DEFAULT 'member',
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(club_id, user_id)
);

CREATE TABLE IF NOT EXISTS book_club_messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  club_id UUID REFERENCES book_clubs(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  message_type TEXT CHECK (message_type IN ('text', 'reaction', 'poll', 'progress_update')) DEFAULT 'text',
  contains_spoiler BOOLEAN DEFAULT FALSE,
  chapter_ref INT,
  reply_to_id UUID REFERENCES book_club_messages(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS book_club_polls (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  club_id UUID REFERENCES book_clubs(id) ON DELETE CASCADE,
  created_by UUID REFERENCES profiles(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  ends_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS book_club_poll_options (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  poll_id UUID REFERENCES book_club_polls(id) ON DELETE CASCADE,
  book_id TEXT REFERENCES books(id),
  label TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS book_club_poll_votes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  poll_id UUID REFERENCES book_club_polls(id) ON DELETE CASCADE,
  option_id UUID REFERENCES book_club_poll_options(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  UNIQUE(poll_id, user_id)
);

-- Enable RLS
ALTER TABLE book_clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_club_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_club_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_club_polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_club_poll_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_club_poll_votes ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Club members can see club" ON book_clubs
FOR SELECT USING (
  id IN (SELECT club_id FROM book_club_members WHERE user_id = auth.uid())
);

CREATE POLICY "Anyone can create club" ON book_clubs
FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Members see messages" ON book_club_messages
FOR SELECT USING (
  club_id IN (SELECT club_id FROM book_club_members WHERE user_id = auth.uid())
);

CREATE POLICY "Members send messages" ON book_club_messages
FOR INSERT WITH CHECK (
  auth.uid() = user_id AND
  club_id IN (SELECT club_id FROM book_club_members WHERE user_id = auth.uid())
);

CREATE POLICY "Members see polls" ON book_club_polls
FOR SELECT USING (
  club_id IN (SELECT club_id FROM book_club_members WHERE user_id = auth.uid())
);

CREATE POLICY "Members vote" ON book_club_poll_votes
FOR ALL USING (auth.uid() = user_id);

