import Link from "next/link";
import { Search, MapPin, ArrowUpRight, Music2, Clapperboard, Trophy, Theater, Sparkles, Ticket, CalendarDays } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import type { EventItem, City } from "@/lib/types";

const categories = [
  { name: "Concerts", icon: Music2, color: "#b18cff" },
  { name: "Movies", icon: Clapperboard, color: "#ff8f75" },
  { name: "Sports", icon: Trophy, color: "#8de0c0" },
  { name: "Theatre", icon: Theater, color: "#f2c66d" },
  { name: "Experiences", icon: Sparkles, color: "#78b8ff" },
];
const fallbackEvents: EventItem[] = [
  { id:"demo-1", title:"The Grand Music Festival", slug:"grand-music-festival", category:"Concerts", language:"Hindi • English", age_rating:"16+" },
  { id:"demo-2", title:"Beyond The Boundary", slug:"beyond-the-boundary", category:"Sports", language:"Live", age_rating:"All ages" },
  { id:"demo-3", title:"Midnight in Mumbai", slug:"midnight-in-mumbai", category:"Theatre", language:"Hindi", age_rating:"12+" },
  { id:"demo-4", title:"The Last Orbit", slug:"the-last-orbit", category:"Movies", language:"Hindi • English", age_rating:"UA 13+" },
];
const art = [
  ["#6c3e9b","#171c49"],["#176b66","#101b36"],["#a34d37","#24142d"],["#425f9a","#17172e"]
];

