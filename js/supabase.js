import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm";
import { SUPABASE_URL, SUPABASE_ANON_KEY, isConfigured } from "./config.js";
export const supabase = isConfigured() ? createClient(SUPABASE_URL, SUPABASE_ANON_KEY, { auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true } }) : null;
export { isConfigured };
export async function requireUser() {
  if (!supabase) { location.href = "/pages/connexion.html"; return null; }
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) { const next = encodeURIComponent(location.pathname + location.search); location.href = `/pages/connexion.html?next=${next}`; return null; }
  const { data: profile } = await supabase.from("profiles").select("id,display_name,role,avatar_url,bio").eq("id", user.id).maybeSingle();
  return { user, profile };
}
export async function requireRole(roles) {
  const session = await requireUser();
  if (!session) return null;
  if (!session.profile || !roles.includes(session.profile.role)) { document.body.innerHTML = `<main class="page-wrap"><section class="panel"><h1>Accès refusé</h1><p>Ce compte n'a pas l'autorisation d'ouvrir cette page.</p><a class="btn btn-primary" href="/">Retour à l'accueil</a></section></main>`; return null; }
  return session;
}
