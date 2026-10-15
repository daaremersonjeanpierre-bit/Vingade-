-- VINGADE+ — schéma de départ Supabase
-- À exécuter dans Supabase > SQL Editor, avec un projet neuf ou après vérification.
-- IMPORTANT : ne jamais exposer la clé service_role dans le navigateur.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Membre Vingade+',
  role text not null default 'user' check (role in ('user','creator','admin')),
  avatar_url text,
  bio text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.movies (
  id uuid primary key default gen_random_uuid(),
  created_by uuid references public.profiles(id) on delete set null,
  title text not null check (char_length(title) between 1 and 160),
  description text not null default '',
  category text not null default 'Autre',
  poster_url text,
  video_url text,
  release_year integer check (release_year is null or release_year between 1888 and 2100),
  duration_minutes integer check (duration_minutes is null or duration_minutes between 1 and 1000),
  status text not null default 'draft' check (status in ('draft','pending','published','rejected','suspended')),
  rights_confirmed boolean not null default false,
  rights_notes text not null default '',
  views_count bigint not null default 0 check (views_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.favorites (
  user_id uuid not null references public.profiles(id) on delete cascade,
  movie_id uuid not null references public.movies(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id,movie_id)
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  movie_id uuid not null references public.movies(id) on delete cascade,
  body text not null check (char_length(body) between 2 and 2000),
  is_hidden boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ratings (
  user_id uuid not null references public.profiles(id) on delete cascade,
  movie_id uuid not null references public.movies(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id,movie_id)
);

create table if not exists public.creator_applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 100),
  message text not null check (char_length(message) between 20 and 1500),
  portfolio_url text,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists movies_status_created_idx on public.movies(status,created_at desc);
create index if not exists movies_creator_idx on public.movies(created_by,created_at desc);
create index if not exists comments_movie_date_idx on public.comments(movie_id,created_at desc);
create index if not exists creator_apps_status_idx on public.creator_applications(status,created_at desc);

-- Crée automatiquement un profil après l'inscription Auth.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id,display_name,role)
  values (new.id, coalesce(nullif(new.raw_user_meta_data->>'display_name',''),'Membre Vingade+'),'user')
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin');
$$;

-- Empêche les utilisateurs de s'attribuer eux-mêmes un rôle privilégié.
create or replace function public.guard_profile_role()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.role is distinct from old.role and auth.uid() is not null and not public.is_admin() then
    raise exception 'Seul un administrateur peut modifier les rôles.';
  end if;
  new.updated_at = now();
  return new;
end;
$$;
drop trigger if exists guard_profile_role_trigger on public.profiles;
create trigger guard_profile_role_trigger before update on public.profiles
for each row execute procedure public.guard_profile_role();

-- Timestamps automatiques.
create or replace function public.touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$ begin new.updated_at=now(); return new; end; $$;
drop trigger if exists touch_profiles on public.profiles;
create trigger touch_profiles before update on public.profiles for each row execute procedure public.touch_updated_at();
drop trigger if exists touch_movies on public.movies;
create trigger touch_movies before update on public.movies for each row execute procedure public.touch_updated_at();
drop trigger if exists touch_comments on public.comments;
create trigger touch_comments before update on public.comments for each row execute procedure public.touch_updated_at();
drop trigger if exists touch_ratings on public.ratings;
create trigger touch_ratings before update on public.ratings for each row execute procedure public.touch_updated_at();

alter table public.profiles enable row level security;
alter table public.movies enable row level security;
alter table public.favorites enable row level security;
alter table public.comments enable row level security;
alter table public.ratings enable row level security;
alter table public.creator_applications enable row level security;

-- Profiles : l'utilisateur lit son profil; l'admin gère les profils.
drop policy if exists profiles_select_own_or_admin on public.profiles;
create policy profiles_select_own_or_admin on public.profiles for select to authenticated using (id=auth.uid() or public.is_admin());
drop policy if exists profiles_update_own_or_admin on public.profiles;
create policy profiles_update_own_or_admin on public.profiles for update to authenticated using (id=auth.uid() or public.is_admin()) with check (id=auth.uid() or public.is_admin());
drop policy if exists profiles_public_creator_names on public.profiles;
create policy profiles_public_creator_names on public.profiles for select to anon,authenticated using (role='creator' or role='admin');

-- Films : public ne voit que les œuvres publiées; créateur gère ses brouillons/en attente/refusées; admin tout gère.
drop policy if exists movies_read_published on public.movies;
create policy movies_read_published on public.movies for select to anon,authenticated using (status='published' or created_by=auth.uid() or public.is_admin());
drop policy if exists movies_creator_insert on public.movies;
create policy movies_creator_insert on public.movies for insert to authenticated with check (created_by=auth.uid() and status in ('draft','pending'));
drop policy if exists movies_creator_update on public.movies;
create policy movies_creator_update on public.movies for update to authenticated using (created_by=auth.uid() and status in ('draft','pending','rejected')) with check (created_by=auth.uid() and status in ('draft','pending','rejected'));
drop policy if exists movies_admin_manage on public.movies;
create policy movies_admin_manage on public.movies for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Favoris privés.
drop policy if exists favorites_own_all on public.favorites;
create policy favorites_own_all on public.favorites for all to authenticated using (user_id=auth.uid() or public.is_admin()) with check (user_id=auth.uid() or public.is_admin());

-- Commentaires visibles s'ils ne sont pas masqués; auteur peut publier/modifier ses messages; admin modère.
drop policy if exists comments_read_visible on public.comments;
create policy comments_read_visible on public.comments for select to anon,authenticated using (is_hidden=false or user_id=auth.uid() or public.is_admin());
drop policy if exists comments_insert_own on public.comments;
create policy comments_insert_own on public.comments for insert to authenticated with check (user_id=auth.uid());
drop policy if exists comments_update_own_or_admin on public.comments;
create policy comments_update_own_or_admin on public.comments for update to authenticated using (user_id=auth.uid() or public.is_admin()) with check (user_id=auth.uid() or public.is_admin());
drop policy if exists comments_delete_own_or_admin on public.comments;
create policy comments_delete_own_or_admin on public.comments for delete to authenticated using (user_id=auth.uid() or public.is_admin());

-- Évaluations.
drop policy if exists ratings_read_all on public.ratings;
create policy ratings_read_all on public.ratings for select to anon,authenticated using (true);
drop policy if exists ratings_insert_own on public.ratings;
create policy ratings_insert_own on public.ratings for insert to authenticated with check (user_id=auth.uid());
drop policy if exists ratings_update_own on public.ratings;
create policy ratings_update_own on public.ratings for update to authenticated using (user_id=auth.uid() or public.is_admin()) with check (user_id=auth.uid() or public.is_admin());
drop policy if exists ratings_delete_own on public.ratings;
create policy ratings_delete_own on public.ratings for delete to authenticated using (user_id=auth.uid() or public.is_admin());

-- Candidatures : candidat voit sa candidature; admin peut lire, accepter ou refuser.
drop policy if exists applications_insert_own on public.creator_applications;
create policy applications_insert_own on public.creator_applications for insert to authenticated with check (user_id=auth.uid() and status='pending');
drop policy if exists applications_read_own_or_admin on public.creator_applications;
create policy applications_read_own_or_admin on public.creator_applications for select to authenticated using (user_id=auth.uid() or public.is_admin());
drop policy if exists applications_admin_update on public.creator_applications;
create policy applications_admin_update on public.creator_applications for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- GRANT standard pour la Data API; RLS continue de contrôler chaque ligne.
grant usage on schema public to anon, authenticated;
grant select on public.movies to anon,authenticated;
grant select on public.profiles to authenticated,anon;
grant insert,update,delete on public.profiles to authenticated;
grant insert,update,delete,select on public.movies to authenticated;
grant select,insert,delete on public.favorites to authenticated;
grant select,insert,update,delete on public.comments to authenticated;
grant select,insert,update,delete on public.ratings to authenticated;
grant select,insert,update on public.creator_applications to authenticated;

-- APRÈS avoir créé ton compte, remplace l'e-mail ci-dessous puis exécute cette commande
-- séparément pour donner le rôle administrateur à TON compte. Ne publie jamais cette valeur en JS.
-- update public.profiles p set role='admin' from auth.users u where p.id=u.id and u.email='TON-EMAIL-ICI';
