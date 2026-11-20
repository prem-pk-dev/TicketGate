# Cloudflare Workers deployment

TicketGate uses Next.js App Router with the OpenNext Cloudflare adapter. The Worker name is `ticketgate`.

## Automated deployment (GitHub Actions)

The workflow `.github/workflows/ci.yml`:
1. Installs dependencies and runs TypeScript, ESLint and the Next.js production build.
2. Builds the Cloudflare Worker with `npx opennextjs-cloudflare build`.
3. Bundles the exact Worker upload with `npx wrangler deploy --dry-run --outdir .worker-dist` (no deployment occurs in this step).
4. Deploys with `npx wrangler deploy` only when the GitHub Actions secret `CLOUDFLARE_API_TOKEN` exists. Without that secret, deployment is skipped while build verification continues.
5. Uploads the OpenNext and Wrangler build outputs as a short-lived CI artifact.

The account ID and public Supabase URL/publishable key are already configured. Never put the Supabase service-role key in a client variable or GitHub workflow.

## One-time authorization required

The connected Cloudflare session can inspect the account and directly upload Worker scripts, but it cannot create API tokens. GitHub Actions cannot reuse the ChatGPT OAuth session, so it needs a repository secret once:

1. In Cloudflare Dashboard, open **My Profile → API Tokens → Create Token**.
2. Create a custom token with the least-privilege **Workers Scripts Write** permission (the UI may label this Workers Scripts: Edit), scoped to this Cloudflare account. This permission covers the Worker script upload and its static-asset upload session; do not grant Workers Admin unless Cloudflare explicitly reports that a required operation needs it.
3. Do not add DNS, billing, Pages, KV or R2 permissions.
4. Copy the token once. Do not paste it into ChatGPT or commit it to the repository.
5. In GitHub, open [TicketGate repository Actions secrets](https://github.com/prem-pk-dev/TicketGate/settings/secrets/actions) → **New repository secret**:
   - Name: `CLOUDFLARE_API_TOKEN`
   - Secret: paste the token value.
6. The next push to `main` runs the deployment automatically. The workflow uses the existing account ID `a9b08391a849a2e0804f6c93bb65c251`.

Official references:
- [Cloudflare GitHub Actions deployment](https://developers.cloudflare.com/workers/ci-cd/external-cicd/github-actions/)
- [Cloudflare Workers roles and permissions](https://developers.cloudflare.com/workers/authorization/)

## Local commands

```bash
npm install
npm run dev
npm run preview
npm run deploy
```

## Cost controls

No paid add-ons or payment processor are configured. Dummy payment only simulates success/failure. Cloudflare Workers and Supabase remain subject to free-tier quotas; no paid plan should be enabled automatically.


## Re-running after adding the repository secret

After saving `CLOUDFLARE_API_TOKEN`, trigger a new push to `main` (a documentation-only commit is sufficient). Confirm the `Deploy to Cloudflare Workers` step runs rather than printing the skip message, then verify the `ticketgate` Worker in the Cloudflare dashboard. A green build alone does not prove deployment succeeded.