export default async function Home() {
  const supabase = await createClient();
  let events = fallbackEvents;
  let cities: City[] = [];
  if (supabase) {
    const [eventResult, cityResult] = await Promise.all([
      supabase.from("events").select("id,title,slug,category,description,poster_url,language,age_rating").eq("status","PUBLISHED").limit(8),
      supabase.from("cities").select("id,name,slug,state").eq("is_active",true).order("name")
    ]);
    if (eventResult.data?.length) events = eventResult.data as EventItem[];
    if (cityResult.data) cities = cityResult.data as City[];
  }
  return <main className="min-h-screen pb-20">
    <header className="container flex h-20 items-center justify-between">
      <Link href="/" className="flex items-center gap-2 text-xl font-black tracking-tight"><span className="grid h-9 w-9 place-items-center rounded-xl bg-[#c7f36b] text-black"><Ticket size={21}/></span>ticket<span className="text-[#c7f36b]">gate</span></Link>
      <nav className="hidden items-center gap-8 text-sm text-[#aab1c1] md:flex"><a href="#events" className="hover:text-white">Discover</a><a href="#categories" className="hover:text-white">Categories</a><a href="#how" className="hover:text-white">How it works</a></nav>
      <div className="flex items-center gap-3"><form action="/search" method="GET" className="hidden items-center gap-2 rounded-full border border-white/10 px-3 py-2 text-sm text-[#c5cada] sm:flex"><MapPin size={15}/><select name="city" defaultValue="" aria-label="Choose city" className="max-w-28 bg-transparent text-sm outline-none"><option value="">All cities</option>{cities.map(city=><option key={city.id} value={city.slug}>{city.name}</option>)}</select><button className="text-xs text-[#c7f36b]">Go</button></form><Link href="/auth" className="rounded-full bg-[#c7f36b] px-5 py-2.5 text-sm font-bold text-[#12170b] transition hover:bg-[#d8ff8a]">Sign in</Link></div>
    </header>
    <section className="container pt-10 md:pt-16">
      <div className="relative overflow-hidden rounded-[30px] border border-white/10 bg-[#171b2b] px-7 py-12 md:px-14 md:py-16">
        <div className="absolute -right-16 -top-28 h-96 w-96 rounded-full bg-[#a78bfa]/20 blur-3xl"/><div className="absolute bottom-0 right-1/4 h-56 w-56 rounded-full bg-[#c7f36b]/10 blur-3xl"/>
        <div className="relative max-w-2xl"><div className="mb-5 inline-flex items-center gap-2 rounded-full border border-[#c7f36b]/30 bg-[#c7f36b]/10 px-3 py-1.5 text-xs font-semibold text-[#d8ff9b]"><Sparkles size={13}/> YOUR CITY. YOUR SCENE. YOUR MOMENT.</div>
          <h1 className="text-4xl font-black leading-[1.08] tracking-tight md:text-6xl">Make plans.<br/><span className="text-[#c7f36b]">Make memories.</span></h1>
          <p className="mt-5 max-w-lg text-base leading-7 text-[#aab1c1] md:text-lg">The best of live entertainment, all in one place. Find your next unforgettable moment.</p>
          <form action="/search" method="GET" className="mt-8 flex max-w-xl items-center gap-3 rounded-2xl border border-white/10 bg-black/30 p-2 pl-4"><Search className="shrink-0 text-[#8e97aa]" size={20}/><input name="q" aria-label="Search events" placeholder="Search events, artists, venues..." className="min-w-0 flex-1 bg-transparent py-2 text-sm outline-none placeholder:text-[#737c90]"/><button className="rounded-xl bg-[#c7f36b] px-5 py-3 text-sm font-bold text-black">Explore</button></form>
          <div className="mt-6 flex flex-wrap gap-2 text-xs text-[#929bad]"><span>Trending:</span><span className="rounded-full bg-white/5 px-3 py-1">Live music</span><span className="rounded-full bg-white/5 px-3 py-1">Weekend plans</span><span className="rounded-full bg-white/5 px-3 py-1">New releases</span></div>
        </div>
        <div className="absolute bottom-0 right-0 hidden h-full w-[39%] items-end justify-center md:flex"><div className="relative mb-[-30px] h-[85%] w-[72%] rotate-[-7deg] rounded-t-[48%] border border-white/15 bg-gradient-to-b from-[#b98bff]/60 via-[#583e84] to-[#11172b] shadow-2xl"><div className="absolute inset-x-0 top-1/3 text-center text-7xl">✦</div><div className="absolute inset-x-0 bottom-12 text-center text-xs font-bold tracking-[.35em] text-white/80">LIVE THE MOMENT</div></div></div>
      </div>
    </section>
    <section id="categories" className="container pt-14"><div className="mb-6 flex items-end justify-between"><div><p className="text-xs font-bold tracking-[.2em] text-[#c7f36b]">EXPLORE YOUR VIBE</p><h2 className="mt-2 text-2xl font-bold">What are you in the mood for?</h2></div><a href="#events" className="hidden text-sm text-[#c7f36b] sm:block">View all <ArrowUpRight className="inline" size={15}/></a></div>
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-5">{categories.map(({name,icon:Icon,color})=><a key={name} href={"/search?category="+name} className="glass group flex items-center gap-3 rounded-2xl p-4 transition hover:-translate-y-1 hover:border-white/20"><span className="grid h-11 w-11 place-items-center rounded-xl" style={{backgroundColor:color+"20",color}}><Icon size={22}/></span><span className="text-sm font-semibold">{name}</span><ArrowUpRight className="ml-auto text-[#697287] transition group-hover:text-white" size={15}/></a>)}</div>
    </section>
    <section id="events" className="container pt-16"><div className="mb-7 flex items-end justify-between"><div><p className="text-xs font-bold tracking-[.2em] text-[#c7f36b]">HANDPICKED FOR YOU</p><h2 className="mt-2 text-2xl font-bold">Events worth stepping out for</h2><p className="mt-2 text-sm text-[#929bad]">Discover what’s happening around you.</p></div><a href="#events" className="text-sm text-[#c7f36b]">See all <ArrowUpRight className="inline" size={15}/></a></div>
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">{events.map((event,i)=><Link key={event.id} href={`/events/${event.slug}`} className="group overflow-hidden rounded-2xl border border-white/10 bg-[#111521] transition hover:-translate-y-1 hover:border-white/20">
        <div className="poster flex h-52 items-center justify-center" style={{"--c1":art[i%4][0],"--c2":art[i%4][1]} as React.CSSProperties}>{event.poster_url ? <img src={event.poster_url} alt="" className="absolute inset-0 h-full w-full object-cover"/> : <div className="relative z-10 text-center"><div className="mb-3 text-5xl">{["♫","◉","✦","▣"][i%4]}</div><span className="text-[10px] font-bold tracking-[.35em] text-white/75">{event.category.toUpperCase()}</span></div>}<span className="absolute bottom-4 left-4 z-10 rounded-full border border-white/20 bg-black/30 px-3 py-1 text-[10px] font-semibold uppercase tracking-wider">{event.category}</span></div>
        <div className="p-4"><h3 className="font-bold transition group-hover:text-[#c7f36b]">{event.title}</h3><p className="mt-2 flex items-center gap-2 text-xs text-[#929bad]"><CalendarDays size={13}/>{event.language ?? "Multiple dates"} <span>·</span>{event.age_rating ?? "All ages"}</p><div className="mt-4 flex items-center justify-between border-t border-white/10 pt-3"><span className="text-xs text-[#929bad]">Explore event</span><span className="grid h-8 w-8 place-items-center rounded-full bg-white/5 text-[#c7f36b]"><ArrowUpRight size={16}/></span></div></div>
      </Link>)}</div>
    </section>
    <section id="how" className="container pt-16"><div className="glass flex flex-col justify-between gap-6 rounded-3xl p-7 md:flex-row md:items-center md:p-10"><div><p className="text-xs font-bold tracking-[.2em] text-[#c7f36b]">SIMPLE. SECURE. SEAMLESS.</p><h2 className="mt-2 text-2xl font-bold">Your next great night is 3 steps away.</h2></div><div className="grid flex-1 gap-5 sm:grid-cols-3 md:max-w-2xl">{[["01","Find your event","Browse shows, matches and experiences."],["02","Pick your seats","Choose the spot that feels right."],["03","Show up & enjoy","Your ticket is ready on your phone."]].map(([n,t,d])=><div key={n}><span className="text-xs font-bold text-[#c7f36b]">{n}</span><h3 className="mt-2 text-sm font-bold">{t}</h3><p className="mt-1 text-xs leading-5 text-[#929bad]">{d}</p></div>)}</div></div></section>
    <footer className="container mt-16 border-t border-white/10 pt-7 text-xs text-[#717b90]"><div className="flex flex-col justify-between gap-3 sm:flex-row"><span>© 2026 TicketGate. Made for moments that matter.</span><span>Discover · Book · Experience</span></div></footer>
  </main>;
}