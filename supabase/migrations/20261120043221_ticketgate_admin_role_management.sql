
drop policy if exists "published events public read" on public.events;
create policy "published events public read" on public.events for select to anon,authenticated
using (status='PUBLISHED' or organizer_id=(select auth.uid()) or (select public.current_user_role())='ADMIN');

create or replace function private.set_user_role(p_user_id uuid,p_role public.app_role)
returns jsonb language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null or (select private.current_user_role())<>'ADMIN' then
   raise exception 'Administrator access required' using errcode='42501';
 end if;
 if p_role not in ('USER','ORGANIZER','ADMIN') then raise exception 'Invalid role' using errcode='22023'; end if;
 update public.profiles set role=p_role,updated_at=now() where id=p_user_id;
 if not found then raise exception 'User not found' using errcode='P0002'; end if;
 return jsonb_build_object('success',true,'user_id',p_user_id,'role',p_role);
end; $$;
grant execute on function private.set_user_role(uuid,public.app_role) to authenticated;
create or replace function public.set_user_role(p_user_id uuid,p_role public.app_role)
returns jsonb language sql security invoker set search_path=''
as $$ select private.set_user_role(p_user_id,p_role) $$;
revoke all on function public.set_user_role(uuid,public.app_role) from public,anon;
grant execute on function public.set_user_role(uuid,public.app_role) to authenticated;
