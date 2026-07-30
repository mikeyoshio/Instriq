-- Seed de datos de catalogo global (hospital_id/workspace_id NULL) para
-- instrument_sterilization_methods (schema_v15_clinical_knowledge_model.sql),
-- decidido y encargado explicitamente por la jefa de quirofano + esterilizacion
-- tras advertirle del riesgo de rellenar datos clinicos de catalogo global.
--
-- CRITERIO (deliberadamente conservador, ver AGENTS.md/instrucciones de la
-- tarea): se rellena UNICAMENTE la categoria general de metodo de
-- esterilizacion (columna "method"). Ningun parametro clinico concreto se
-- inventa jamas: temperature, time_minutes, pressure, drying,
-- recommended_cycle, compatibility_notes y restrictions se dejan SIEMPRE
-- NULL (no se mencionan en el INSERT). Cada hospital podra anadir su propia
-- particularidad exacta (temperatura/tiempo/ciclo de su central de
-- esterilizacion) desde el formulario ya existente en la app.
--
-- Reglas aplicadas instrumento a instrumento:
--   1) Categoria corte/diseccion/sutura/separacion/succion, instrumental
--      metalico reutilizable clasico (pinzas, tijeras, portaagujas,
--      separadores manuales, canulas de aspiracion rigidas, etc.), sin
--      mencion explicita de "desechable"/"un solo uso"/"disposable" en su
--      nombre/descripcion/alias => method = 'vapor' (autoclave de vapor es
--      el estandar universal para instrumental metalico reutilizable).
--   2) Mencion explicita de un solo uso, o naturaleza de implante/cateter/
--      injerto de un solo paciente => method = 'desechable'.
--   3) El bisturi (mango reutilizable + hoja desechable) recibe DOS filas:
--      una 'vapor' para el mango y otra 'desechable' para la hoja.
--   4) Categoria 'equipos' (Dart) => se omite siempre: maquinas motorizadas/
--      electronicas no se esterilizan como unidad completa.
--   5) Ademas de la categoria 'equipos' literal del catalogo Dart, se
--      trataron con el MISMO criterio (omision total) otros instrumentos
--      cuya categoria Dart es distinta (corte/succion/especiales) pero que
--      en realidad son maquinas motorizadas, consolas electronicas, sistemas
--      de navegacion, laseres o plataformas roboticas completas (p. ej.
--      sierras oscilantes, craneotomos, microscopios, laseres, sistemas de
--      navegacion, consolas roboticas). Inventar un metodo de esterilizacion
--      para estos seria mas arriesgado que para cualquier otro caso: se
--      documentan en el informe de la tarea, no en este archivo.
--   6) Categoria 'especiales' evaluada caso por caso: instrumental metalico
--      simple reutilizable => 'vapor'; implantes/cateteres/injertos/bolsas de
--      un solo uso => 'desechable'; dispositivos de energia avanzada
--      (Harmonic, LigaSure, ThunderBeat, EnSeal) cuyo componente de mano es
--      de un solo uso segun practica y etiquetado FDA estandar (el generador
--      reutilizable no forma parte de este catalogo) => 'desechable'. Donde
--      no hubo confianza razonable (trocares de composicion mixta reutilizable/
--      desechable segun modelo, fijador externo con marco reutilizable +
--      clavos de un solo uso, endoscopios descritos como "rigido o flexible"
--      o "de un solo uso o reutilizable", grapadoras motorizadas de
--      generacion ambigua, instrumental robotico EndoWrist con protocolo de
--      reprocesado propio del fabricante) NO se inserto fila alguna: mejor
--      omitir que adivinar mal. Lista completa en el informe de la tarea.
--
-- Nada de esto sustituye el IFU del fabricante ni el protocolo local de la
-- central de esterilizacion: son datos de catalogo global, de partida,
-- pensados para ser refinados por cada hospital.

-- ---- CORTE ----

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'bisturi', null, null, 'vapor', 'Corresponde al mango reutilizable del bisturi. La hoja es un componente de un solo uso independiente: ver la otra fila de este mismo instrumento (method = ''desechable''). Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'bisturi', null, null, 'desechable', 'Corresponde a la hoja de bisturi, de un solo uso: no reesterilizar. El mango (reutilizable) se esteriliza aparte por vapor: ver la otra fila de este mismo instrumento. Verifica las instrucciones del fabricante.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'tijera-mayo', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'tijera-metzenbaum', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'tijera-iris', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

