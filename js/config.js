// Configuration publique. Ne place JAMAIS une clé service_role ici.
export const SUPABASE_URL = "https://ntpfcrzumcofbkwwvjdy.supabase.co";
export const SUPABASE_ANON_KEY = "sb_publishable_pmASWlD4QoEF_vyDJP6ZwQ_oeY0Xmcz";
// Hébergeur vidéo : les URL des vidéos autorisées peuvent être stockées dans la table movies.
export const SITE_NAME = "Vingade+";
export const isConfigured = () => SUPABASE_URL.startsWith("https://") && !SUPABASE_URL.includes("REMPLACE-MOI") && SUPABASE_ANON_KEY.length > 20 && !SUPABASE_ANON_KEY.includes("REMPLACE_");
