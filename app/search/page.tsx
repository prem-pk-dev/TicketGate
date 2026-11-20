import Link from "next/link";
import { Search,ArrowLeft,CalendarDays } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import type { EventItem,City } from "@/lib/types";
export default async function SearchPage({searchParams}:{searchParams:Promise<{q?:string;category?:string;city?:string}>}){
 const params=await searchParams;const q=(params.q||"").trim();const category=params.category||"";const city=params.city||"";
 const supabase=await createClient();let events:EventItem[]=[];let cities:City[]=[];
 if(supabase){
  const {data:cityRows}=await supabase.from("cities").select("id,name,slug,state").eq("is_active",true).order("name");if(cityRows)cities=cityRows as City[];
  let query=supabase.from("events").select("id,title,slug,category,description,poster_url,language,age_rating").eq("status","PUBLISHED");
  if(q)query=query.ilike("title","%"+q+"%");
  if(category)query=query.eq("category",category);
  if(city){const selectedCity=cities.find(c=>c.slug===city);if(selectedCity){query=supabase.from("events").select("id,title,slug,category,description,poster_url,language,age_rating,shows!inner(halls!inner(venues!inner(city_id)))").eq("status","PUBLISHED").eq("shows.halls.venues.city_id",selectedCity.id);if(q)query=query.ilike("title","%"+q+"%");if(category)query=query.eq("category",category);}}
  const {data}=await query.limit(30);if(data)events=data as unknown as EventItem[];
 }
 return <main className="container min-h-screen py-10"><Link href="/" className="inline-flex items-center gap-2 text-sm text-[#c7f36b]"><ArrowLeft size={16}/> Home</Link><div className="mt-8"><p className="text-xs font-bold tracking-[.2em] text-[#c7f36b]">DISCOVER</p><h1 className="mt-2 text-3xl font-black">Find your next experience</h1></div>
 <form action="/search" method="GET" className="mt-6 grid gap-3 rounded-2xl border border-white/10 bg-[#111521] p-4 sm:grid-cols-[1fr_180px_180px_auto]"><label className="flex items-center gap-3"><Search className="text-[#929bad]" size={18}/><input name="q" defaultValue={q} placeholder="Search event title…" className="w-full bg-transparent py-2 text-sm outline-none"/></label><select name="category" defaultValue={category} className="rounded-xl border border-white/10 bg-[#171c2a] px-3 py-3 text-sm"><option value="">All categories</option>{["Concerts","Movies","Sports","Theatre","Experiences"].map(x=><option key={x}>{x}</option>)}</select><select name="city" defaultValue={city} className="rounded-xl border border-white/10 bg-[#171c2a] px-3 py-3 text-sm"><option value="">All cities</option>{cities.map(x=><option key={x.id} value={x.slug}>{x.name}</option>)}</select><button className="rounded-xl bg-[#c7f36b] px-5 py-3 text-sm font-bold text-black">Search</button></form>
 <p className="mt-7 text-sm text-[#929bad]">{events.length} event(s) found</p>
 <div className="mt-4 grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">{events.map((e,i)=><Link key={e.id} href={"/events/"+e.slug} className="overflow-hidden rounded-2xl border border-white/10 bg-[#111521] transition hover:-translate-y-1 hover:border-white/20"><div className="flex h-44 items-center justify-center bg-gradient-to-br from-[#43345f] to-[#151b30]">{e.poster_url?<img src={e.poster_url} alt="" className="h-full w-full object-cover"/>:<span className="text-5xl text-[#c7f36b]">{["♫","◉","✦","▣"][i%4]}</span>}</div><div className="p-4"><p className="text-[10px] font-bold uppercase tracking-wider text-[#c7f36b]">{e.category}</p><h2 className="mt-2 font-bold">{e.title}</h2><p className="mt-2 flex items-center gap-2 text-xs text-[#929bad]"><CalendarDays size={13}/>{e.language||"Multiple dates"}</p></div></Link>)}</div>
 {events.length===0&&<div className="mt-8 rounded-2xl border border-white/10 bg-[#111521] p-8 text-center text-sm text-[#929bad]">No matching events yet. Try another search or city.</div>}
 </main>;
}