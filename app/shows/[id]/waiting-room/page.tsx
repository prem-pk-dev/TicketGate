"use client";
import Link from "next/link";
import { useEffect,useState } from "react";
import { useParams,useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Users,Clock3,ArrowRight,RefreshCw } from "lucide-react";
type QueueState={status:string;position:number|null;expires_at?:string};
export default function WaitingRoomPage(){
 const {id}=useParams<{id:string}>();const router=useRouter();const [supabase]=useState(()=>createClient());
 const [queue,setQueue]=useState<QueueState|null>(null);const [error,setError]=useState("");const [busy,setBusy]=useState(false);
 async function join(){setBusy(true);setError("");const {data,error:rpcError}=await supabase.rpc("join_show_queue",{p_show_id:id});if(rpcError)setError(rpcError.message);else setQueue(data as QueueState);setBusy(false);}
 async function refresh(){const {data,error:rpcError}=await supabase.rpc("get_show_queue_status",{p_show_id:id});if(rpcError)setError(rpcError.message);else setQueue(data as QueueState);}
 useEffect(()=>{join();},[id]);
 useEffect(()=>{if(!queue||queue.status!=="WAITING")return;const timer=setInterval(refresh,4000);return()=>clearInterval(timer);},[queue?.status,id]);
 return <main className="container grid min-h-screen place-items-center py-12"><div className="w-full max-w-lg rounded-3xl border border-white/10 bg-[#111521] p-8 text-center"><Link href="/" className="text-sm text-[#c7f36b]">← Back to events</Link><div className="mx-auto mt-8 grid h-16 w-16 place-items-center rounded-full bg-[#c7f36b]/10 text-[#c7f36b]"><Users size={30}/></div><p className="mt-5 text-xs font-bold tracking-[.2em] text-[#c7f36b]">VIRTUAL WAITING ROOM</p><h1 className="mt-2 text-3xl font-black">{queue?.status==="ADMITTED"?"You’re up next.":"Getting your place in line."}</h1>
 {!queue&&<p className="mt-4 text-sm text-[#929bad]">Joining the secure queue…</p>}
 {queue?.status==="WAITING"&&<><p className="mt-4 text-sm text-[#929bad]">High demand right now. This page checks your position automatically.</p><div className="mt-7 rounded-2xl border border-white/10 bg-black/20 p-6"><p className="text-xs text-[#929bad]">YOUR QUEUE POSITION</p><p className="mt-2 text-5xl font-black text-[#c7f36b]">#{queue.position}</p><div className="mt-4 flex items-center justify-center gap-2 text-xs text-[#929bad]"><RefreshCw size={13}/> Refreshing every 4 seconds</div></div></>}
 {queue?.status==="ADMITTED"&&<><p className="mt-4 text-sm text-[#929bad]">You have 30 minutes to proceed. Seat holds last 10 minutes at checkout.</p><button onClick={()=>router.push("/shows/"+id+"/seats")} className="mt-7 inline-flex items-center gap-2 rounded-xl bg-[#c7f36b] px-6 py-3 text-sm font-bold text-black">Choose your seats <ArrowRight size={16}/></button></>}
 {queue?.status==="EXPIRED"&&<button onClick={join} disabled={busy} className="mt-7 rounded-xl bg-[#c7f36b] px-6 py-3 text-sm font-bold text-black">{busy?"Joining…":"Rejoin waiting room"}</button>}
 {error&&<p role="alert" className="mt-5 text-xs text-[#ffad9f]">{error}</p>}
 </div></main>;
}