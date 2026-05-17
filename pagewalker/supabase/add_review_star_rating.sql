-- Optional: enables optional star ratings on reviews (e.g. Gutenberg reader comments).
alter table public.reviews
  add column if not exists star_rating double precision;
