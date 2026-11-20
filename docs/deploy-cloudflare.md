# Cloudflare Workers deployment

TicketGate uses the Cloudflare OpenNext adapter for its Next.js App Router deployment.

## Worker settings
- Worker name: `ticketgate`
- Build command: `npx opennextjs-cloudflare build`
- Deploy command: `npx wrangler deploy`
- Production branch: `main`
- Root directory: `/`

The Worker configuration already contains the public Supabase project URL and publishable key. These values are intended to be public browser configuration; never put a Supabase service-role key in the Worker vars or browser bundle.

## Connect GitHub
In Cloudflare Dashboard:
1. Open **Workers & Pages** → **Create application** → **Import a repository**.
2. Authorize GitHub if prompted and select `prem-pk-dev/TicketGate`.
3. Select `main` as the production branch.
4. Set the build command to `npx opennextjs-cloudflare build`.
5. Set the deploy command to `npx wrangler deploy`.
6. Set the root directory to `/`, then Save and Deploy.

Cloudflare may create a pull request to add framework configuration. Review it rather than overwriting the existing OpenNext configuration.

## Local commands
```bash
npm install
npm run dev
npm run preview
npm run deploy
```

## Cost
Workers and Supabase have free-tier limits and quotas. No paid add-ons or payment processor are configured. Check current account usage before enabling paid plans or optional services.
