// Configuration publique. Ne place JAMAIS une clé service_role ici.
export const SUPABASE_URL = "https://REMPLACE-MOI.supabase.co";
export const SUPABASE_ANON_KEY = "REMPLACE_PAR_TA_CLE_PUBLIQUE_ANON_OU_PUBLISHABLE";
// Hébergeur vidéo : les URL des vidéos autorisées peuvent être stockées dans la table movies.
export const SITE_NAME = "Vingade+";
export const isConfigured = () => SUPABASE_URL.startsWith("https://") && !SUPABASE_URL.includes("REMPLACE-MOI") && SUPABASE_ANON_KEY.length > 20 && !SUPABASE_ANON_KEY.includes("REMPLACE_");
