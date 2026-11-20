
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.current_user_role() from public, anon;
grant execute on function public.current_user_role() to authenticated;
revoke all on function public.lock_show_seats(uuid,uuid[]) from public, anon;
grant execute on function public.lock_show_seats(uuid,uuid[]) to authenticated;
revoke all on function public.release_expired_seat_locks() from public, anon, authenticated;
grant execute on function public.release_expired_seat_locks() to service_role;
revoke all on function public.confirm_dummy_payment(uuid,boolean,text) from public, anon;
grant execute on function public.confirm_dummy_payment(uuid,boolean,text) to authenticated;

create or replace function public.create_booking(p_show_id uuid,p_seat_ids uuid[],p_promo_code text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
 v_user uuid := auth.uid();
 v_booking public.bookings%rowtype;
 v_subtotal numeric(10,2);
 v_fees numeric(10,2);
 v_discount numeric(10,2) := 0;
 v_promo public.promo_codes%rowtype;
 v_count integer;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 if coalesce(array_length(p_seat_ids,1),0)<1 or array_length(p_seat_ids,1)>10 then
   raise exception 'Select between 1 and 10 seats' using errcode='22023';
 end if;
 perform 1 from public.show_seats
  where show_id=p_show_id and seat_id=any(p_seat_ids)
  order by seat_id for update;
 select count(*),coalesce(sum(price),0) into v_count,v_subtotal
 from public.show_seats
 where show_id=p_show_id and seat_id=any(p_seat_ids)
   and status='LOCKED' and locked_by=v_user and locked_until>now() and booking_id is null;
 if v_count<>array_length(p_seat_ids,1) then
   raise exception 'Seat hold expired or no longer belongs to you' using errcode='P0001';
 end if;
 if p_promo_code is not null and length(trim(p_promo_code))>0 then
   select * into v_promo from public.promo_codes
    where code=upper(trim(p_promo_code)) and is_active
      and valid_from<=now() and (valid_until is null or valid_until>now())
    for update;
   if not found then raise exception 'Invalid or expired promo code' using errcode='P0001'; end if;
   if v_promo.max_uses is not null and v_promo.used_count>=v_promo.max_uses then
     raise exception 'Promo code usage limit reached' using errcode='P0001';
   end if;
   if v_subtotal<v_promo.min_order then raise exception 'Order does not meet promo minimum' using errcode='P0001'; end if;
   if v_promo.discount_percent is not null then
     v_discount:=round(v_subtotal*v_promo.discount_percent/100,2);
   else
     v_discount:=least(v_subtotal,v_promo.discount_amount);
   end if;
 end if;
 v_fees:=round(v_subtotal*0.05,2);
 insert into public.bookings(user_id,show_id,subtotal,fees,discount,total,promo_code_id,expires_at)
 values(v_user,p_show_id,v_subtotal,v_fees,v_discount,v_subtotal+v_fees-v_discount,
        v_promo.id,now()+interval '10 minutes')
 returning * into v_booking;
 insert into public.booking_seats(booking_id,show_seat_id,price)
 select v_booking.id,ss.id,ss.price from public.show_seats ss
 where ss.show_id=p_show_id and ss.seat_id=any(p_seat_ids);
 update public.show_seats set booking_id=v_booking.id
 where show_id=p_show_id and seat_id=any(p_seat_ids);
 return jsonb_build_object('booking_id',v_booking.id,'booking_code',v_booking.booking_code,
   'subtotal',v_booking.subtotal,'fees',v_booking.fees,'discount',v_booking.discount,
   'total',v_booking.total,'expires_at',v_booking.expires_at);
end; $$;
revoke all on function public.create_booking(uuid,uuid[],text) from public, anon;
grant execute on function public.create_booking(uuid,uuid[],text) to authenticated;
