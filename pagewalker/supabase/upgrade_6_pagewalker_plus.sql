-- Pagewalker Plus subscription flag on profiles.
-- Set is_plus = true (and optional plus_expires_at) after Play Billing confirms payment.

alter table public.profiles
  add column if not exists is_plus boolean not null default false,
  add column if not exists plus_expires_at timestamptz;

comment on column public.profiles.is_plus is 'Pagewalker Plus subscriber';
comment on column public.profiles.plus_expires_at is 'When Plus access ends; null = no expiry set';
