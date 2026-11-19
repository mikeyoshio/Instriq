-- schema_v72: nova especialitat del catàleg, Odontologia i Cirurgia Bucal
-- (Specialty.odontologia a lib/models/instrument.dart). Les peces dentals que
-- eren a 'maxilofacial' s'hi han mogut al catàleg compilat; aquí només cal
-- que la taula de referència tingui el slug, igual que schema_v38 amb
-- 'anestesiologiaReanimacio'.
insert into specialties (slug, label)
values ('odontologia', 'Odontología y Cirugía Bucal')
on conflict (slug) do nothing;
