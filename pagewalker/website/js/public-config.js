/**
 * Public Supabase client settings (same project as the Pagewalker app).
 * Anon key is safe in the browser; RLS applies on the server.
 * Vercel SUPABASE_* env vars override this when set (see pw-config.js).
 */
window.PAGEWALKER_PUBLIC_CONFIG = {
  supabaseUrl: "https://ahiujuljjbozmfwoqtli.supabase.co",
  supabaseAnonKey:
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFoaXVqdWxqamJvem1md29xdGxpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2MDQ5MDIsImV4cCI6MjA5MTE4MDkwMn0.q_Jz6qnkwuhU5svFDt9JShWN_KUhzc2TNKfSU5fHJOI",
};
