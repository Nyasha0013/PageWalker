-- Star ratings on reviews (web + app). Idempotent.
ALTER TABLE public.reviews
  ADD COLUMN IF NOT EXISTS star_rating DOUBLE PRECISION;

COMMENT ON COLUMN public.reviews.star_rating IS
  '1–5 star rating; used by web (social) and mobile.';
