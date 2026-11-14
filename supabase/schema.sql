-- Forward.medium starter schema. Run in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  display_name text,
  bio text,
  avatar_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  slug text unique,
  excerpt text,
  body text not null default '',
  category text not null default 'LIFE',
  content_type text not null default 'Article' check (content_type in ('Article','Short story','Novel')),
  language text not null default 'English' check (language in ('Hindi','English')),
  status text not null default 'draft' check (status in ('draft','published','archived')),
  cover_image_url text,
  read_time integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  published_at timestamptz
);

create index if not exists posts_status_published_idx on public.posts(status,published_at desc);
create index if not exists posts_author_idx on public.posts(author_id,created_at desc);

create table if not exists public.chapters (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  chapter_number integer not null,
  title text not null,
  body text not null default '',
  created_at timestamptz not null default now(),
  unique(post_id,chapter_number)
);

create table if not exists public.post_likes (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(post_id,user_id)
);

create table if not exists public.bookmarks (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(post_id,user_id)
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 3000),
  created_at timestamptz not null default now()
);

create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(follower_id,following_id),
  check(follower_id <> following_id)
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles(id,username,display_name)
  values(new.id, null, coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email,'@',1)))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.chapters enable row level security;
alter table public.post_likes enable row level security;
alter table public.bookmarks enable row level security;
alter table public.comments enable row level security;
alter table public.follows enable row level security;

create policy "Profiles are publicly readable" on public.profiles for select to anon, authenticated using (true);
create policy "Users update their profile" on public.profiles for update to authenticated using ((select auth.uid())=id) with check ((select auth.uid())=id);
create policy "Published posts are public" on public.posts for select to anon, authenticated using (status='published' or (select auth.uid())=author_id);
create policy "Authors create posts" on public.posts for insert to authenticated with check ((select auth.uid())=author_id);
create policy "Authors update posts" on public.posts for update to authenticated using ((select auth.uid())=author_id) with check ((select auth.uid())=author_id);
create policy "Authors delete posts" on public.posts for delete to authenticated using ((select auth.uid())=author_id);
create policy "Chapters follow parent visibility" on public.chapters for select to anon, authenticated using (exists(select 1 from public.posts p where p.id=post_id and (p.status='published' or p.author_id=(select auth.uid()))));
create policy "Authors manage chapters" on public.chapters for all to authenticated using (exists(select 1 from public.posts p where p.id=post_id and p.author_id=(select auth.uid()))) with check (exists(select 1 from public.posts p where p.id=post_id and p.author_id=(select auth.uid())));
create policy "Likes are public" on public.post_likes for select to anon, authenticated using (true);
create policy "Users manage own likes" on public.post_likes for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy "Users read own bookmarks" on public.bookmarks for select to authenticated using ((select auth.uid())=user_id);
create policy "Users manage own bookmarks" on public.bookmarks for all to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
create policy "Comments are public" on public.comments for select to anon, authenticated using (true);
create policy "Signed-in users comment as themselves" on public.comments for insert to authenticated with check ((select auth.uid())=author_id);
create policy "Authors delete own comments" on public.comments for delete to authenticated using ((select auth.uid())=author_id);
create policy "Follows are visible" on public.follows for select to authenticated using (true);
create policy "Users manage own follows" on public.follows for all to authenticated using ((select auth.uid())=follower_id) with check ((select auth.uid())=follower_id);

grant select on public.profiles, public.posts, public.chapters, public.post_likes, public.comments to anon, authenticated;
grant insert,update,delete on public.profiles, public.posts, public.chapters, public.post_likes, public.bookmarks, public.comments, public.follows to authenticated;
grant select on public.bookmarks, public.follows to authenticated;
