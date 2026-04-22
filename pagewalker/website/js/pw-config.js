/**
 * Loads Supabase URL + anon key: prefers Vercel /api/config when env is set,
 * otherwise uses window.PAGEWALKER_PUBLIC_CONFIG (public-config.js).
 */
function configFromWindow() {
  const w = window.PAGEWALKER_PUBLIC_CONFIG;
  if (w && w.supabaseUrl && w.supabaseAnonKey) {
    return {
      supabaseUrl: w.supabaseUrl,
      supabaseAnonKey: w.supabaseAnonKey,
      googleBooksApiKey: w.googleBooksApiKey || "",
    };
  }
  return null;
}

export async function loadPublicConfig() {
  try {
    const res = await fetch("/api/config", { cache: "no-store" });
    if (res.ok) {
      const data = await res.json();
      if (data?.supabaseUrl && data?.supabaseAnonKey) {
        return {
          supabaseUrl: data.supabaseUrl,
          supabaseAnonKey: data.supabaseAnonKey,
          googleBooksApiKey: data.googleBooksApiKey || "",
        };
      }
    }
  } catch (_) {
    /* offline or no /api on static host */
  }
  const fallback = configFromWindow();
  if (fallback) return fallback;
  throw new Error("config_missing");
}
