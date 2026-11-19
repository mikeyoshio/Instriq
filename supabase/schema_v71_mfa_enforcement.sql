-- schema_v71: la verificació en dos passos (MFA, TOTP) l'exigeix la base de
-- dades, no només l'app.
--
-- Sense això, l'MFA seria només una pantalla: amb la contrasenya robada
-- algú podria cridar l'API de Supabase directament (sessió aal1) i llegir o
-- escriure dades. Amb aquesta política, un compte que té un factor verificat
-- no veu ni toca cap fila fins que la sessió és aal2 (codi introduït).
-- Els comptes sense MFA no noten cap canvi.
--
-- Com funciona: una política RESTRICTIVE s'aplica a més (AND) de les
-- polítiques que ja té cada taula. No dona accés a ningú: només el treu
-- quan falta el codi.
--
-- Limitacions conegudes:
--  * Les funcions SECURITY DEFINER (RPC) se salten RLS i, per tant, aquesta
--    comprovació. Les RPC que retornen dades d'usuari es poden blindar
--    afegint-hi `if not public.mfa_satisfied() then raise exception ...`.
--  * Només cobreix les taules que existeixen ara. En crear-ne una de nova
--    amb RLS, torneu a executar el bloc 2 (és idempotent).
--
-- Recuperar un compte que ha perdut el mòbil (només des del SQL Editor):
--   delete from auth.mfa_factors
--   where user_id = (select id from auth.users where email = 'persona@exemple.com');
--
-- Desfer-ho tot:
--   do $$ declare t record; begin
--     for t in select tablename from pg_policies where schemaname = 'public' and policyname = 'mfa_required'
--     loop execute format('drop policy mfa_required on public.%I', t.tablename); end loop;
--   end $$;

-- 1) La sessió compleix: o ja és aal2, o l'usuari no té cap factor verificat.
create or replace function public.mfa_satisfied()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
      or not exists (
        select 1 from auth.mfa_factors f
        where f.user_id = auth.uid() and f.status = 'verified'
      );
$$;

revoke all on function public.mfa_satisfied() from public;
grant execute on function public.mfa_satisfied() to authenticated;

-- 2) Política restrictiva a totes les taules de public amb RLS activat.
--    `(select ...)` fa que s'avaluï un cop per consulta, no per fila.
do $$
declare
  t record;
begin
  for t in
    select c.relname
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind in ('r', 'p') and c.relrowsecurity
  loop
    execute format('drop policy if exists mfa_required on public.%I', t.relname);
    execute format(
      'create policy mfa_required on public.%I as restrictive for all to authenticated '
      'using ((select public.mfa_satisfied())) with check ((select public.mfa_satisfied()))',
      t.relname);
  end loop;
end $$;

-- 3) Comprovació: quantes taules tenen la política.
select count(*) as taules_protegides
from pg_policies
where schemaname = 'public' and policyname = 'mfa_required';
