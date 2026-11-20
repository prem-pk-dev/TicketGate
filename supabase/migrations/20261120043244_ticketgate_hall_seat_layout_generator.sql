
create or replace function private.populate_hall_seats()
returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.seats(hall_id,row_label,seat_number,category,base_price)
 select new.id,
   case when r.row_no<=26 then chr(64+r.row_no) else 'R'||r.row_no end,
   s.seat_no,
   case when r.row_no<=greatest(1,floor(new.seat_rows*0.2)) then 'PREMIUM'
        when r.row_no<=greatest(2,floor(new.seat_rows*0.65)) then 'STANDARD' else 'ECONOMY' end,
   case when r.row_no<=greatest(1,floor(new.seat_rows*0.2)) then 1800
        when r.row_no<=greatest(2,floor(new.seat_rows*0.65)) then 1100 else 650 end
 from generate_series(1,new.seat_rows) r(row_no)
 cross join generate_series(1,new.seat_columns) s(seat_no);
 return new;
end; $$;
drop trigger if exists on_hall_created_populate_seats on public.halls;
create trigger on_hall_created_populate_seats after insert on public.halls
for each row execute procedure private.populate_hall_seats();
