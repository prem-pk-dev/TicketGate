# Cloudflare Workers deployment

TicketGate uses Next.js App Router with the OpenNext Cloudflare adapter. The repository is configured to deploy the Worker named `ticketgate`.

## Automated deployment (GitHub Actions)

The workflow `.github/workflows/ci.yml` now:
1. Installs dependencies and runs TypeScript, ESLint and the Next.js production build.
2. Builds the Cloudflare Worker with `npx opennextjs-cloudflare build`.
3. Deploys with `npx wrangler deploy` when the GitHub Actions secret `CLOUDFLARE_API_TOKEN` exists. Without that secret it skips only the deploy step; build verification still runs.
4. Uploads the OpenNext output as a short-lived CI artifact for diagnosis.

The account ID is already configured in the workflow. Public Supabase URL and publishable key are configured in `wrangler.jsonc` and the CI build environment. Never put the Supabase service-role key in a client variable or GitHub workflow.

## One-time authorization required

The connected Cloudflare OAuth session can inspect the account and free build-minute allowance, but it cannot create API tokens (Cloudflare returns 403 because the OAuth grant lacks API Tokens Write). A repository secret is therefore needed once:

1. In Cloudflare Dashboard, open **My Profile → API Tokens → Create Token**.
2. Create a custom token with **Workers → Admin** at the account/product scope for the initial creation of the new Worker. After the first successful deployment, reduce the token to **Workers → Editor** scoped only to the `ticketgate` Worker; subsequent deployments need only Editor on that Worker.
3. Scope it to the TicketGate Cloudflare account only. Do not add DNS, billing, Pages, KV or R2 permissions unless Cloudflare explicitly requires them for a later feature.
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
