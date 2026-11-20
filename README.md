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
- Responsive discovery homepage with city/event data from Supabase.
- Event detail pages and showtime links.
- Sign-up/sign-in using Supabase Auth.
- Interactive seat map, max 10 seats per booking.
- Atomic 10-minute seat holds using Postgres row locks.
- Booking creation RPC with fees and promo validation.
- Dummy success/failure payment RPC with idempotency.
- Booking history and QR digital ticket.
- Seeded demo catalog: 5 cities, 8 venues, 12 events, 12 shows, 960 seat records.
- Promo codes: `WELCOME10`, `TICKET50`.

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
New users receive the `USER` role. New users receive the `USER` role. To bootstrap the first admin, sign up through `/auth`, then run this once in the Supabase SQL Editor using that account's email:\n\n```sql\nupdate public.profiles p set role = 'ADMIN'\nfrom auth.users u where p.id = u.id and u.email = 'YOUR_LOGIN_EMAIL';\n```\n\nAfter that, assign `ORGANIZER` roles from the Admin dashboard. Role updates are protected by an admin-only database RPC.

## Verification status
Supabase migrations and seed counts have been applied and verified. Supabase seed counts and security advisor have been verified. A production build, browser E2E tests, two-client seat-lock race test, and live Cloudflare deployment remain pending. Cloudflare Git repository connection has been registered; finish the Worker import/build in the Cloudflare dashboard as described in `docs/deploy-cloudflare.md`.
