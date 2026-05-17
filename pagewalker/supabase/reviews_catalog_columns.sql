-- denormalized book fields on reviews for catalog-sourced titles

ALTER TABLE reviews ADD COLUMN IF NOT EXISTS book_title TEXT;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS book_author TEXT;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS book_cover_url TEXT;
