
create index if not exists show_queue_user_id_idx on public.show_queue_entries(user_id);

drop policy if exists "cities public read" on public.cities;
drop policy if exists "admins manage cities" on public.cities;
create policy "cities anon read active" on public.cities for select to anon using(is_active);
create policy "cities authenticated read" on public.cities for select to authenticated using(is_active or (select public.current_user_role())='ADMIN');
create policy "admins insert cities" on public.cities for insert to authenticated with check((select public.current_user_role())='ADMIN');
create policy "admins update cities" on public.cities for update to authenticated using((select public.current_user_role())='ADMIN') with check((select public.current_user_role())='ADMIN');
create policy "admins delete cities" on public.cities for delete to authenticated using((select public.current_user_role())='ADMIN');

drop policy if exists "active addons public read" on public.add_ons;
drop policy if exists "organizers manage add ons" on public.add_ons;
create policy "addons anon read active" on public.add_ons for select to anon using(is_active);
create policy "addons authenticated read" on public.add_ons for select to authenticated
using(is_active or (select public.current_user_role())='ADMIN' or exists(select 1 from public.events e where e.id=event_id and e.organizer_id=(select auth.uid())));
create policy "organizers insert add ons" on public.add_ons for insert to authenticated
with check((select public.current_user_role())='ADMIN' or exists(select 1 from public.events e where e.id=event_id and e.organizer_id=(select auth.uid())));
create policy "organizers update add ons" on public.add_ons for update to authenticated
using((select public.current_user_role())='ADMIN' or exists(select 1 from public.events e where e.id=event_id and e.organizer_id=(select auth.uid())))
with check((select public.current_user_role())='ADMIN' or exists(select 1 from public.events e where e.id=event_id and e.organizer_id=(select auth.uid())));
create policy "organizers delete add ons" on public.add_ons for delete to authenticated
using((select public.current_user_role())='ADMIN' or exists(select 1 from public.events e where e.id=event_id and e.organizer_id=(select auth.uid())));

drop policy if exists "active promo public read" on public.promo_codes;
drop policy if exists "admins manage promos" on public.promo_codes;
create policy "promos anon read active" on public.promo_codes for select to anon
using(is_active and now() between valid_from and coalesce(valid_until,'infinity'::timestamptz));
create policy "promos authenticated read" on public.promo_codes for select to authenticated
using((is_active and now() between valid_from and coalesce(valid_until,'infinity'::timestamptz)) or (select public.current_user_role())='ADMIN');
create policy "admins insert promos" on public.promo_codes for insert to authenticated with check((select public.current_user_role())='ADMIN');
create policy "admins update promos" on public.promo_codes for update to authenticated using((select public.current_user_role())='ADMIN') with check((select public.current_user_role())='ADMIN');
create policy "admins delete promos" on public.promo_codes for delete to authenticated using((select public.current_user_role())='ADMIN');

drop policy if exists "shows public read" on public.shows;
drop policy if exists "organizers manage shows" on public.shows;
create policy "shows anon read published" on public.shows for select to anon
using(exists(select 1 from public.events e where e.id=event_id and e.status='PUBLISHED'));
create policy "shows authenticated read" on public.shows for select to authenticated
using(exists(select 1 from public.events e where e.id=event_id and (e.status='PUBLISHED' or e.organizer_id=(select auth.uid()))) or (select public.current_user_role())='ADMIN');
create policy "organizers insert shows" on public.shows for insert to authenticated
with check((select public.current_user_role())='ADMIN' or exists(select 1 from public.events e where e.id=event_id and e.organizer_id=(select auth.uid())));
create policy "organizers update shows" on public.shows for update to authenticated
using((select public.current_user_role())='ADMIN' or exists(select 1 from public.events e where e.id=event_id and e.organizer_id=(select auth.uid())))
with check((select public.current_user_role())='ADMIN' or exists(select 1 from public.events e where e.id=event_id and e.organizer_id=(select auth.uid())));
create policy "organizers delete shows" on public.shows for delete to authenticated
using((select public.current_user_role())='ADMIN' or exists(select 1 from public.events e where e.id=event_id and e.organizer_id=(select auth.uid())));

drop policy if exists "organizers manage halls" on public.halls;
create policy "organizers insert halls" on public.halls for insert to authenticated
with check((select public.current_user_role())='ADMIN' or exists(select 1 from public.venues v where v.id=venue_id and v.created_by=(select auth.uid())));
create policy "organizers update halls" on public.halls for update to authenticated
using((select public.current_user_role())='ADMIN' or exists(select 1 from public.venues v where v.id=venue_id and v.created_by=(select auth.uid())))
with check((select public.current_user_role())='ADMIN' or exists(select 1 from public.venues v where v.id=venue_id and v.created_by=(select auth.uid())));
create policy "organizers delete halls" on public.halls for delete to authenticated
using((select public.current_user_role())='ADMIN' or exists(select 1 from public.venues v where v.id=venue_id and v.created_by=(select auth.uid())));

drop policy if exists "organizers manage seats" on public.seats;
create policy "organizers insert seats" on public.seats for insert to authenticated
with check((select public.current_user_role())='ADMIN' or exists(select 1 from public.halls h join public.venues v on v.id=h.venue_id where h.id=hall_id and v.created_by=(select auth.uid())));
create policy "organizers update seats" on public.seats for update to authenticated
using((select public.current_user_role())='ADMIN' or exists(select 1 from public.halls h join public.venues v on v.id=h.venue_id where h.id=hall_id and v.created_by=(select auth.uid())))
with check((select public.current_user_role())='ADMIN' or exists(select 1 from public.halls h join public.venues v on v.id=h.venue_id where h.id=hall_id and v.created_by=(select auth.uid())));
create policy "organizers delete seats" on public.seats for delete to authenticated
using((select public.current_user_role())='ADMIN' or exists(select 1 from public.halls h join public.venues v on v.id=h.venue_id where h.id=hall_id and v.created_by=(select auth.uid())));
