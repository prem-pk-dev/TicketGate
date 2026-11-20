
create or replace function public.current_user_role()
returns public.app_role
language sql stable security definer set search_path = ''
as $$ select role from public.profiles where id = auth.uid() $$;
drop policy if exists "profiles read self or admin" on public.profiles;
drop policy if exists "profiles update self" on public.profiles;
create policy "profiles read self or admin" on public.profiles for select to authenticated
using (id=auth.uid() or public.current_user_role()='ADMIN');
create policy "profiles update own non-role fields" on public.profiles for update to authenticated
using (id=auth.uid()) with check (id=auth.uid() and role=public.current_user_role());
grant execute on function public.current_user_role() to authenticated;
