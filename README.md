# TicketGate

A modern event-ticket discovery and booking platform built for India.

## Stack
- Next.js App Router + TypeScript + Tailwind CSS
- Supabase Postgres, Auth, RLS and transactional RPC functions
- Cloudflare Workers + OpenNext adapter
- Dummy payment flow only; no real payment processing

## Local setup
1. Install Node.js 20.9+.
2. Copy `.env.example` to `.env.local`.
3. Add the TicketGate Supabase URL and publishable key (already shown in `.env.example`).
4. Run `npm install`, then `npm run dev`.
5. Open http://localhost:3000.

## Implemented
- Responsive discovery homepage with event search, category and city filters.
- Event detail pages and showtime links.
- Sign-up/sign-in using Supabase Auth.
- Interactive seat map, max 10 seats per booking.
- Database-backed virtual waiting room with admission slots.
- Atomic 10-minute seat holds using Postgres row locks.
- Booking creation RPC with add-ons, fees and promo validation.
- Dummy success/failure payment RPC with idempotency.
- Booking history, QR digital ticket, cancellation and simulated refund.
- Organizer event/show management and automatic seat-map generation.
- Admin dashboard for users, roles, cities, venues and halls.
- Staff ticket validation and check-in.
- Two-client concurrency test script at `scripts/test-seat-lock-concurrency.mjs`.
- Seeded demo catalog: 5 cities, 8 venues, 12 events, 12 shows, 960 seat records.
- Promo codes: `WELCOME10`, `TICKET50`.

## Database setup
The exact applied SQL history is tracked under `supabase/migrations/`. Link the existing project with `supabase link --project-ref nokxeuxmhbbnllijnfht`, then use `supabase migration list` to verify it matches. Use `supabase db push` only for new migrations; do not reset the production project.

## Database safety
All exposed tables have RLS enabled. Seat availability is exposed through a column-safe view; internal lock owner and booking fields are not public. Security-sensitive RPC implementations live in a private schema and are called through authenticated wrappers. Never expose a Supabase service-role key.

## Cloudflare
See [Cloudflare deployment guide](docs/deploy-cloudflare.md). The Worker uses `wrangler.jsonc`, `open-next.config.ts`, and the OpenNext adapter. Cloudflare Workers Builds should use:
- Build: `npx opennextjs-cloudflare build`
- Deploy: `npx wrangler deploy`
- Branch: `main`

## Payment
The checkout is a simulation only. It does not collect card details or move money.

## Roles
New users receive the `USER` role. To bootstrap the first admin, sign up through `/auth`, then run this once in the Supabase SQL Editor using that account's email:

```sql
update public.profiles p set role = 'ADMIN'
from auth.users u where p.id = u.id and u.email = 'YOUR_LOGIN_EMAIL';
```

After that, assign `ORGANIZER` roles from the Admin dashboard. Role updates are protected by an admin-only database RPC.

## Verification status
Supabase migrations, seed counts and security advisor have been verified. A production build and browser E2E tests remain pending. The two-client seat-lock test is wired into CI but requires the GitHub secret `SUPABASE_SERVICE_ROLE_KEY` to execute. Live Cloudflare deployment remains pending. Cloudflare Git repository connection has been registered; finish the Worker import/build in the Cloudflare dashboard as described in `docs/deploy-cloudflare.md`.
