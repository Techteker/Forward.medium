-- Add bilingual story language support to existing Forward posts.
alter table public.posts
  add column if not exists language text not null default 'English';

alter table public.posts
  drop constraint if exists posts_language_check;

alter table public.posts
  add constraint posts_language_check
  check (language in ('Hindi', 'English'));

create index if not exists posts_language_published_idx
  on public.posts(language, status, published_at desc);
