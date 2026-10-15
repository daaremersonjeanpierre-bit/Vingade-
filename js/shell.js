import { supabase } from "./supabase.js";
const accountLink=document.getElementById("account-link");
if(accountLink && supabase){ supabase.auth.getUser().then(async({data:{user}})=>{if(!user)return; const {data:p}=await supabase.from("profiles").select("role,display_name").eq("id",user.id).maybeSingle(); accountLink.href=p?.role==="admin"?"/pages/admin/index.html":p?.role==="creator"?"/pages/createur/index.html":"/pages/profil.html"; accountLink.textContent=p?.display_name||"Mon compte"; }); }
document.querySelectorAll("[data-signout]").forEach(btn=>btn.addEventListener("click",async()=>{if(supabase)await supabase.auth.signOut();location.href="/";}));
