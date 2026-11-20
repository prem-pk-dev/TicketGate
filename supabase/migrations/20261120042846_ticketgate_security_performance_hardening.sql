
drop view if exists public.public_show_seats;
revoke all on public.show_seats from anon,authenticated;
grant select(id,show_id,seat_id,price,status,locked_until) on public.show_seats to anon,authenticated;
create policy "public seat availability read" on public.show_seats for select to anon,authenticated using (true);
create view public.public_show_seats with (security_invoker=true) as
select ss.id,ss.show_id,ss.seat_id,ss.price,
 case when ss.status='LOCKED' and ss.locked_until<=now() then 'AVAILABLE'::public.show_seat_status else ss.status end as status,
 (ss.status='LOCKED' and ss.locked_until>now()) as is_locked,
 s.row_label,s.seat_number,s.category
from public.show_seats ss join public.seats s on s.id=ss.seat_id;
grant select on public.public_show_seats to anon,authenticated;

create index if not exists add_ons_event_id_idx on public.add_ons(event_id);
create index if not exists booking_add_ons_add_on_id_idx on public.booking_add_ons(add_on_id);
create index if not exists booking_add_ons_booking_id_idx on public.booking_add_ons(booking_id);
create index if not exists booking_seats_show_seat_id_idx on public.booking_seats(show_seat_id);
create index if not exists bookings_promo_code_id_idx on public.bookings(promo_code_id);
create index if not exists bookings_show_id_idx on public.bookings(show_id);
create index if not exists check_ins_checked_in_by_idx on public.check_ins(checked_in_by);
create index if not exists events_organizer_id_idx on public.events(organizer_id);
create index if not exists halls_venue_id_idx on public.halls(venue_id);
create index if not exists payments_booking_id_idx on public.payments(booking_id);
create index if not exists show_seats_booking_id_idx on public.show_seats(booking_id);
create index if not exists show_seats_locked_by_idx on public.show_seats(locked_by);
create index if not exists show_seats_seat_id_idx on public.show_seats(seat_id);
create index if not exists shows_hall_id_idx on public.shows(hall_id);
create index if not exists venues_city_id_idx on public.venues(city_id);
create index if not exists venues_created_by_idx on public.venues(created_by);

drop policy if exists "published events public read" on public.events;
create policy "published events public read" on public.events for select to anon,authenticated
using (status='PUBLISHED' or organizer_id=(select auth.uid()));
drop policy if exists "users read own booking seats" on public.booking_seats;
create policy "users read own booking seats" on public.booking_seats for select to authenticated
using (exists(select 1 from public.bookings b where b.id=booking_id and b.user_id=(select auth.uid())));
drop policy if exists "users read own booking addons" on public.booking_add_ons;
create policy "users read own booking addons" on public.booking_add_ons for select to authenticated
using (exists(select 1 from public.bookings b where b.id=booking_id and b.user_id=(select auth.uid())));
drop policy if exists "users read own payments" on public.payments;
create policy "users read own payments" on public.payments for select to authenticated
using (exists(select 1 from public.bookings b where b.id=booking_id and b.user_id=(select auth.uid())));
drop policy if exists "checkin owner or staff read" on public.check_ins;
create policy "checkin owner or staff read" on public.check_ins for select to authenticated
using (exists(select 1 from public.bookings b where b.id=booking_id and b.user_id=(select auth.uid())) or (select public.current_user_role()) in ('ADMIN','ORGANIZER'));
drop policy if exists "profiles read self or admin" on public.profiles;
create policy "profiles read self or admin" on public.profiles for select to authenticated
using (id=(select auth.uid()) or (select public.current_user_role())='ADMIN');
drop policy if exists "profiles update own non-role fields" on public.profiles;
create policy "profiles update own non-role fields" on public.profiles for update to authenticated
using (id=(select auth.uid())) with check (id=(select auth.uid()) and role=(select public.current_user_role()));
drop policy if exists "users and event owners read bookings" on public.bookings;
create policy "users and event owners read bookings" on public.bookings for select to authenticated
using (
 user_id=(select auth.uid())
 or (select public.current_user_role())='ADMIN'
 or exists(select 1 from public.shows sh join public.events ev on ev.id=sh.event_id where sh.id=show_id and ev.organizer_id=(select auth.uid()))
);
