import { loadPublicConfig } from "./pw-config.js";

let client;
let createClientFn;

function loadSupabaseLibrary() {
  if (createClientFn) return Promise.resolve(createClientFn);
  if (typeof window !== "undefined" && window.supabase?.createClient) {
    createClientFn = window.supabase.createClient;
    return Promise.resolve(createClientFn);
  }
  return new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = "/js/vendor/supabase.js";
    script.async = true;
    script.onload = () => {
      if (!window.supabase?.createClient) {
        reject(new Error("supabase_load_failed"));
        return;
      }
      createClientFn = window.supabase.createClient;
      resolve(createClientFn);
    };
    script.onerror = () => reject(new Error("supabase_load_failed"));
    document.head.appendChild(script);
  });
}

export async function getSupabase() {
  if (client) return client;
  const cfg = await loadPublicConfig();
  const createClient = await loadSupabaseLibrary();
  client = createClient(cfg.supabaseUrl, cfg.supabaseAnonKey, {
    auth: {
      flowType: "pkce",
      detectSessionInUrl: true,
      persistSession: true,
      autoRefreshToken: true,
      storage: typeof window !== "undefined" ? window.localStorage : undefined,
    },
  });
  return client;
}
