class Env {
  Env._();

  // ─── Supabase (required for auth & data) ─────────────────────────────
  // Get these from: Supabase Dashboard → your project → Settings → API
  //   • Project URL → paste into supabaseUrl (e.g. https://abcdefgh.supabase.co)
  //   • anon public key → paste into supabaseAnonKey
  // Do NOT commit real keys to version control.
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Optional (for books search / AI features)
  static const String googleBooksApiKey = 'YOUR_GOOGLE_BOOKS_API_KEY';
  static const String openAiKey = 'YOUR_OPENAI_API_KEY';
}

