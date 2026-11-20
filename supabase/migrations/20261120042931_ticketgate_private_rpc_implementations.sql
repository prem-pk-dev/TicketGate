
create schema if not exists private;
revoke all on schema private from public,anon;
grant usage on schema private to authenticated,service_role;

create or replace function private.current_user_role()
returns public.app_role language sql stable security definer set search_path=''
as $$ select role from public.profiles where id=auth.uid() $$;
grant execute on function private.current_user_role() to authenticated;

create or replace function private.lock_show_seats(p_show_id uuid,p_seat_ids uuid[])
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_user uuid:=auth.uid();v_count integer;v_distinct integer;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 v_distinct:=coalesce(array_length(p_seat_ids,1),0);
 if v_distinct<1 or v_distinct>10 then raise exception 'Select between 1 and 10 seats' using errcode='22023'; end if;
 if (select count(distinct x) from unnest(p_seat_ids) x)<>v_distinct then raise exception 'Duplicate seats are not allowed' using errcode='22023'; end if;
 perform 1 from public.show_seats where show_id=p_show_id and seat_id=any(p_seat_ids) order by seat_id for update;
 select count(*) into v_count from public.show_seats where show_id=p_show_id and seat_id=any(p_seat_ids)
  and (status='AVAILABLE' or (status='LOCKED' and locked_until<now()) or (status='LOCKED' and locked_by=v_user));
 if v_count<>v_distinct then raise exception 'One or more seats are no longer available' using errcode='P0001'; end if;
 update public.show_seats set status='LOCKED',locked_by=v_user,locked_until=now()+interval '10 minutes'
 where show_id=p_show_id and seat_id=any(p_seat_ids);
 return jsonb_build_object('success',true,'locked_until',now()+interval '10 minutes','seat_count',v_distinct);
end; $$;
grant execute on function private.lock_show_seats(uuid,uuid[]) to authenticated;

create or replace function private.create_booking(p_show_id uuid,p_seat_ids uuid[],p_promo_code text default null)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_user uuid:=auth.uid();v_booking public.bookings%rowtype;v_subtotal numeric(10,2);v_fees numeric(10,2);v_discount numeric(10,2):=0;v_promo public.promo_codes%rowtype;v_count integer;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 if coalesce(array_length(p_seat_ids,1),0)<1 or array_length(p_seat_ids,1)>10 then raise exception 'Select between 1 and 10 seats' using errcode='22023'; end if;
 perform 1 from public.show_seats where show_id=p_show_id and seat_id=any(p_seat_ids) order by seat_id for update;
 select count(*),coalesce(sum(price),0) into v_count,v_subtotal from public.show_seats
 where show_id=p_show_id and seat_id=any(p_seat_ids) and status='LOCKED' and locked_by=v_user and locked_until>now() and booking_id is null;
 if v_count<>array_length(p_seat_ids,1) then raise exception 'Seat hold expired or no longer belongs to you' using errcode='P0001'; end if;
 if p_promo_code is not null and length(trim(p_promo_code))>0 then
  select * into v_promo from public.promo_codes where code=upper(trim(p_promo_code)) and is_active and valid_from<=now() and (valid_until is null or valid_until>now()) for update;
  if not found then raise exception 'Invalid or expired promo code' using errcode='P0001'; end if;
  if v_promo.max_uses is not null and v_promo.used_count>=v_promo.max_uses then raise exception 'Promo code usage limit reached' using errcode='P0001'; end if;
  if v_subtotal<v_promo.min_order then raise exception 'Order does not meet promo minimum' using errcode='P0001'; end if;
  if v_promo.discount_percent is not null then v_discount:=round(v_subtotal*v_promo.discount_percent/100,2); else v_discount:=least(v_subtotal,v_promo.discount_amount); end if;
 end if;
 v_fees:=round(v_subtotal*0.05,2);
 insert into public.bookings(user_id,show_id,subtotal,fees,discount,total,promo_code_id,expires_at)
 values(v_user,p_show_id,v_subtotal,v_fees,v_discount,v_subtotal+v_fees-v_discount,v_promo.id,now()+interval '10 minutes') returning * into v_booking;
 insert into public.booking_seats(booking_id,show_seat_id,price)
 select v_booking.id,ss.id,ss.price from public.show_seats ss where ss.show_id=p_show_id and ss.seat_id=any(p_seat_ids);
 update public.show_seats set booking_id=v_booking.id where show_id=p_show_id and seat_id=any(p_seat_ids);
 return jsonb_build_object('booking_id',v_booking.id,'booking_code',v_booking.booking_code,'subtotal',v_booking.subtotal,'fees',v_booking.fees,'discount',v_booking.discount,'total',v_booking.total,'expires_at',v_booking.expires_at);
