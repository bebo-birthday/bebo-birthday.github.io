-- Run in Supabase SQL Editor after creating two Auth users.
create table if not exists public.gifts (
  id uuid primary key,
  headline text not null default 'my favorite person',
  message text not null default '',
  video_path text,
  updated_at timestamptz not null default now()
);

create table if not exists public.gift_members (
  gift_id uuid not null references public.gifts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','recipient')),
  primary key (gift_id,user_id),
  unique (gift_id,role)
);

alter table public.gifts enable row level security;
alter table public.gift_members enable row level security;

revoke all on public.gifts from anon;
grant select on public.gifts to authenticated;
grant update (headline,message,video_path,updated_at) on public.gifts to authenticated;
revoke all on public.gift_members from anon, authenticated;
grant select on public.gift_members to authenticated;

drop policy if exists "gift members can view membership" on public.gift_members;
create policy "gift members can view membership" on public.gift_members
for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists "invited users can read gift" on public.gifts;
create policy "invited users can read gift" on public.gifts
for select to authenticated using (
  exists (select 1 from public.gift_members m where m.gift_id = gifts.id and m.user_id = (select auth.uid()))
);

drop policy if exists "only owner can edit gift" on public.gifts;
create policy "only owner can edit gift" on public.gifts
for update to authenticated using (
  exists (select 1 from public.gift_members m where m.gift_id = gifts.id and m.user_id = (select auth.uid()) and m.role = 'owner')
) with check (
  exists (select 1 from public.gift_members m where m.gift_id = gifts.id and m.user_id = (select auth.uid()) and m.role = 'owner')
);

insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('birthday-videos','birthday-videos',false,524288000,array['video/mp4','video/webm','video/quicktime','video/ogg'])
on conflict (id) do update set public=false, file_size_limit=524288000,
  allowed_mime_types=array['video/mp4','video/webm','video/quicktime','video/ogg'];

drop policy if exists "gift members can read birthday video" on storage.objects;
create policy "gift members can read birthday video" on storage.objects
for select to authenticated using (
  bucket_id = 'birthday-videos' and exists (
    select 1 from public.gift_members m where m.gift_id::text = (storage.foldername(name))[1] and m.user_id = (select auth.uid())
  )
);
drop policy if exists "gift owner can upload birthday video" on storage.objects;
create policy "gift owner can upload birthday video" on storage.objects
for insert to authenticated with check (
  bucket_id = 'birthday-videos' and exists (
    select 1 from public.gift_members m where m.gift_id::text = (storage.foldername(name))[1] and m.user_id = (select auth.uid()) and m.role='owner'
  )
);
drop policy if exists "gift owner can delete birthday video" on storage.objects;
create policy "gift owner can delete birthday video" on storage.objects
for delete to authenticated using (
  bucket_id = 'birthday-videos' and exists (
    select 1 from public.gift_members m where m.gift_id::text = (storage.foldername(name))[1] and m.user_id = (select auth.uid()) and m.role='owner'
  )
);
