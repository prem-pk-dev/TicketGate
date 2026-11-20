"use client";
import Link from "next/link";
import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

export default function AuthPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [resending, setResending] = useState(false);
  const [message, setMessage] = useState("");
  const [mode, setMode] = useState<"signin" | "signup">("signin");

  const emailRedirectTo = typeof window === "undefined" ? undefined : `${window.location.origin}/auth/callback`;

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setMessage("");
    try {
      const supabase = createClient();
      const result = mode === "signin"
        ? await supabase.auth.signInWithPassword({ email, password })
        : await supabase.auth.signUp({
            email,
            password,
            options: { emailRedirectTo },
          });
      if (result.error) throw result.error;
      setMessage(mode === "signin"
        ? "Signed in. You can now continue booking."
        : "Account request received. Check your inbox and spam folder for the confirmation link. If no email arrives, use Resend confirmation email below.");
    } catch (e) {
      setMessage(e instanceof Error ? e.message : "Authentication failed.");
    } finally {
      setBusy(false);
    }
  }

  async function resendConfirmation() {
    if (!email.trim()) {
      setMessage("Enter your email address first.");
      return;
    }
    setResending(true);
    setMessage("");
    try {
      const supabase = createClient();
      const { error } = await supabase.auth.resend({
        type: "signup",
        email: email.trim(),
        options: { emailRedirectTo },
      });
      if (error) throw error;
      setMessage("Confirmation email request sent. Check your inbox and spam folder.");
    } catch (e) {
      setMessage(e instanceof Error ? e.message : "Could not resend confirmation email.");
    } finally {
      setResending(false);
    }
  }

  return <main className="grid min-h-screen place-items-center px-5"><div className="w-full max-w-md rounded-3xl border border-white/10 bg-[#111521] p-8">
    <Link href="/" className="text-sm text-[#c7f36b]">← Back to TicketGate</Link>
    <h1 className="mt-8 text-3xl font-black">{mode === "signin" ? "Welcome back." : "Create your account."}</h1>
    <p className="mt-2 text-sm text-[#929bad]">Sign in to manage your tickets and bookings.</p>
    <form onSubmit={submit} className="mt-8 space-y-4">
      <label className="block text-sm">Email<input required type="email" value={email} onChange={e => setEmail(e.target.value)} className="mt-2 w-full rounded-xl border border-white/10 bg-black/20 px-4 py-3 outline-none focus:border-[#c7f36b]" /></label>
      <label className="block text-sm">Password<input required minLength={8} type="password" value={password} onChange={e => setPassword(e.target.value)} className="mt-2 w-full rounded-xl border border-white/10 bg-black/20 px-4 py-3 outline-none focus:border-[#c7f36b]" /></label>
      <button disabled={busy} className="w-full rounded-xl bg-[#c7f36b] py-3 font-bold text-black disabled:opacity-60">{busy ? "Please wait…" : mode === "signin" ? "Sign in" : "Create account"}</button>
    </form>
    {mode === "signin" && <button type="button" onClick={resendConfirmation} disabled={resending} className="mt-4 w-full text-xs text-[#c7f36b] underline disabled:opacity-60">{resending ? "Sending…" : "Resend confirmation email"}</button>}
    {message && <p role="status" aria-live="polite" className="mt-4 break-words text-sm text-[#c7f36b]">{message}</p>}
    <button onClick={() => { setMode(mode === "signin" ? "signup" : "signin"); setMessage(""); }} className="mt-6 text-xs text-[#929bad] underline">{mode === "signin" ? "New to TicketGate? Create an account" : "Already have an account? Sign in"}</button>
  </div></main>;
}
