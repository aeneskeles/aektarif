-- TarifUyg Supabase Database Schema
-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- PROFILES TABLE
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  username text unique,
  display_name text,
  avatar_url text,
  bio text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.profiles enable row level security;

create policy "Public profiles are viewable by everyone"
  on public.profiles for select using (true);

create policy "Users can insert their own profile"
  on public.profiles for insert with check (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update using (auth.uid() = id);

-- Handle new user signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, username, display_name)
  values (new.id, new.email, split_part(new.email, '@', 1), split_part(new.email, '@', 1));
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- RECIPES TABLE
create table if not exists public.recipes (
  id text primary key,
  title_en text not null,
  title_tr text,
  description_en text,
  description_tr text,
  steps_en text not null,
  steps_tr text,
  ingredients_raw text[] not null,
  ingredient_keys text[] not null,
  image_url text,
  prep_time int,
  cook_time int,
  servings int,
  difficulty text,
  category text,
  tags text[],
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists recipes_ingredient_keys_gin_idx
  on public.recipes using gin (ingredient_keys);

alter table public.recipes enable row level security;

create policy "Recipes are viewable by everyone"
  on public.recipes for select using (true);

-- POSTS TABLE
create table if not exists public.posts (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  image_url text not null,
  title text not null,
  description text,
  ingredient_keys text[] default '{}',
  recipe_id text references public.recipes(id) on delete set null,
  recipe_title text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists posts_user_id_idx on public.posts(user_id);
create index if not exists posts_created_at_idx on public.posts(created_at desc);

alter table public.posts enable row level security;

create policy "Posts are viewable by everyone"
  on public.posts for select using (true);

create policy "Users can create their own posts"
  on public.posts for insert with check (auth.uid() = user_id);

create policy "Users can update their own posts"
  on public.posts for update using (auth.uid() = user_id);

create policy "Users can delete their own posts"
  on public.posts for delete using (auth.uid() = user_id);

-- LIKES TABLE
create table if not exists public.likes (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  post_id uuid references public.posts(id) on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, post_id)
);

create index if not exists likes_post_id_idx on public.likes(post_id);
create index if not exists likes_user_id_idx on public.likes(user_id);

alter table public.likes enable row level security;

create policy "Likes are viewable by everyone"
  on public.likes for select using (true);

create policy "Users can like posts"
  on public.likes for insert with check (auth.uid() = user_id);

create policy "Users can unlike posts"
  on public.likes for delete using (auth.uid() = user_id);

-- COMMENTS TABLE
create table if not exists public.comments (
  id uuid default uuid_generate_v4() primary key,
  post_id uuid references public.posts(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists comments_post_id_idx on public.comments(post_id);

alter table public.comments enable row level security;

create policy "Comments are viewable by everyone"
  on public.comments for select using (true);

create policy "Users can create comments"
  on public.comments for insert with check (auth.uid() = user_id);

create policy "Users can delete their own comments"
  on public.comments for delete using (auth.uid() = user_id);

-- FUNCTIONS
create or replace function public.get_feed_posts(
  p_user_id uuid default null,
  p_limit int default 20,
  p_offset int default 0
)
returns table (
  id uuid,
  user_id uuid,
  image_url text,
  title text,
  description text,
  ingredient_keys text[],
  recipe_id text,
  recipe_title text,
  created_at timestamp with time zone,
  likes_count bigint,
  comments_count bigint,
  is_liked boolean,
  user_username text,
  user_display_name text,
  user_avatar_url text
)
language sql stable
as $$
  select
    p.id, p.user_id, p.image_url, p.title, p.description,
    p.ingredient_keys, p.recipe_id, p.recipe_title, p.created_at,
    (select count(*) from public.likes l where l.post_id = p.id) as likes_count,
    (select count(*) from public.comments c where c.post_id = p.id) as comments_count,
    (select exists(select 1 from public.likes l where l.post_id = p.id and l.user_id = p_user_id)) as is_liked,
    pr.username, pr.display_name, pr.avatar_url
  from public.posts p
  join public.profiles pr on p.user_id = pr.id
  order by p.created_at desc
  limit p_limit offset p_offset;
$$;

create or replace function public.recommend_recipes(
  inventory_keys text[],
  limit_count int default 50
)
returns table (
  recipe_id text,
  title_en text,
  title_tr text,
  image_url text,
  match_count int,
  needed_count int,
  missing_count int,
  missing_keys text[]
)
language sql stable
as $$
  select
    r.id as recipe_id, r.title_en, r.title_tr, r.image_url,
    (select count(*)::int from unnest(r.ingredient_keys) as k where k = any(inventory_keys)) as match_count,
    cardinality(r.ingredient_keys)::int as needed_count,
    (select count(*)::int from unnest(r.ingredient_keys) as k where not (k = any(inventory_keys))) as missing_count,
    (select coalesce(array_agg(k order by k), array[]::text[]) from unnest(r.ingredient_keys) as k where not (k = any(inventory_keys))) as missing_keys
  from public.recipes r
  where cardinality(r.ingredient_keys) > 0
  order by missing_count asc, match_count desc
  limit limit_count;
$$;

-- GRANTS
grant usage on schema public to anon, authenticated;
grant select on public.profiles to anon, authenticated;
grant select, insert, update on public.profiles to authenticated;
grant select on public.recipes to anon, authenticated;
grant select, insert, update, delete on public.posts to authenticated;
grant select on public.posts to anon;
grant select, insert, delete on public.likes to authenticated;
grant select on public.likes to anon;
grant select, insert, delete on public.comments to authenticated;
grant select on public.comments to anon;
grant execute on function public.get_feed_posts(uuid, int, int) to anon, authenticated;
grant execute on function public.recommend_recipes(text[], int) to anon, authenticated;
