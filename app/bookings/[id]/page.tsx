import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { CheckCircle2, CalendarDays, MapPin } from "lucide-react";
import { QRCodeSVG } from "qrcode.react";
import { createClient } from "@/lib/supabase/server";
import CancelBookingButton from "@/components/cancel-booking-button";

type BookingShow = {
  starts_at: string;
  events: { title: string } | null;
  halls: { name: string; venues: { name: string; address: string | null } | null } | null;
};

export default async function BookingPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const supabase = await createClient();
  if (!supabase) redirect("/auth");
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/auth");
  const { data: booking } = await supabase.from("bookings")
    .select("id,booking_code,status,total,qr_token,created_at,shows(starts_at,events(title),halls(name,venues(name,address)))")
    .eq("id", id).eq("user_id", user.id).maybeSingle();
  if (!booking) notFound();

  const show = booking.shows as unknown as BookingShow | null;
  const canCancel = booking.status === "CONFIRMED" && new Date(show?.starts_at ?? 0).getTime() > Date.now() + 24 * 60 * 60 * 1000;

  return <main className="container grid min-h-screen place-items-center py-12"><div className="w-full max-w-xl rounded-3xl border border-white/10 bg-[#111521] p-8 text-center">
    <div className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-[#c7f36b]/15 text-[#c7f36b]"><CheckCircle2 size={32}/></div>
    <p className="mt-5 text-xs font-bold tracking-[.2em] text-[#c7f36b]">BOOKING CONFIRMED</p><h1 className="mt-2 text-3xl font-black">You’re going!</h1>
    <p className="mt-2 text-sm text-[#929bad]">Your digital ticket is ready. Keep this QR code safe.</p>
    <div className="mt-8 rounded-2xl border border-dashed border-white/20 bg-black/20 p-6">
      <p className="text-xs text-[#929bad]">BOOKING REFERENCE</p><p className="mt-1 text-2xl font-black tracking-widest">{booking.booking_code}</p>
      <div className="mx-auto mt-6 inline-block rounded-2xl bg-white p-3"><QRCodeSVG value={String(booking.qr_token)} size={190} level="H" includeMargin/></div>
      <p className="mt-3 text-[10px] text-[#929bad]">Present this QR code at the venue entrance.</p>
      <p className="mt-5 text-base font-bold">{show?.events?.title}</p>
      <p className="mt-2 flex items-center justify-center gap-2 text-xs text-[#929bad]"><CalendarDays size={14}/>{show?.starts_at ? new Date(show.starts_at).toLocaleString("en-IN",{dateStyle:"full",timeStyle:"short"}) : "Show time unavailable"}</p>
      <p className="mt-2 flex items-center justify-center gap-2 text-xs text-[#929bad]"><MapPin size={14}/>{show?.halls?.venues?.name} · {show?.halls?.name}</p>
      <p className="mt-5 text-xl font-bold">₹{Number(booking.total).toFixed(2)}</p>{canCancel&&<CancelBookingButton bookingId={booking.id}/>}
    </div>
    <div className="mt-7 flex flex-wrap justify-center gap-3"><Link href="/my-bookings" className="rounded-xl border border-white/10 px-5 py-3 text-sm font-semibold">My bookings</Link><Link href="/" className="rounded-xl bg-[#c7f36b] px-6 py-3 text-sm font-bold text-black">Discover more events</Link></div>
  </div></main>;
}
