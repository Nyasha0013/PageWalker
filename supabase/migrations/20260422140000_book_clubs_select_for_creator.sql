-- After INSERT, PostgREST runs SELECT/RETURNING on the new row. The old policy only allowed
-- rows where the user was already in book_club_members — so a brand-new club was invisible
-- until the second insert, causing "new row violates row-level security" on book_clubs.
-- This replaces SELECT with: creator, members, or public listed clubs.
DROP POLICY IF EXISTS "Club members can see club" ON public.book_clubs;
DROP POLICY IF EXISTS "book_clubs_select" ON public.book_clubs;
CREATE POLICY "book_clubs_select"
  ON public.book_clubs
  FOR SELECT
  TO authenticated
  USING (
    created_by = auth.uid()
    OR id IN (SELECT club_id FROM public.book_club_members WHERE user_id = auth.uid())
    OR is_private = false
  );
