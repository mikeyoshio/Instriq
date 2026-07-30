-- Fase C de la evolucion de Instriq: modelo de dominio nucleo. Hasta ahora
-- "fabricante", "especialidad", "cirujano/a" y "documento de referencia (IFU)"
-- eran texto libre repetido en varias tablas (instrument_technical_info.
-- manufacturer, preference_cards.surgeon_name, group_document_versions.
-- specialty / custom_instruments.specialty / tray_versions.specialty,
-- instrument_technical_info.ifu_url). Esta ronda les da tabla propia con FK
-- real, sin todavia romper nada que ya funcione con el texto libre (ver nota
-- de "conservador" en la seccion 8c). Ejecutar despues de
-- schema_v18_work_mode_favorites_recent.sql.
--
-- 1-4: catalogos nuevos (manufacturers, specialties, surgeons, tags), cada
-- uno con su propio nivel de acceso:
--   - manufacturers/tags: dato global compartido entre todos los hospitales
--     (un fabricante o una etiqueta no es propiedad de nadie), cualquier
--     usuaria/o autenticada puede darlo de alta, nadie lo borra todavia
--     (fusionar duplicados es trabajo futuro, fuera de esta fase).
--   - specialties: lista CERRADA (las 16 especialidades de
--     lib/models/instrument.dart, Specialty enum), sembrada solo por esta
--     migracion. Sin policy de insert: no tiene sentido que el cliente cree
--     especialidades nuevas, la lista la controla el codigo Dart.
--   - surgeons: privado por hospital, igual que preference_cards siempre ha
--     sido (mismo idiom de RLS que schema.sql).
--
-- 5-6: taggings/reference_documents son polimorficos (apuntan a "cualquier
-- cosa" via ref_type/ref_id), calcado del patron ya usado en schema_v15/v16/
-- v18 para instrument_ref_type/ref_type. hospital_id nullable en ambas: null
-- significa "el objeto etiquetado/el documento es global" (p.ej. etiquetar un
-- instrumento del catalogo, o el IFU publico de un fabricante), no null
-- significa "el objeto etiquetado es privado de un hospital" (p.ej. una
-- bandeja, un documento de grupo, un cirujano) y debe coincidir con el
-- hospital_id de quien lo crea.
--
-- 7: se amplia el conjunto de valores permitido en los check constraint de
-- ref_type/instrument_ref_type ya existentes para que las tres tablas
-- polimorficas de esta migracion (taggings, y en el futuro cualquier otra)
-- puedan referenciar tambien 'surgeon', 'manufacturer' y 'specialty' ademas
-- de lo que ya soportaban. Ampliar un check constraint es siempre seguro
-- (nunca invalida una fila que ya cumplia el constraint anterior, mas
-- restrictivo).
--
-- 8: migracion de columnas de texto libre a FK, con backfill defensivo para
-- el poco dato que ya pueda existir (ver notas especificas en cada bloque).

-- 1. Fabricantes ---------------------------------------------------------------

create table if not exists manufacturers (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  website text,
  created_at timestamptz not null default now()
);

alter table manufacturers enable row level security;

drop policy if exists "manufacturers_select" on manufacturers;
create policy "manufacturers_select" on manufacturers
  for select using (true); -- dato global de catalogo, igual que el catalogo Dart

drop policy if exists "manufacturers_insert" on manufacturers;
create policy "manufacturers_insert" on manufacturers
  for insert with check (auth.role() = 'authenticated');

-- Sin policy de update/delete: fusionar duplicados (p.ej. "Stryker" vs
-- "Stryker Corp.") es trabajo futuro, no de esta fase.

-- 2. Especialidades (lista cerrada, sembrada por esta migracion) ---------------

create table if not exists specialties (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  label text not null,
  created_at timestamptz not null default now()
);

alter table specialties enable row level security;

drop policy if exists "specialties_select" on specialties;
create policy "specialties_select" on specialties
  for select using (true);

-- Sin policy de insert: es una lista cerrada (Specialty enum de
-- lib/models/instrument.dart), la siembra el propio script de migracion como
-- owner de la tabla (salta RLS), no el cliente.

-- slug = Specialty.name, label = Specialty.label, copiados literales de
-- lib/models/instrument.dart (16 valores, sin traducir a ca/en, igual que el
-- enum Dart de origen).
insert into specialties (slug, label) values
  ('general', 'Cirugía general'),
  ('laparoscopiaEnergia', 'Laparoscopia y energía avanzada'),
  ('roboticaAsistida', 'Cirugía robótica'),
  ('ortopediaTrauma', 'Traumatología y ortopedia'),
  ('neurocirugia', 'Neurocirugía'),
  ('cardiovascular', 'Cardiovascular'),
  ('ginecologiaObstetricia', 'Ginecología y obstetricia'),
  ('urologia', 'Urología'),
  ('otorrino', 'Otorrinolaringología'),
  ('vascular', 'Angiología y Cirugía Vascular'),
  ('maxilofacial', 'Cirugía Oral y Maxilofacial'),
  ('pediatrica', 'Cirugía Pediátrica'),
  ('plastica', 'Cirugía Plástica, Estética y Reparadora'),
  ('toracica', 'Cirugía Torácica'),
  ('dermatologia', 'Dermatología Médico-Quirúrgica y Venereología'),
  ('oftalmologia', 'Oftalmología')
on conflict (slug) do nothing;

-- 3. Cirujanos/as (privado por hospital, mismo idiom que schema.sql) -----------

create table if not exists surgeons (
  id uuid primary key default gen_random_uuid(),
  hospital_id uuid not null references hospitals(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  unique (hospital_id, name)
);

create index if not exists surgeons_hospital_idx on surgeons (hospital_id);

alter table surgeons enable row level security;

-- Idiom identico al de "cards_select_same_hospital"/"cards_insert_same_hospital"
-- en schema.sql (subquery directo a profiles, no my_hospital_id()): sigue
-- exactamente lo que ya se usaba para preference_cards antes de schema_v3.
drop policy if exists "surgeons_select" on surgeons;
create policy "surgeons_select" on surgeons
  for select using (
    hospital_id = (select hospital_id from profiles where id = auth.uid())
  );

drop policy if exists "surgeons_insert" on surgeons;
create policy "surgeons_insert" on surgeons
  for insert with check (
    hospital_id = (select hospital_id from profiles where id = auth.uid())
  );

-- Sin policy de update/delete esta fase: fusionar/renombrar cirujanos
-- duplicados es trabajo futuro.

-- 4. Etiquetas (globales, compartidas entre hospitales) ------------------------

create table if not exists tags (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

alter table tags enable row level security;

drop policy if exists "tags_select" on tags;
create policy "tags_select" on tags
  for select using (true);

drop policy if exists "tags_insert" on tags;
create policy "tags_insert" on tags
  for insert with check (auth.role() = 'authenticated');

-- Sin policy de update/delete: fusionar duplicados es trabajo futuro.

-- 5. Etiquetado polimorfico (tags -> cualquier entidad) -------------------------
-- Mismo patron ref_type/ref_id que favorites/recent_views (schema_v18), pero
-- con un conjunto de valores mas amplio porque aqui tambien se etiquetan
-- entidades que no tiene sentido "favoritear" (un fabricante, una
-- especialidad, un cirujano/a).

create table if not exists taggings (
  id uuid primary key default gen_random_uuid(),
  tag_id uuid not null references tags(id) on delete cascade,
  ref_type text not null check (ref_type in (
    'catalog', 'custom', 'group_document', 'tray', 'preference_card',
    'surgeon', 'manufacturer', 'specialty'
  )),
  ref_id text not null,
  -- NULL = lo etiquetado es global/publico (p.ej. un instrumento del
  -- catalogo o un fabricante); NOT NULL = lo etiquetado es privado de un
  -- hospital (p.ej. una bandeja, un documento de grupo, un cirujano) y debe
  -- coincidir con el hospital_id de quien crea la etiqueta.
  hospital_id uuid references hospitals(id) on delete cascade,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique (tag_id, ref_type, ref_id)
);

create index if not exists taggings_ref_idx on taggings (ref_type, ref_id);
create index if not exists taggings_hospital_idx on taggings (hospital_id);

alter table taggings enable row level security;

-- Select: mismo idiom de dos ramas (global vs. propio hospital) que ya
-- corrigio schema_v17 para instrument_sterilization_methods/
-- instrument_technical_info.
drop policy if exists "taggings_select" on taggings;
create policy "taggings_select" on taggings
  for select using (
    hospital_id is null
    or hospital_id = (select hospital_id from profiles where id = auth.uid())
  );

drop policy if exists "taggings_insert" on taggings;
create policy "taggings_insert" on taggings
  for insert with check (
    created_by = auth.uid()
    and (
      hospital_id is null
      or hospital_id = (select hospital_id from profiles where id = auth.uid())
    )
  );

drop policy if exists "taggings_delete" on taggings;
create policy "taggings_delete" on taggings
  for delete using (created_by = auth.uid());

-- Sin policy de update: quitar y volver a poner una etiqueta es mas simple
-- que editarla (no hay campos editables aparte de la propia relacion).

-- 6. Documentos de referencia (biblioteca de IFU/guias/manuales) ---------------
-- Un IFU suele cubrir varios modelos de instrumento de un mismo fabricante,
-- asi que merece tabla propia en vez de una columna URL suelta (que es lo
-- que hacia instrument_technical_info.ifu_url hasta ahora, ver seccion 8a).

create table if not exists reference_documents (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  url text not null,
  doc_type text not null default 'other' check (doc_type in ('ifu', 'guide', 'manual', 'other')),
  -- NULL = documento global (p.ej. el IFU publico de un fabricante),
  -- NOT NULL = documento privado de un hospital.
  hospital_id uuid references hospitals(id) on delete cascade,
  manufacturer_id uuid references manufacturers(id) on delete set null,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create index if not exists reference_documents_hospital_idx on reference_documents (hospital_id);
create index if not exists reference_documents_manufacturer_idx on reference_documents (manufacturer_id);

alter table reference_documents enable row level security;

-- Select: mismo idiom de dos ramas que taggings de arriba.
drop policy if exists "reference_documents_select" on reference_documents;
create policy "reference_documents_select" on reference_documents
  for select using (
    hospital_id is null
    or hospital_id = (select hospital_id from profiles where id = auth.uid())
  );

-- Insert: documento global (hospital_id is null) solo lo puede dar de alta
-- un admin -- mismo idiom "hospital_id is null and my_is_hospital_admin()"
-- que ya usan instrument_sterilization_methods_insert/
-- instrument_technical_info_insert en schema_v15 para el dato de catalogo
-- global. Documento privado de hospital: cualquier miembro de ese hospital
-- (mismo subquery que surgeons_insert de arriba).
drop policy if exists "reference_documents_insert" on reference_documents;
create policy "reference_documents_insert" on reference_documents
  for insert with check (
    (hospital_id is null and my_is_hospital_admin())
    or (
      hospital_id is not null
      and hospital_id = (select hospital_id from profiles where id = auth.uid())
    )
  );

-- Sin policy de update/delete esta fase.

-- 7. Ampliar el conjunto de ref_type/instrument_ref_type permitido -------------
-- Los tres check constraint de abajo se crearon como constraint de columna
-- inline (sin nombre explicito), asi que Postgres les puso el nombre por
-- defecto "<tabla>_<columna>_check". Se asume ese nombre por defecto aqui
-- (no se ha podido confirmar contra la base de datos real -- ver nota al
-- final del mensaje de la tarea: verificar con
-- "select conname from pg_constraint where conrelid = '<tabla>'::regclass"
-- antes de aplicar). "drop constraint if exists" hace que, si el nombre
-- adivinado no es el real, esta migracion no falle -- solo haria falta
-- repetir el "add constraint" a mano con el nombre correcto.
alter table instrument_sterilization_methods
  drop constraint if exists instrument_sterilization_methods_instrument_ref_type_check;
alter table instrument_sterilization_methods
  add constraint instrument_sterilization_methods_instrument_ref_type_check
  check (instrument_ref_type in (
    'catalog', 'custom', 'group_document', 'tray', 'preference_card',
    'surgeon', 'manufacturer', 'specialty'
  ));

alter table instrument_technical_info
  drop constraint if exists instrument_technical_info_instrument_ref_type_check;
alter table instrument_technical_info
  add constraint instrument_technical_info_instrument_ref_type_check
  check (instrument_ref_type in (
    'catalog', 'custom', 'group_document', 'tray', 'preference_card',
    'surgeon', 'manufacturer', 'specialty'
  ));

alter table catalog_community_photos
  drop constraint if exists catalog_community_photos_instrument_ref_type_check;
alter table catalog_community_photos
  add constraint catalog_community_photos_instrument_ref_type_check
  check (instrument_ref_type in (
    'catalog', 'custom', 'group_document', 'tray', 'preference_card',
    'surgeon', 'manufacturer', 'specialty'
  ));

-- 8. Migrar columnas de texto libre a FK, con backfill defensivo ---------------

-- 8a. instrument_technical_info.manufacturer (text) -> manufacturer_id (FK).
-- La tabla deberia tener 0 filas hoy (Fase E aun sin datos reales cargados),
-- pero el backfill de abajo se escribe igualmente por si ya hay alguna fila
-- para cuando esto se aplique -- asi es seguro en ambos escenarios.
alter table instrument_technical_info add column if not exists manufacturer_id uuid references manufacturers(id);
alter table instrument_technical_info add column if not exists ifu_document_id uuid references reference_documents(id);

insert into manufacturers (name)
select distinct manufacturer from instrument_technical_info where manufacturer is not null
on conflict (name) do nothing;

update instrument_technical_info
set manufacturer_id = m.id
from manufacturers m
where m.name = instrument_technical_info.manufacturer;

-- ifu_url (text) no tiene un backfill automatico razonable a
-- ifu_document_id: convertir una URL suelta en una fila de
-- reference_documents exigiria inventar un titulo que no existe hoy en
-- ningun sitio. Si al aplicar esto ya hay filas con ifu_url relleno, revisar
-- a mano antes de continuar (crear la fila de reference_documents
-- correspondiente y enlazarla via ifu_document_id) porque el texto de la URL
-- se pierde en el drop column de abajo.
alter table instrument_technical_info drop column if exists manufacturer;
alter table instrument_technical_info drop column if exists ifu_url;

-- 8b. preference_cards.surgeon_name (text) -> surgeon_id (FK a surgeons).
alter table preference_cards add column if not exists surgeon_id uuid references surgeons(id);

insert into surgeons (hospital_id, name)
select distinct hospital_id, surgeon_name from preference_cards where surgeon_name is not null
on conflict (hospital_id, name) do nothing;

update preference_cards pc
set surgeon_id = s.id
from surgeons s
where s.hospital_id = pc.hospital_id and s.name = pc.surgeon_name;

-- NOTA: se borra surgeon_name porque el nombre ya queda representado via
-- surgeon_id -> surgeons.name. surgeon_id se deja NULLABLE a proposito (no
-- "not null"): si el backfill de arriba dejase alguna fila sin match
-- (surgeon_name con espacios/variantes que no coincidieran exactamente al
-- insertar en surgeons), es preferible una tarjeta con surgeon_id null que
-- una migracion que falla a mitad de camino por un "not null" imposible de
-- cumplir.
alter table preference_cards drop column if exists surgeon_name;

-- 8c. group_document_versions.specialty / custom_instruments.specialty /
--     tray_versions.specialty (text libre) -> specialty_id (FK a
--     specialties). Backfill por coincidencia de texto (case/espacios
--     aparte) contra el label de la taxonomia cerrada de 16 valores.
alter table group_document_versions add column if not exists specialty_id uuid references specialties(id);
update group_document_versions gdv
set specialty_id = sp.id
from specialties sp
where lower(trim(gdv.specialty)) = lower(sp.label);

alter table custom_instruments add column if not exists specialty_id uuid references specialties(id);
update custom_instruments ci
set specialty_id = sp.id
from specialties sp
where lower(trim(ci.specialty)) = lower(sp.label);

alter table tray_versions add column if not exists specialty_id uuid references specialties(id);
update tray_versions tv
set specialty_id = sp.id
from specialties sp
where lower(trim(tv.specialty)) = lower(sp.label);

-- NOTA (paso deliberadamente conservador/reversible de esta migracion): NO
-- se borra la columna text "specialty" de ninguna de las tres tablas de
-- arriba en esta misma migracion. El backfill solo enlaza filas cuyo texto
-- coincide (case/espacios aparte) con alguna de las 16 label exactas de la
-- taxonomia Specialty; cualquier fila con un valor libre que no case
-- (texto antiguo, especialidad no listada, erratas) se queda con
-- specialty_id = null pero con su texto original intacto en la columna
-- vieja -- nada se pierde en silencio. Antes de borrar "specialty" en una
-- migracion de seguimiento, comprobar a mano cuantas filas de cada tabla
-- quedaron con specialty_id is null y specialty is not null, y decidir caso
-- a caso si se mapean a mano o se descartan.
