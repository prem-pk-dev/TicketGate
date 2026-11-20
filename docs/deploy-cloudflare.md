# Cloudflare Workers deployment

TicketGate uses the Cloudflare OpenNext adapter for its Next.js App Router deployment.

## Worker settings
- Worker name: `ticketgate` (must match `wrangler.jsonc`)
- Production branch: `main`
- Root directory: `/`
- Build command: `npx opennextjs-cloudflare build`
- Deploy command: `npx wrangler deploy`

## Connect GitHub
1. Open Cloudflare Dashboard → **Workers & Pages** → **Create application** → **GitHub**.
2. Authorize the GitHub integration if prompted.
3. Select `prem-pk-dev/TicketGate` and branch `main`.
4. Set the Worker name to `ticketgate` and root directory to `/`.
5. Set build command to `npx opennextjs-cloudflare build`.
6. Set deploy command to `npx wrangler deploy`.
7. In **Build variables and secrets**, add:
   - `NEXT_PUBLIC_SUPABASE_URL` = value in `.env.example`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY` = value in `.env.example`
   These public client values must be present at build time for Next.js to inline them.
8. Save and Deploy. Cloudflare Workers Builds automatically creates its deployment API token by default; do not create or paste a token into GitHub.

Cloudflare should show a `workers.dev` URL when the first deployment succeeds. The Worker name must match `wrangler.jsonc` or the build will fail.

## Local commands
```bash
npm install
npm run dev
npm run preview
npm run deploy
```

## Cost
No paid add-ons or payment processor are configured. Workers Builds and Supabase usage remain subject to the accounts' free-tier quotas; check usage before enabling any paid plan.

Official guide: https://developers.cloudflare.com/workers/ci-cd/builds/
