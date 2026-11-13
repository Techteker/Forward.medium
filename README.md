# Forward — Stories worth staying for

A mobile-first publishing and reading app for thoughtful articles, short stories and serialized novels.

## Stack
- React + TypeScript + Vite
- Supabase Auth + Postgres + Row Level Security
- Responsive app shell and installable web-app manifest
- Vercel-ready static frontend

## Local development
1. Install Node.js 20+.
2. Run `npm install`.
3. Copy `.env.example` to `.env.local`.
4. Add your Supabase project URL and public anon/publishable key.
5. Run `npm run dev`; create a production build with `npm run build`.

## Supabase setup
Run `supabase/schema.sql` in the Supabase SQL Editor. The schema creates profiles, posts, chapters, likes, bookmarks, comments and follows, enables RLS, and adds ownership-based policies. Configure the Supabase Auth email provider and allowed redirect URLs for your deployed domain.

Never put a Supabase service-role key in frontend environment variables. Only use the public anon/publishable key in `VITE_SUPABASE_ANON_KEY`.

## Implemented in this starter
- App-style desktop sidebar and mobile bottom navigation
- Home feed, topic filtering and search
- Article / short story / novel reading view
- Bookmark and like interactions (currently local UI state)
- Writing editor with word count and publish flow
- Supabase session listener, magic-link sign-in and published-post fetch/insert when configured
- PWA manifest and app icon

## Production work still required
- Persistent bookmarks, likes, follows, comments and notifications wired to their tables
- Chapter-by-chapter novel management and rich-text editor / image uploads
- Profile editing, moderation/admin tools, reporting and rate limits
- Server rendering or prerendering for per-story SEO, dynamic canonical URLs, JSON-LD and XML sitemaps. The current Vite SPA has a shared HTML shell, so per-article search metadata is not yet production-complete.
- End-to-end testing, accessibility audit, analytics, error monitoring and Vercel deployment

## Deploy
Import this repository into Vercel, set the build command to `npm run build`, output directory to `dist`, and add the two public Supabase environment variables. Configure Supabase Auth redirect URLs for the final production domain.
