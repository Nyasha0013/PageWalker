-- ONE COPY-PASTE for Supabase → SQL → New query → paste all → Run (confirm the “destructive” warning)
-- Use the SAME project as in your app: Dashboard → Project Settings → General → Reference ID
--   must match the project where your supabaseUrl / anon key point.
--
-- If you get: relation "book_club_members" does not exist, run in order:
--   1) book_clubs.sql
--   2) book_clubs_browse_request_join.sql
-- then run this file again.
--
-- Fixes: (A) member RLS infinite recursion, (B) book_clubs insert + member_count trigger under RLS

ALTER TABLE public.book_clubs
  ADD COLUMN IF NOT EXISTS member_count INT NOT NULL DEFAULT 0;

-- (A) book_club_members: drop helper + all policies, recreate safe set
DROP FUNCTION IF EXISTS public.is_book_club_member(uuid, uuid);

DO $$
DECLARE
  p record;
BEGIN
  FOR p IN
    SELECT pol.polname
    FROM pg_policy pol
    JOIN pg_class c ON c.oid = pol.polrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = 'book_club_members'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.book_club_members', p.polname);
  END LOOP;
END $$;

CREATE POLICY "book_club_members_select"
  ON public.book_club_members
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "book_club_members_insert_self"
  ON public.book_club_members
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "book_club_members_insert_creator"
  ON public.book_club_members
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.book_clubs bc
      WHERE bc.id = club_id AND bc.created_by = auth.uid()
    )
  );

-- (B) book_clubs INSERT for authenticated; SECURITY DEFINER counter so member_count can update
DROP POLICY IF EXISTS "Anyone can create club" ON public.book_clubs;
DROP POLICY IF EXISTS "book_clubs_insert" ON public.book_clubs;
CREATE POLICY "book_clubs_insert"
  ON public.book_clubs
  FOR INSERT
  TO authenticated
  WITH CHECK (created_by = auth.uid());

CREATE OR REPLACE FUNCTION public.sync_book_club_member_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.book_clubs
    SET member_count = member_count + 1
    WHERE id = NEW.club_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.book_clubs
    SET member_count = GREATEST(0, member_count - 1)
    WHERE id = OLD.club_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS tr_sync_book_club_member_count ON public.book_club_members;
CREATE TRIGGER tr_sync_book_club_member_count
  AFTER INSERT OR DELETE ON public.book_club_members
  FOR EACH ROW
  EXECUTE PROCEDURE public.sync_book_club_member_count();

COMMENT ON TABLE public.book_club_members IS
  'RLS: see only own member rows. Club listing uses book_clubs + public/member.';
