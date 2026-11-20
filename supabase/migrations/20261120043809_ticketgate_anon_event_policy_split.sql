
drop policy if exists "published events public read" on public.events;
create policy "published events public read" on public.events for select to anon
using (status='PUBLISHED');
create policy "authenticated events read" on public.events for select to authenticated
using (status='PUBLISHED' or organizer_id=(select auth.uid()) or (select public.current_user_role())='ADMIN');
