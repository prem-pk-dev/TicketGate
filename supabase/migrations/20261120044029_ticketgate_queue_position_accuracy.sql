
create or replace function private.join_show_queue(p_show_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_user uuid:=auth.uid();v_entry public.show_queue_entries%rowtype;v_position integer;v_admitted integer;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 perform pg_advisory_xact_lock(hashtext(p_show_id::text));
 if not exists(select 1 from public.shows sh join public.events e on e.id=sh.event_id where sh.id=p_show_id and sh.sales_open and e.status='PUBLISHED' and sh.starts_at>now()) then
  raise exception 'This show is not open for booking' using errcode='P0001';
 end if;
 insert into public.show_queue_entries(show_id,user_id,status,created_at,expires_at)
 values(p_show_id,v_user,'WAITING',now(),now()+interval '30 minutes')
 on conflict(show_id,user_id) do update set status=case when show_queue_entries.expires_at<=now() then 'WAITING' else show_queue_entries.status end,
 created_at=case when show_queue_entries.expires_at<=now() then now() else show_queue_entries.created_at end,
 expires_at=case when show_queue_entries.expires_at<=now() then now()+interval '30 minutes' else show_queue_entries.expires_at end;
 perform private.promote_show_queue(p_show_id);
 select * into v_entry from public.show_queue_entries where show_id=p_show_id and user_id=v_user;
 if v_entry.status='ADMITTED' then v_position:=0;
 else
  select count(*) into v_admitted from public.show_queue_entries where show_id=p_show_id and status='ADMITTED' and expires_at>now();
  select count(*)+v_admitted into v_position from public.show_queue_entries q where q.show_id=p_show_id and q.status='WAITING' and q.expires_at>now() and q.created_at<=v_entry.created_at;
 end if;
 return jsonb_build_object('status',v_entry.status,'position',v_position,'expires_at',v_entry.expires_at);
end; $$;

create or replace function private.get_show_queue_status(p_show_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_user uuid:=auth.uid();v_entry public.show_queue_entries%rowtype;v_position integer;v_admitted integer;
begin
 if v_user is null then raise exception 'Authentication required' using errcode='28000'; end if;
 perform pg_advisory_xact_lock(hashtext(p_show_id::text));
 perform private.promote_show_queue(p_show_id);
 select * into v_entry from public.show_queue_entries where show_id=p_show_id and user_id=v_user and expires_at>now();
 if not found then return jsonb_build_object('status','EXPIRED','position',null); end if;
 if v_entry.status='ADMITTED' then v_position:=0;
 else
  select count(*) into v_admitted from public.show_queue_entries where show_id=p_show_id and status='ADMITTED' and expires_at>now();
  select count(*)+v_admitted into v_position from public.show_queue_entries q where q.show_id=p_show_id and q.status='WAITING' and q.expires_at>now() and q.created_at<=v_entry.created_at;
 end if;
 return jsonb_build_object('status',v_entry.status,'position',v_position,'expires_at',v_entry.expires_at);
end; $$;