end; $$;
grant execute on function private.create_booking(uuid,uuid[],text) to authenticated;

create or replace function private.confirm_dummy_payment(p_booking_id uuid,p_success boolean,p_idempotency_key text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_booking public.bookings%rowtype;v_payment public.payments%rowtype;v_expected integer;v_valid integer;
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='28000'; end if;
 if p_idempotency_key is null or length(trim(p_idempotency_key))<8 then raise exception 'A valid idempotency key is required' using errcode='22023'; end if;
 select * into v_booking from public.bookings where id=p_booking_id and user_id=auth.uid() for update;
 if not found then raise exception 'Booking not found' using errcode='P0002'; end if;
 select * into v_payment from public.payments where idempotency_key=p_idempotency_key;
 if found then if v_payment.booking_id<>p_booking_id then raise exception 'Idempotency key already used' using errcode='23505'; end if; return jsonb_build_object('status',v_payment.status,'payment_id',v_payment.id); end if;
 if v_booking.status<>'PENDING' or (v_booking.expires_at is not null and v_booking.expires_at<now()) then raise exception 'Booking is not payable' using errcode='P0001'; end if;
 if p_success then
  select count(*) into v_expected from public.booking_seats where booking_id=p_booking_id;
  select count(*) into v_valid from public.booking_seats bs join public.show_seats ss on ss.id=bs.show_seat_id
  where bs.booking_id=p_booking_id and ss.status='LOCKED' and ss.locked_by=auth.uid() and ss.locked_until>now() and ss.booking_id=p_booking_id;
  if v_expected=0 or v_valid<>v_expected then raise exception 'One or more seat holds have expired' using errcode='P0001'; end if;
 end if;
 insert into public.payments(booking_id,status,amount,idempotency_key,provider_reference)
 values(p_booking_id,case when p_success then 'SUCCESS'::public.payment_status else 'FAILED'::public.payment_status end,v_booking.total,p_idempotency_key,'DUMMY-'||p_idempotency_key) returning * into v_payment;
 if p_success then
  update public.bookings set status='CONFIRMED' where id=p_booking_id;
  update public.show_seats ss set status='BOOKED',locked_until=null from public.booking_seats bs where bs.booking_id=p_booking_id and bs.show_seat_id=ss.id;
  if v_booking.promo_code_id is not null then update public.promo_codes set used_count=used_count+1 where id=v_booking.promo_code_id and (max_uses is null or used_count<max_uses); if not found then raise exception 'Promo code usage limit reached' using errcode='P0001'; end if; end if;
 end if;
 return jsonb_build_object('status',v_payment.status,'payment_id',v_payment.id);
end; $$;
grant execute on function private.confirm_dummy_payment(uuid,boolean,text) to authenticated;

create or replace function public.current_user_role()
returns public.app_role language sql stable security invoker set search_path=''
as $$ select private.current_user_role() $$;
create or replace function public.lock_show_seats(p_show_id uuid,p_seat_ids uuid[])
returns jsonb language sql security invoker set search_path=''
as $$ select private.lock_show_seats(p_show_id,p_seat_ids) $$;
create or replace function public.create_booking(p_show_id uuid,p_seat_ids uuid[],p_promo_code text default null)
returns jsonb language sql security invoker set search_path=''
as $$ select private.create_booking(p_show_id,p_seat_ids,p_promo_code) $$;
create or replace function public.confirm_dummy_payment(p_booking_id uuid,p_success boolean,p_idempotency_key text)
returns jsonb language sql security invoker set search_path=''
as $$ select private.confirm_dummy_payment(p_booking_id,p_success,p_idempotency_key) $$;

revoke all on function public.current_user_role() from public,anon;
grant execute on function public.current_user_role() to authenticated;
revoke all on function public.lock_show_seats(uuid,uuid[]) from public,anon;
grant execute on function public.lock_show_seats(uuid,uuid[]) to authenticated;
revoke all on function public.create_booking(uuid,uuid[],text) from public,anon;
grant execute on function public.create_booking(uuid,uuid[],text) to authenticated;
revoke all on function public.confirm_dummy_payment(uuid,boolean,text) from public,anon;
grant execute on function public.confirm_dummy_payment(uuid,boolean,text) to authenticated;
