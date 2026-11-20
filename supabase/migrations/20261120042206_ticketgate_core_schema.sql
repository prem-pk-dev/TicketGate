
create extension if not exists pgcrypto;
create type public.app_role as enum ('USER','ORGANIZER','ADMIN');
create type public.show_seat_status as enum ('AVAILABLE','LOCKED','BOOKED');
create type public.booking_status as enum ('PENDING','CONFIRMED','CANCELLED','EXPIRED','REFUNDED');
create type public.payment_status as enum ('INITIATED','SUCCESS','FAILED','REFUNDED');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  role public.app_role not null default 'USER',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.cities (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  state text not null,
  is_active boolean not null default true
);
create table public.venues (
  id uuid primary key default gen_random_uuid(),
  city_id uuid not null references public.cities(id),
  name text not null,
  slug text not null unique,
  address text not null,
  description text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
create table public.halls (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references public.venues(id) on delete cascade,
  name text not null,
  seat_rows integer not null default 10 check (seat_rows between 1 and 100),
  seat_columns integer not null default 10 check (seat_columns between 1 and 100)
);
create table public.seats (
  id uuid primary key default gen_random_uuid(),
  hall_id uuid not null references public.halls(id) on delete cascade,
  row_label text not null,
  seat_number integer not null check (seat_number > 0),
  category text not null default 'STANDARD',
  base_price numeric(10,2) not null default 0 check (base_price >= 0),
  unique(hall_id,row_label,seat_number)
);
create table public.events (
  id uuid primary key default gen_random_uuid(),
  organizer_id uuid references public.profiles(id),
  title text not null,
  slug text not null unique,
  description text,
  category text not null,
  poster_url text,
  banner_url text,
  language text,
  duration_minutes integer,
  age_rating text,
  status text not null default 'DRAFT' check (status in ('DRAFT','PUBLISHED','CANCELLED')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.shows (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  hall_id uuid not null references public.halls(id),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  sales_open boolean not null default true,
  check (ends_at > starts_at)
);
create table public.show_seats (
  id uuid primary key default gen_random_uuid(),
  show_id uuid not null references public.shows(id) on delete cascade,
  seat_id uuid not null references public.seats(id),
  price numeric(10,2) not null check (price >= 0),
  status public.show_seat_status not null default 'AVAILABLE',
  locked_by uuid references public.profiles(id),
  locked_until timestamptz,
  booking_id uuid,
  unique(show_id,seat_id)
);
create table public.add_ons (
  id uuid primary key default gen_random_uuid(),
  event_id uuid references public.events(id) on delete cascade,
  name text not null,
  description text,
  price numeric(10,2) not null check (price >= 0),
  is_active boolean not null default true
);
create table public.promo_codes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  discount_percent numeric(5,2) check (discount_percent between 0 and 100),
  discount_amount numeric(10,2) check (discount_amount >= 0),
  min_order numeric(10,2) not null default 0,
  max_uses integer,
  used_count integer not null default 0,
  valid_from timestamptz not null default now(),
  valid_until timestamptz,
  is_active boolean not null default true,
  check (discount_percent is not null or discount_amount is not null)
);
create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  booking_code text not null unique default upper(substr(encode(gen_random_bytes(8),'hex'),1,12)),
  user_id uuid not null references public.profiles(id),
  show_id uuid not null references public.shows(id),
  status public.booking_status not null default 'PENDING',
  subtotal numeric(10,2) not null default 0,
  fees numeric(10,2) not null default 0,
  discount numeric(10,2) not null default 0,
  total numeric(10,2) not null default 0,
  promo_code_id uuid references public.promo_codes(id),
  expires_at timestamptz,
  qr_token uuid not null default gen_random_uuid(),
  created_at timestamptz not null default now()
);
alter table public.show_seats add constraint show_seats_booking_fk foreign key (booking_id) references public.bookings(id);
create table public.booking_seats (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  show_seat_id uuid not null references public.show_seats(id),
  price numeric(10,2) not null,
  unique(booking_id,show_seat_id)
);
create table public.booking_add_ons (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  add_on_id uuid not null references public.add_ons(id),
  quantity integer not null default 1 check (quantity between 1 and 20),
  unit_price numeric(10,2) not null
);
create table public.payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id),
  provider text not null default 'DUMMY',
  status public.payment_status not null default 'INITIATED',
  amount numeric(10,2) not null check (amount >= 0),
  idempotency_key text not null unique,
  provider_reference text,
  created_at timestamptz not null default now()
);
create table public.check_ins (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id),
  checked_in_by uuid references public.profiles(id),
  checked_in_at timestamptz not null default now()
);

create index shows_event_starts_idx on public.shows(event_id,starts_at);
create index events_status_category_idx on public.events(status,category);
create index show_seats_show_status_idx on public.show_seats(show_id,status);
create index bookings_user_created_idx on public.bookings(user_id,created_at desc);
create index bookings_expiry_idx on public.bookings(status,expires_at);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id,full_name)
  values(new.id, coalesce(new.raw_user_meta_data->>'full_name',''));
  return new;
