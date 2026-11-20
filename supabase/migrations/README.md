# Supabase migrations

The SQL files in this folder are the exact migration statements applied to the TicketGate Supabase project, in version order. The demo seed is included as a separate migration.

Link the existing project and verify migration state:

```bash
supabase login
supabase link --project-ref nokxeuxmhbbnllijnfht
supabase migration list
```

To apply any migrations added later:

```bash
supabase db push
```

Do not reset the production database to replay these migrations. Use a separate development project for destructive schema experiments.
