"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
export default function CancelBookingButton({bookingId}:{bookingId:string}){
 const router=useRouter();const [busy,setBusy]=useState(false);const [message,setMessage]=useState("");
 async function cancel(){if(!window.confirm("Cancel this ticket? The dummy payment will be marked as refunded."))return;setBusy(true);const supabase=createClient();const {error}=await supabase.rpc("cancel_booking",{p_booking_id:bookingId});setMessage(error?error.message:"Booking cancelled. Simulated refund recorded.");setBusy(false);if(!error)router.refresh();}
 return <div className="mt-3"><button onClick={cancel} disabled={busy} className="rounded-xl border border-[#ff927f]/40 px-4 py-2 text-xs font-semibold text-[#ffad9f] disabled:opacity-50">{busy?"Cancelling…":"Cancel booking"}</button>{message&&<p role="status" className="mt-2 text-xs text-[#ffad9f]">{message}</p>}</div>;
}