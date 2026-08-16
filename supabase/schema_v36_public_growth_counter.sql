-- Comptador públic de creixement per a la landing page (instriq.org): nombre
-- d'equips/organitzacions reals creats a la plataforma. Exclou noms que
-- semblen proves internes (demo/test/qa/prova) perquè la xifra sigui honesta
-- -- amb només 2 files avui ("Hospital Demo" i "Equipo Angli"), comptar-les
-- totes inflaria una xifra que encara no representa creixement real.
create or replace function get_public_organization_count()
returns integer
language sql
security definer
set search_path = public
stable
as $$
  select count(*)::int
  from organizations
  where name !~* '(demo|test|qa|prova|prueba)';
$$;

revoke all on function get_public_organization_count() from public;
grant execute on function get_public_organization_count() to anon, authenticated;
