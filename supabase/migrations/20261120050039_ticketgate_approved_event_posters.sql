update public.events
set poster_url='https://media-assets-4sb.pages.dev/thumbnails/event-concert.webp'
where slug in ('arijit-singh-live','sunburn-neon-nights','project-raag')
  and (poster_url is null or poster_url='');
update public.events
set poster_url='https://media-assets-4sb.pages.dev/images/05_food_culture/food_culture_01.jpg'
where slug='hyderabad-food-carnival' and (poster_url is null or poster_url='');