end; $$;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.lock_show_seats(p_show_id uuid, p_seat_ids uuid[])
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_user uuid := auth.uid(); v_count integer; v_distinct integer;
begin
  if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
  v_distinct := coalesce(array_length(p_seat_ids,1),0);
  if v_distinct < 1 or v_distinct > 10 then
    raise exception 'Select between 1 and 10 seats' using errcode='22023';
  end if;
  if (select count(distinct x) from unnest(p_seat_ids) x) <> v_distinct then
    raise exception 'Duplicate seats are not allowed' using errcode='22023';
  end if;
  perform 1 from public.show_seats
   where show_id=p_show_id and seat_id=any(p_seat_ids)
   order by seat_id for update;
  select count(*) into v_count from public.show_seats
   where show_id=p_show_id and seat_id=any(p_seat_ids)
     and (status='AVAILABLE' or (status='LOCKED' and locked_until < now()) or (status='LOCKED' and locked_by=v_user));
  if v_count <> v_distinct then
    raise exception 'One or more seats are no longer available' using errcode='P0001';
  end if;
  update public.show_seats
     set status='LOCKED', locked_by=v_user, locked_until=now()+interval '10 minutes'
   where show_id=p_show_id and seat_id=any(p_seat_ids);
  return jsonb_build_object('success',true,'locked_until',now()+interval '10 minutes','seat_count',v_distinct);
end; $$;

create or replace function public.release_expired_seat_locks()
returns integer language plpgsql security definer set search_path = public as $$
declare v_count integer;
begin
 update public.show_seats set status='AVAILABLE',locked_by=null,locked_until=null
 where status='LOCKED' and locked_until < now();
 get diagnostics v_count = row_count;
 return v_count;
end; $$;

create or replace function public.confirm_dummy_payment(p_booking_id uuid, p_success boolean, p_idempotency_key text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_booking public.bookings%rowtype; v_payment public.payments%rowtype;
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='28000'; end if;
 select * into v_booking from public.bookings where id=p_booking_id and user_id=auth.uid() for update;
 if not found then raise exception 'Booking not found' using errcode='P0002'; end if;
 select * into v_payment from public.payments where idempotency_key=p_idempotency_key;
 if found then return jsonb_build_object('status',v_payment.status,'payment_id',v_payment.id); end if;
 if v_booking.status <> 'PENDING' or (v_booking.expires_at is not null and v_booking.expires_at < now()) then
   raise exception 'Booking is not payable' using errcode='P0001';
 end if;
 insert into public.payments(booking_id,status,amount,idempotency_key,provider_reference)
 values(p_booking_id,case when p_success then 'SUCCESS'::public.payment_status else 'FAILED'::public.payment_status end,
        v_booking.total,p_idempotency_key,'DUMMY-'||p_idempotency_key)
 returning * into v_payment;
 if p_success then
   update public.bookings set status='CONFIRMED' where id=p_booking_id;
   update public.show_seats ss set status='BOOKED',booking_id=p_booking_id,locked_until=null
    from public.booking_seats bs where bs.booking_id=p_booking_id and bs.show_seat_id=ss.id
      and ss.locked_by=auth.uid() and ss.status='LOCKED' and ss.locked_until > now();
 else
   update public.bookings set status='PENDING' where id=p_booking_id;
 end if;
 return jsonb_build_object('status',v_payment.status,'payment_id',v_payment.id);
end; $$;

alter table public.profiles enable row level security;
alter table public.cities enable row level security;
alter table public.venues enable row level security;
alter table public.halls enable row level security;
alter table public.seats enable row level security;
alter table public.events enable row level security;
alter table public.shows enable row level security;
alter table public.show_seats enable row level security;
alter table public.add_ons enable row level security;
alter table public.promo_codes enable row level security;
alter table public.bookings enable row level security;
alter table public.booking_seats enable row level security;
alter table public.booking_add_ons enable row level security;
alter table public.payments enable row level security;
alter table public.check_ins enable row level security;

create policy "profiles read self or admin" on public.profiles for select to authenticated using (id=auth.uid() or exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='ADMIN'));
create policy "profiles update self" on public.profiles for update to authenticated using (id=auth.uid()) with check (id=auth.uid());
create policy "cities public read" on public.cities for select to anon,authenticated using (is_active);
create policy "venues public read" on public.venues for select to anon,authenticated using (true);
create policy "halls public read" on public.halls for select to anon,authenticated using (true);
create policy "seats public read" on public.seats for select to anon,authenticated using (true);
create policy "published events public read" on public.events for select to anon,authenticated using (status='PUBLISHED' or organizer_id=auth.uid());
create policy "shows public read" on public.shows for select to anon,authenticated using (exists(select 1 from public.events e where e.id=event_id and e.status='PUBLISHED'));
create policy "show seats public read" on public.show_seats for select to anon,authenticated using (true);
create policy "active addons public read" on public.add_ons for select to anon,authenticated using (is_active);
create policy "active promo public read" on public.promo_codes for select to anon,authenticated using (is_active and now() between valid_from and coalesce(valid_until,'infinity'::timestamptz));
create policy "users read own bookings" on public.bookings for select to authenticated using (user_id=auth.uid() or exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('ADMIN','ORGANIZER')));
create policy "users create own bookings" on public.bookings for insert to authenticated with check (user_id=auth.uid());
create policy "users read own booking seats" on public.booking_seats for select to authenticated using (exists(select 1 from public.bookings b where b.id=booking_id and b.user_id=auth.uid()));
create policy "users read own booking addons" on public.booking_add_ons for select to authenticated using (exists(select 1 from public.bookings b where b.id=booking_id and b.user_id=auth.uid()));
create policy "users read own payments" on public.payments for select to authenticated using (exists(select 1 from public.bookings b where b.id=booking_id and b.user_id=auth.uid()));
create policy "checkin owner or staff read" on public.check_ins for select to authenticated using (exists(select 1 from public.bookings b where b.id=booking_id and b.user_id=auth.uid()) or exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('ADMIN','ORGANIZER')));

grant execute on function public.lock_show_seats(uuid,uuid[]) to authenticated;
grant execute on function public.confirm_dummy_payment(uuid,boolean,text) to authenticated;
grant execute on function public.release_expired_seat_locks() to service_role;
