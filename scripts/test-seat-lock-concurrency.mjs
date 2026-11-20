import { createClient } from "@supabase/supabase-js";
import { randomUUID } from "node:crypto";

const url = process.env.SUPABASE_URL;
const anonKey = process.env.SUPABASE_ANON_KEY;
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !anonKey || !serviceKey) {
  throw new Error("Set SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY.");
}
const admin = createClient(url, serviceKey, { auth: { autoRefreshToken: false, persistSession: false } });
const password = "TgTest-" + randomUUID() + "-aA9!";
const users = [];
let showId;
let seatId;

async function createTestUser() {
  const email = "ticketgate-race-" + randomUUID() + "@example.com";
  const { data, error } = await admin.auth.admin.createUser({ email, password, email_confirm: true });
  if (error) throw error;
  users.push(data.user.id);
  const client = createClient(url, anonKey, { auth: { autoRefreshToken: false, persistSession: false } });
  const signed = await client.auth.signInWithPassword({ email, password });
  if (signed.error) throw signed.error;
  return client;
}

try {
  const { data: show, error: showError } = await admin.from("shows").select("id").gt("starts_at", new Date().toISOString()).limit(1).single();
  if (showError) throw showError;
  showId = show.id;
  const { data: seat, error: seatError } = await admin.from("show_seats").select("seat_id").eq("show_id", showId).eq("status", "AVAILABLE").limit(1).single();
  if (seatError) throw seatError;
  seatId = seat.seat_id;

  const [clientA, clientB] = await Promise.all([createTestUser(), createTestUser()]);
  const queueResults = await Promise.all([clientA.rpc("join_show_queue", { p_show_id: showId }), clientB.rpc("join_show_queue", { p_show_id: showId })]);
  for (const result of queueResults) if (result.error) throw result.error;
  const attempts = await Promise.all([
    clientA.rpc("lock_show_seats", { p_show_id: showId, p_seat_ids: [seatId] }),
    clientB.rpc("lock_show_seats", { p_show_id: showId, p_seat_ids: [seatId] }),
  ]);
  const successes = attempts.filter((result) => !result.error).length;
  const failures = attempts.filter((result) => !!result.error).length;
  if (successes !== 1 || failures !== 1) {
    throw new Error("Concurrency invariant failed: expected exactly one lock success and one conflict; got " + successes + " success(es), " + failures + " failure(s).");
  }
  console.log("PASS: simultaneous seat lock attempts produced exactly one winner and one conflict.");
} finally {
  if (showId && seatId) {
    await admin.from("show_seats").update({ status: "AVAILABLE", locked_by: null, locked_until: null, booking_id: null }).eq("show_id", showId).eq("seat_id", seatId);
  }
  for (const userId of users) await admin.auth.admin.deleteUser(userId);
}
