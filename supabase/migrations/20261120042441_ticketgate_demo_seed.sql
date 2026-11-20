
insert into public.cities(name,slug,state) values
 ('Mumbai','mumbai','Maharashtra'),('Delhi-NCR','delhi-ncr','Delhi'),('Bengaluru','bengaluru','Karnataka'),
 ('Jaipur','jaipur','Rajasthan'),('Hyderabad','hyderabad','Telangana')
on conflict (slug) do nothing;

insert into public.venues(city_id,name,slug,address,description)
select c.id,v.name,v.slug,v.address,v.description
from (values
 ('mumbai','Aurora Arena','aurora-arena','Bandra Kurla Complex, Mumbai','A modern live-event arena'),
 ('mumbai','PVR Icon Phoenix','pvr-icon-phoenix','Lower Parel, Mumbai','Premium cinema and screening venue'),
 ('delhi-ncr','The Dome NCR','the-dome-ncr','Sector 29, Gurugram','A flexible performance venue'),
 ('delhi-ncr','Cinepolis Pacific','cinepolis-pacific','Tagore Garden, New Delhi','Premium multiplex'),
 ('bengaluru','Indiranagar Grounds','indiranagar-grounds','Indiranagar, Bengaluru','Open-air concert grounds'),
 ('jaipur','Pink City Auditorium','pink-city-auditorium','C-Scheme, Jaipur','Performing arts auditorium'),
 ('hyderabad','Hitech City Stadium','hitech-city-stadium','HITEC City, Hyderabad','Sports and entertainment venue'),
 ('hyderabad','AMB Cinemas','amb-cinemas','Gachibowli, Hyderabad','Luxury cinema experience')
) as v(city_slug,name,slug,address,description)
join public.cities c on c.slug=v.city_slug
where not exists(select 1 from public.venues x where x.slug=v.slug);

insert into public.halls(venue_id,name,seat_rows,seat_columns)
select v.id,'Main Hall',8,10 from public.venues v
where not exists(select 1 from public.halls h where h.venue_id=v.id);

insert into public.seats(hall_id,row_label,seat_number,category,base_price)
select h.id,chr(64+r.row_no),s.seat_no,
 case when r.row_no<=2 then 'PREMIUM' when r.row_no<=5 then 'STANDARD' else 'ECONOMY' end,
 case when r.row_no<=2 then 1800 when r.row_no<=5 then 1100 else 650 end
from public.halls h cross join generate_series(1,8) r(row_no) cross join generate_series(1,10) s(seat_no)
where not exists(select 1 from public.seats z where z.hall_id=h.id);

insert into public.events(title,slug,description,category,language,age_rating,duration_minutes,status)
values
 ('Arijit Singh — Live in Concert','arijit-singh-live','An unforgettable evening of music, stories and live performances.','Concerts','Hindi','16+',150,'PUBLISHED'),
 ('Sunburn Arena: Neon Nights','sunburn-neon-nights','A high-energy electronic music night with immersive visuals.','Concerts','English','18+',210,'PUBLISHED'),
 ('India vs Australia — T20','india-vs-australia-t20','Catch the action live from the stands.','Sports','Live','All ages',210,'PUBLISHED'),
 ('Jaipur Literature Festival','jaipur-literature-festival','Ideas, conversations and stories from remarkable voices.','Experiences','Hindi • English','All ages',360,'PUBLISHED'),
 ('The Lion King — Stage Musical','lion-king-stage-musical','A spectacular stage production for the whole family.','Theatre','English','All ages',140,'PUBLISHED'),
 ('Midnight in Mumbai','midnight-in-mumbai','A contemporary theatre story about the city that never sleeps.','Theatre','Hindi','12+',120,'PUBLISHED'),
 ('The Last Orbit','the-last-orbit','A science-fiction adventure on the big screen.','Movies','Hindi • English','UA 13+',145,'PUBLISHED'),
 ('Project Raag','project-raag','A celebration of independent Indian music.','Concerts','Hindi','16+',180,'PUBLISHED'),
 ('Bengaluru FC — Home Match','bengaluru-fc-home','Experience the roar of the home crowd.','Sports','Live','All ages',120,'PUBLISHED'),
 ('Hyderabad Food Carnival','hyderabad-food-carnival','A weekend celebration of food, culture and music.','Experiences','Multiple','All ages',300,'PUBLISHED'),
 ('The Comedy Collective','the-comedy-collective','A live stand-up showcase featuring rising voices.','Theatre','Hindi • English','18+',110,'PUBLISHED'),
 ('Galaxy Quest: IMAX Experience','galaxy-quest-imax','A larger-than-life cinematic adventure.','Movies','English','UA 13+',130,'PUBLISHED')
on conflict (slug) do nothing;

with ranked_events as (
  select e.id,e.duration_minutes,row_number() over(order by e.slug) rn
  from public.events e where e.status='PUBLISHED'
), ranked_halls as (
  select h.id,row_number() over(order by v.slug) rn
  from public.halls h join public.venues v on v.id=h.venue_id
)
insert into public.shows(event_id,hall_id,starts_at,ends_at)
select e.id,h.id,now()+(e.rn*2+2)*interval '1 day',
       now()+(e.rn*2+2)*interval '1 day'+make_interval(mins=>coalesce(e.duration_minutes,120))
from ranked_events e join ranked_halls h on h.rn=((e.rn-1)%8)+1
where not exists(select 1 from public.shows s where s.event_id=e.id);

insert into public.show_seats(show_id,seat_id,price)
select sh.id,st.id,st.base_price
from public.shows sh join public.seats st on st.hall_id=sh.hall_id
where not exists(select 1 from public.show_seats ss where ss.show_id=sh.id and ss.seat_id=st.id);

insert into public.add_ons(name,description,price,is_active)
select x.name,x.description,x.price,true from (values
 ('Snack Combo','Popcorn and beverage combo',250::numeric),
 ('Fast Track Entry','Priority entry lane',150::numeric),
 ('Merch Pack','Event exclusive merchandise',499::numeric)
) x(name,description,price)
where not exists(select 1 from public.add_ons a where a.name=x.name);

insert into public.promo_codes(code,discount_percent,min_order,max_uses,is_active)
values ('WELCOME10',10,500,10000,true) on conflict(code) do nothing;
insert into public.promo_codes(code,discount_amount,min_order,max_uses,is_active)
values ('TICKET50',50,300,5000,true) on conflict(code) do nothing;
