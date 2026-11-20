
create or replace view public.public_show_seats as
select ss.id,ss.show_id,ss.seat_id,ss.price,
 case when ss.status='LOCKED' and ss.locked_until<=now() then 'AVAILABLE'::public.show_seat_status else ss.status end as status,
 (ss.status='LOCKED' and ss.locked_until>now()) as is_locked,
 s.row_label,s.seat_number,s.category
from public.show_seats ss join public.seats s on s.id=ss.seat_id;
revoke select on public.show_seats from anon,authenticated;
drop policy if exists "show seats public read" on public.show_seats;
grant select on public.public_show_seats to anon,authenticated;

drop policy if exists "users create own bookings" on public.bookings;
drop policy if exists "users read own bookings" on public.bookings;
create policy "users and event owners read bookings" on public.bookings for select to authenticated
using (
 user_id=auth.uid()
 or public.current_user_role()='ADMIN'
 or exists(select 1 from public.shows sh join public.events ev on ev.id=sh.event_id where sh.id=show_id and ev.organizer_id=auth.uid())
);

create or replace function public.confirm_dummy_payment(p_booking_id uuid,p_success boolean,p_idempotency_key text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
 v_booking public.bookings%rowtype;
 v_payment public.payments%rowtype;
 v_expected integer;
 v_valid integer;
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='28000'; end if;
 if p_idempotency_key is null or length(trim(p_idempotency_key))<8 then
   raise exception 'A valid idempotency key is required' using errcode='22023';
 end if;
 select * into v_booking from public.bookings where id=p_booking_id and user_id=auth.uid() for update;
 if not found then raise exception 'Booking not found' using errcode='P0002'; end if;
 select * into v_payment from public.payments where idempotency_key=p_idempotency_key;
 if found then
   if v_payment.booking_id<>p_booking_id then raise exception 'Idempotency key already used' using errcode='23505'; end if;
   return jsonb_build_object('status',v_payment.status,'payment_id',v_payment.id);
 end if;
 if v_booking.status<>'PENDING' or (v_booking.expires_at is not null and v_booking.expires_at<now()) then
   raise exception 'Booking is not payable' using errcode='P0001';
 end if;
 if p_success then
   select count(*) into v_expected from public.booking_seats where booking_id=p_booking_id;
   select count(*) into v_valid from public.booking_seats bs join public.show_seats ss on ss.id=bs.show_seat_id
    where bs.booking_id=p_booking_id and ss.status='LOCKED' and ss.locked_by=auth.uid()
      and ss.locked_until>now() and ss.booking_id=p_booking_id;
   if v_expected=0 or v_valid<>v_expected then
     raise exception 'One or more seat holds have expired' using errcode='P0001';
   end if;
 end if;
 insert into public.payments(booking_id,status,amount,idempotency_key,provider_reference)
 values(p_booking_id,case when p_success then 'SUCCESS'::public.payment_status else 'FAILED'::public.payment_status end,
        v_booking.total,p_idempotency_key,'DUMMY-'||p_idempotency_key)
 returning * into v_payment;
 if p_success then
   update public.bookings set status='CONFIRMED' where id=p_booking_id;
   update public.show_seats ss set status='BOOKED',locked_until=null
    from public.booking_seats bs where bs.booking_id=p_booking_id and bs.show_seat_id=ss.id;
   if v_booking.promo_code_id is not null then
     update public.promo_codes set used_count=used_count+1
     where id=v_booking.promo_code_id and (max_uses is null or used_count<max_uses);
     if not found then raise exception 'Promo code usage limit reached' using errcode='P0001'; end if;
   end if;
 end if;
 return jsonb_build_object('status',v_payment.status,'payment_id',v_payment.id);
end; $$;
revoke all on function public.confirm_dummy_payment(uuid,boolean,text) from public,anon;
grant execute on function public.confirm_dummy_payment(uuid,boolean,text) to authenticated;
