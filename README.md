# Vingade+ — version de départ pour Vercel

Cette archive contient une application web responsive avec une page d'accueil cinématographique, catalogue lié à Supabase, inscription/connexion, favoris synchronisés, fiche œuvre, commentaires, notes, tableau de bord administrateur et espace créateur avec candidatures et soumission de contenus.

## À savoir avant le déploiement

- Le site est une **base réelle à configurer**, pas un service de streaming prêt à exploiter sans compte fournisseur.
- Le catalogue ne contient volontairement aucun faux film. Il affiche uniquement les œuvres de la table `movies` dont le statut est `published`.
- Pour que l'authentification, les données, les favoris, notes, commentaires et rôles fonctionnent, configure Supabase et exécute `supabase-schema.sql`.
- La lecture du film utilise l'URL `video_url` fournie pour chaque œuvre. Pour une diffusion stable et protégée, configure un hébergeur vidéo (par exemple Bunny Stream) et ses URL de lecture autorisées. Ce paquet ne crée pas un compte hébergeur, n'importe pas les films et ne déverrouille pas les droits de diffusion.
- N'importe que les œuvres dont tu possèdes les droits ou une autorisation écrite.
- Le suivi automatique des vues n'est pas implémenté dans cette version; les statistiques de vues sont donc indicatives / non alimentées.
- L'espace admin n'a pas de compte prédéfini. Crée un compte normal, puis attribue le rôle admin avec la requête commentée à la fin du SQL.

## 1. Supabase

1. Crée un projet Supabase.
2. Ouvre `supabase-schema.sql`, copie son contenu dans **SQL Editor** de Supabase et exécute-le.
3. Dans Supabase, récupère l'URL du projet et la clé publique `anon` (ou `publishable`). Ne prends jamais la clé `service_role` / secrète.
4. Ouvre `js/config.js` et remplace `SUPABASE_URL` et `SUPABASE_ANON_KEY`.
5. Crée ton compte Vingade+ depuis `/pages/inscription.html`.
6. Dans SQL Editor, adapte et exécute séparément la requête tout à la fin de `supabase-schema.sql` en remplaçant `TON-EMAIL-ICI` par l'adresse de ton compte. Cela te donne le rôle administrateur.
7. Dans Supabase Auth, configure les URL du site et les URL de redirection vers le domaine Vercel quand il existe. Durant les tests, ajoute aussi ton URL de développement autorisée.

## 2. Déployer sur Vercel depuis le téléphone

Vercel n'utilise pas forcément un ZIP comme un éditeur de code : le parcours standard est de pousser le dossier dans un dépôt Git puis d'importer ce dépôt dans Vercel.

1. Décompresse `vingade-plus.zip`.
2. Crée un dépôt GitHub et ajoute **tout le contenu du dossier** à la racine du dépôt (il faut voir `index.html`, `vercel.json`, `css/`, `js/`, `pages/` et `supabase-schema.sql` à la racine, pas un dossier `vingade-plus/vingade-plus/` supplémentaire).
3. Dans Vercel, choisis **Add New → Project**, importe le dépôt GitHub et lance le déploiement.
4. Aucun build command ni framework spécialisé n'est requis : c'est un site HTML/CSS/JavaScript statique. Laisse les réglages par défaut de site statique si Vercel les détecte; le dossier de sortie est la racine (`.`).
5. Après le déploiement, ouvre l'URL Vercel et teste les pages.

## 3. Routes utiles

- Accueil : `/`
- Connexion : `/pages/connexion.html`
- Inscription : `/pages/inscription.html`
- Ma liste : `/pages/favoris.html`
- Profil : `/pages/profil.html`
- Candidature créateur : `/pages/createur/candidature.html`
- Espace créateur : `/pages/createur/index.html`
- Administration : `/pages/admin/index.html`

## 4. Ajouter une œuvre

Après avoir attribué le rôle `creator` à un profil via l'administration ou SQL, le créateur peut ouvrir l'espace créateur et envoyer une œuvre. Elle restera en attente jusqu'à validation par un admin. L'administrateur doit vérifier les autorisations, puis cliquer sur Publier.

L'URL vidéo doit provenir d'un fournisseur vidéo configuré et être autorisée à la lecture dans un navigateur. Un lien de page privée du tableau de bord n'est généralement pas une URL de lecture valable.

## 5. Vérifications de sécurité avant de lancer au public

- Active et vérifie les politiques RLS.
- Garde la clé `service_role` hors du navigateur et de GitHub.
- Vérifie que seul un admin peut changer les rôles et publier des œuvres.
- Configure la protection des vidéos, les droits de diffusion, la confidentialité, les conditions d'utilisation et une politique de signalement.
- Teste avec un compte utilisateur, un créateur et un administrateur distincts.
- Configure e-mail de confirmation et récupération de mot de passe dans Supabase Auth.

## Dépannage

- **Catalogue vide** : normal tant qu'aucune œuvre n'est publiée; vérifie aussi la configuration `js/config.js`.
- **Erreur 401/403** : confirme l'URL/clé publique et la politique RLS de la table concernée.
- **Connexion après confirmation d'e-mail** : vérifie les URL Auth de Supabase.
- **Vidéos non lues** : l'URL peut exiger une signature, être bloquée par CORS ou ne pas être un lien de lecture. Configure l'intégration de l'hébergeur.
- **Page admin inaccessible** : attribue `role='admin'` au profil correspondant dans Supabase.
