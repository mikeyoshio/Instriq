-- schema_v70: corregeix l'hora de les franjes de quiròfan creades abans del
-- 2026-11-18.
--
-- Bug (client, ja corregit a SurgicalSlotService): l'app enviava la data
-- d'inici/fi com a hora local SENSE zona horària ("2026-11-18T18:45:00.000").
-- Postgres la interpretava com a UTC, de manera que una franja de les 18:45
-- (Barcelona) quedava desada com 18:45 UTC = 19:45 a l'hivern (20:45 a l'estiu).
-- L'app, el panell i el feed .ics mostraven aquesta hora desplaçada.
--
-- Correcció: reinterpretar l'hora "de rellotge" desada com a hora de
-- Europe/Madrid. Funciona igual a l'hivern (CET) i a l'estiu (CEST).
-- Limitació coneguda: suposa que qui va crear la franja era a la península
-- (Europe/Madrid); una franja creada des de Canàries quedaria 1 h desplaçada.
--
-- Només toca franges creades abans del desplegament de la correcció. Si
-- després d'aquesta data algú crea una franja des d'una versió antiga de
-- l'app (p. ex. Microsoft Store 1.2.0), aquella franja no es corregeix aquí.

-- 1) Previsualització: executa només aquest SELECT primer i comprova que
--    "hora_corregida" és la que esperaves.
select id, procedure_name,
       starts_at as hora_actual,
       (starts_at at time zone 'UTC') at time zone 'Europe/Madrid' as hora_corregida,
       created_at
from surgical_slots
where created_at < timestamptz '2026-11-18 11:00:00+00'
order by starts_at;

-- 2) Correcció.
begin;
update surgical_slots
set starts_at = (starts_at at time zone 'UTC') at time zone 'Europe/Madrid',
    ends_at   = (ends_at   at time zone 'UTC') at time zone 'Europe/Madrid'
where created_at < timestamptz '2026-11-18 11:00:00+00';
commit;