-- ---- DISECCION / PRENSION ----

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'pinza-diseccion-dientes', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'pinza-diseccion-sin-dientes', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'pinza-kocher', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'pinza-kelly', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'pinza-mosquito', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'pinza-allis', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'pinza-babcock', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'pinza-foerster', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'pinza-backhaus', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'pinza-rochester-pean', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

-- ---- SUJECION / SUTURA ----

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'portaagujas-mayo-hegar', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'portaagujas-webster', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'portaagujas-vascular', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'portaagujas-castroviejo', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

-- ---- SEPARACION / EXPOSICION ----

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'separador-farabeuf', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'separador-weitlaner', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'valva-doyen', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'separador-richardson', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

-- ---- SUCCION / ASPIRACION ----

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'canula-yankauer', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'canula-poole', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

-- ---- SONDAS / ESPECIALES (generales) ----

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'sonda-acanalada', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'legra', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'electrobisturi', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.'),
('catalog', 'pinza-disección-bipolar', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

-- Nota: 'trocar' (generico y su version pediatrica 'trocar-laparoscopico-pediatrico')
-- se omite deliberadamente: coexisten en el mercado y en los hospitales
-- versiones reutilizables metalicas y versiones desechables de un solo uso
-- sin que el catalogo global pueda decidir cual predomina. Ver informe.

-- ---- LAPAROSCOPIA Y ENERGIA AVANZADA ----
-- bisturi-armonico, ligasure, thunderbeat y enseal: el componente de mano
-- (shears/pinza selladora) es de un solo uso segun practica y etiquetado
-- estandar del fabricante; el generador reutilizable no esta representado
-- en el catalogo de instrumentos (no es un "instrumento" individual).

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'bisturi-armonico', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.'),
('catalog', 'ligasure', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.'),
('catalog', 'thunderbeat', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.'),
('catalog', 'enseal', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

-- Nota: 'grapadora-signia' y 'grapadora-circular-motorizada' se omiten:
-- segun modelo/generacion el mango puede ser reutilizable multi-disparo o
-- de un solo uso: no se puede decidir con confianza a nivel de catalogo
-- global. Ver informe.

-- ---- CIRUGIA ROBOTICA ----
-- davinci-sistema, hugo-ras y versius son plataformas/consolas roboticas
-- completas: mismo criterio que 'equipos', se omiten. pinza-cadiere,
-- pinza-prograsp y vessel-sealer-robotico son instrumental EndoWrist con
-- protocolo de reprocesado propio y limite de usos segun el fabricante:
-- no se puede decidir con confianza razonable a nivel de catalogo global.
-- Ver informe.

-- ---- TRAUMATOLOGIA Y ORTOPEDIA ----
-- sierra-oscilante-ortopedica, driver-quirurgico y navegacion-ortopedica:
-- maquinas motorizadas/electronicas, mismo criterio que 'equipos', se
-- omiten. fijador-externo: sistema mixto marco reutilizable + clavos
-- percutaneos de un solo uso, no se decide con confianza. Ver informe.

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'clavo-intramedular', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.'),
('catalog', 'placa-fijacion', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

-- ---- NEUROCIRUGIA ----
-- aspirador-ultrasonico, craniotomo, neuronavegacion y microscopio-quirurgico:
-- maquinas motorizadas/electronicas o consolas, mismo criterio que
-- 'equipos', se omiten.

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'perforador-craneal', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.'),
('catalog', 'clip-aneurisma', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

-- ---- CARDIOVASCULAR ----
-- sierra-esternal: maquina motorizada, mismo criterio que 'equipos', se omite.

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'canula-aortica', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.'),
('catalog', 'clamp-aortico', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'pinza-debakey', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'anastomosis-distal', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.'),
('catalog', 'cierre-esternal', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

-- ---- GINECOLOGIA Y OBSTETRICIA ----
-- morcelador: instrumento motorizado electromecanico, mismo criterio que
-- 'equipos', se omite. histeroscopio: descrito como "rigido o flexible",
-- protocolo de reprocesado muy distinto segun el modelo, no se decide con
-- confianza. Ver informe.

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'bolsa-contencion-morcelacion', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.'),
('catalog', 'pinza-green-armytage', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

-- ---- UROLOGIA ----
-- resectoscopio-bipolar, laser-holmio y laser-tulio: consolas/sistemas
-- electronicos u opticos con vaina reutilizable + electrodo de un solo uso
-- (resectoscopio) o laseres, mismo criterio que 'equipos', se omiten.
-- ureteroscopio-flexible: su propia descripcion dice explicitamente "de un
-- solo uso o reutilizable" (coexisten ambas versiones), no se decide con
-- confianza. Ver informe.

-- (sin inserts en esta seccion)

-- ---- OTORRINOLARINGOLOGIA ----
-- microdebridador-ent, navegacion-ent, coblator y laser-co2-laringeo:
-- maquinas motorizadas/electronicas o consolas, mismo criterio que
-- 'equipos', se omiten.

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'dilatacion-sinusal-balon', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

-- ---- ANGIOLOGIA Y CIRUGIA VASCULAR ----
-- ecografo-doppler-intraoperatorio y sistema-trombectomia-mecanica: ya son
-- categoria 'equipos' en el catalogo Dart, se omiten.

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'pinza-satinsky', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'clamp-bulldog', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'cateter-fogarty', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.'),
('catalog', 'injerto-vascular-protesico', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

-- ---- CIRUGIA ORAL Y MAXILOFACIAL ----
-- motor-piezoelectrico-oral: ya es categoria 'equipos' en el catalogo Dart,
-- se omite.

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'forceps-extraccion-dental', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'elevador-periostotomo', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'placa-osteosintesis-maxilofacial', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.'),
('catalog', 'distractor-mandibular', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.'),
('catalog', 'fresa-quirurgica-dental', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

-- ---- CIRUGIA PEDIATRICA ----
-- sistema-ecmo-neonatal: ya es categoria 'equipos' en el catalogo Dart, se
-- omite. trocar-laparoscopico-pediatrico: mismo motivo que 'trocar' (mezcla
-- de versiones reutilizables y desechables segun modelo), se omite.

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'set-pediatrico-escala-reducida', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'tijera-potts-smith-pediatrica', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'separador-weitlaner-pediatrico', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'cateter-umbilical', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

-- ---- CIRUGIA PLASTICA, ESTETICA Y REPARADORA ----
-- dermatomo: ya es categoria 'equipos' en el catalogo Dart, se omite.

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'gancho-piel-doble-punta', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'separador-senn-miller', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'canula-liposuccion', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'expansor-tisular', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

-- ---- CIRUGIA TORACICA ----
-- sistema-vats: ya es categoria 'equipos' en el catalogo Dart, se omite.

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'separador-finochietto', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'grapadora-toracica-motorizada', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.'),
('catalog', 'drenaje-toracico-sello-agua', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.'),
('catalog', 'pinza-duval', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

-- ---- DERMATOLOGIA MEDICO-QUIRURGICA Y VENEREOLOGIA ----
-- criosonda-crioterapia, dermatoscopio-digital y laser-dermatologico: ya son
-- categoria 'equipos' en el catalogo Dart, se omiten.

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'punch-biopsia-cutanea', null, null, 'desechable', 'Componente o version de un solo uso — no reesterilizar. Verifica las instrucciones del fabricante.'),
('catalog', 'cureta-dermatologica', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;

-- ---- OFTALMOLOGIA ----
-- facoemulsificador y vitrectomo: ya son categoria 'equipos' en el catalogo
-- Dart, se omiten.

insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, hospital_id, workspace_id, method, observations) values
('catalog', 'especulo-palpebral', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'pinza-capsulorrexis', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.'),
('catalog', 'portaagujas-barraquer', null, null, 'vapor', 'Metodo general para instrumental metalico reutilizable estandar. Verifica siempre las instrucciones de uso (IFU) del fabricante y el protocolo de tu central de esterilizacion para parametros exactos y posibles excepciones.')
on conflict (instrument_ref_type, instrument_ref_id, method) where workspace_id is null do nothing;
