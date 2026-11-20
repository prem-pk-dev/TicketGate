
create policy "organizers create venues" on public.venues for insert to authenticated
with check ((select public.current_user_role()) in ('ADMIN','ORGANIZER') and created_by=(select auth.uid()));
create policy "organizers update owned venues" on public.venues for update to authenticated
using ((select public.current_user_role())='ADMIN' or created_by=(select auth.uid()))
with check ((select public.current_user_role())='ADMIN' or created_by=(select auth.uid()));
create policy "organizers delete owned venues" on public.venues for delete to authenticated
using ((select public.current_user_role())='ADMIN' or created_by=(select auth.uid()));

create policy "organizers manage halls" on public.halls for all to authenticated
using ((select public.current_user_role())='ADMIN' or exists(select 1 from public.venues v where v.id=venue_id and v.created_by=(select auth.uid())))
with check ((select public.current_user_role())='ADMIN' or exists(select 1 from public.venues v where v.id=venue_id and v.created_by=(select auth.uid())));
create policy "organizers manage seats" on public.seats for all to authenticated
using ((select public.current_user_role())='ADMIN' or exists(select 1 from public.halls h join public.venues v on v.id=h.venue_id where h.id=hall_id and v.created_by=(select auth.uid())))
with check ((select public.current_user_role())='ADMIN' or exists(select 1 from public.halls h join public.venues v on v.id=h.venue_id where h.id=hall_id and v.created_by=(select auth.uid())));

create policy "organizers create events" on public.events for insert to authenticated
with check ((select public.current_user_role())='ADMIN' or ((select public.current_user_role())='ORGANIZER' and organizer_id=(select auth.uid())));
create policy "organizers update own events" on public.events for update to authenticated
using ((select public.current_user_role())='ADMIN' or organizer_id=(select auth.uid()))
with check ((select public.current_user_role())='ADMIN' or organizer_id=(select auth.uid()));
create policy "organizers delete own events" on public.events for delete to authenticated
using ((select public.current_user_role())='ADMIN' or organizer_id=(select auth.uid()));

create policy "organizers manage shows" on public.shows for all to authenticated
using ((select public.current_user_role())='ADMIN' or exists(select 1 from public.events e where e.id=event_id and e.organizer_id=(select auth.uid())))
with check ((select public.current_user_role())='ADMIN' or exists(select 1 from public.events e where e.id=event_id and e.organizer_id=(select auth.uid())));
create policy "organizers manage add ons" on public.add_ons for all to authenticated
using ((select public.current_user_role())='ADMIN' or exists(select 1 from public.events e where e.id=event_id and e.organizer_id=(select auth.uid())))
with check ((select public.current_user_role())='ADMIN' or exists(select 1 from public.events e where e.id=event_id and e.organizer_id=(select auth.uid())));
create policy "admins manage cities" on public.cities for all to authenticated
using ((select public.current_user_role())='ADMIN') with check ((select public.current_user_role())='ADMIN');
create policy "admins manage promos" on public.promo_codes for all to authenticated
using ((select public.current_user_role())='ADMIN') with check ((select public.current_user_role())='ADMIN');

drop policy if exists "checkin owner or staff read" on public.check_ins;
drop policy if exists "checkin owner or event organizer read" on public.check_ins;
create policy "checkin owner or event organizer read" on public.check_ins for select to authenticated
using (
 exists(select 1 from public.bookings b where b.id=booking_id and b.user_id=(select auth.uid()))
 or (select public.current_user_role())='ADMIN'
 or exists(select 1 from public.bookings b join public.shows sh on sh.id=b.show_id join public.events e on e.id=sh.event_id where b.id=booking_id and e.organizer_id=(select auth.uid()))
);

create or replace function private.cancel_booking(p_booking_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_booking public.bookings%rowtype;v_start timestamptz;
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select b.* into v_booking from public.bookings b where b.id=p_booking_id and b.user_id=auth.uid() for update;
 if not found then raise exception 'Booking not found' using errcode='P0002'; end if;
 select starts_at into v_start from public.shows where id=v_booking.show_id;
 if v_booking.status<>'CONFIRMED' then raise exception 'Only confirmed bookings can be cancelled' using errcode='P0001'; end if;
 if v_start<=now()+interval '24 hours' then raise exception 'Cancellation closes 24 hours before the show' using errcode='P0001'; end if;
 if exists(select 1 from public.check_ins where booking_id=p_booking_id) then raise exception 'Checked-in tickets cannot be cancelled' using errcode='P0001'; end if;
 update public.bookings set status='CANCELLED' where id=p_booking_id;
 update public.payments set status='REFUNDED' where booking_id=p_booking_id and status='SUCCESS';
 update public.show_seats ss set status='AVAILABLE',locked_by=null,locked_until=null,booking_id=null
 from public.booking_seats bs where bs.booking_id=p_booking_id and bs.show_seat_id=ss.id;
 return jsonb_build_object('status','CANCELLED','refund_status','SIMULATED_REFUND');
end; $$;
grant execute on function private.cancel_booking(uuid) to authenticated;
create or replace function public.cancel_booking(p_booking_id uuid)
returns jsonb language sql security invoker set search_path=''
as $$ select private.cancel_booking(p_booking_id) $$;
revoke all on function public.cancel_booking(uuid) from public,anon;
grant execute on function public.cancel_booking(uuid) to authenticated;

create or replace function private.validate_ticket(p_qr_token uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_booking public.bookings%rowtype;v_event public.events%rowtype;v_check public.check_ins%rowtype;
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='28000'; end if;
 if (select private.current_user_role()) not in ('ADMIN','ORGANIZER') then raise exception 'Staff access required' using errcode='42501'; end if;
 select b.* into v_booking from public.bookings b where b.qr_token=p_qr_token;
 if not found then raise exception 'Ticket not found' using errcode='P0002'; end if;
 select e.* into v_event from public.events e join public.shows sh on sh.event_id=e.id where sh.id=v_booking.show_id;
 if (select private.current_user_role())<>'ADMIN' and v_event.organizer_id<>auth.uid() then raise exception 'You cannot validate tickets for this event' using errcode='42501'; end if;
 if v_booking.status<>'CONFIRMED' then raise exception 'Ticket is not valid: %',v_booking.status using errcode='P0001'; end if;
 select * into v_check from public.check_ins where booking_id=v_booking.id;
 if found then return jsonb_build_object('valid',false,'already_checked_in',true,'booking_code',v_booking.booking_code,'event',v_event.title,'checked_in_at',v_check.checked_in_at); end if;
 insert into public.check_ins(booking_id,checked_in_by) values(v_booking.id,auth.uid()) returning * into v_check;
 return jsonb_build_object('valid',true,'already_checked_in',false,'booking_code',v_booking.booking_code,'event',v_event.title,'checked_in_at',v_check.checked_in_at);
end; $$;
grant execute on function private.validate_ticket(uuid) to authenticated;
create or replace function public.validate_ticket(p_qr_token uuid)
returns jsonb language sql security invoker set search_path=''
as $$ select private.validate_ticket(p_qr_token) $$;
revoke all on function public.validate_ticket(uuid) from public,anon;
grant execute on function public.validate_ticket(uuid) to authenticated;
