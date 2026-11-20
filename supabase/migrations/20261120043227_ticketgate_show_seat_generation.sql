
create or replace function private.populate_show_seats()
returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.show_seats(show_id,seat_id,price)
 select new.id,s.id,s.base_price from public.seats s where s.hall_id=new.hall_id
 on conflict(show_id,seat_id) do nothing;
 return new;
end; $$;
drop trigger if exists on_show_created_populate_seats on public.shows;
create trigger on_show_created_populate_seats after insert on public.shows
for each row execute procedure private.populate_show_seats();
