# Instriq

🌐 **Català** · [Castellano](README.es.md) · [English](README.en.md)

Plataforma professional de coneixement col·laboratiu per al bloc quirúrgic (Flutter: Android, iOS, Web). Reuneix instrumental, tècniques, protocols i l'experiència real de l'equip en un sol lloc, i permet a qualsevol grup (un hospital, un bloc quirúrgic, un servei, un equip d'instrumentistes, un centre de formació...) documentar la seva pròpia manera de treballar — substituint les carpetes de paper desactualitzades per alguna cosa que es porta a la tauleta o al mòbil.

L'ús bàsic (catàleg, flashcards, quiz, progrés) **no requereix compte**. Només cal iniciar sessió si vols unir-te o crear l'espai compartit del teu grup.

## Captures

| Entrada al grup | Catàleg | Detall | Flashcards |
|---|---|---|---|
| ![Entrada al grup](docs/screenshots/welcome.png) | ![Catàleg](docs/screenshots/catalogo.png) | ![Detall](docs/screenshots/detalle_instrumento.png) | ![Flashcards](docs/screenshots/flashcards.png) |

## Funcionalitats

- **Catàleg**: 216 instruments organitzats per 17 especialitats/àrees (cirurgia general, laparoscòpia i energia avançada, cirurgia robòtica, traumatologia i ortopèdia, neurocirurgia, cardiovascular, ginecologia i obstetrícia, urologia, otorinolaringologia, angiologia i cirurgia vascular, cirurgia oral i maxil·lofacial, cirurgia pediàtrica, cirurgia plàstica/estètica i reparadora, cirurgia toràcica, dermatologia medicoquirúrgica i venereologia, oftalmologia, anestesiologia i reanimació) i per categoria funcional (tall, dissecció, sutura, separació, succió, equips i màquines, especials). Cada instrument té el nom i els àlies (noms comercials i fabricant, ex. "LigaSure" de Medtronic, "Harmonic" d'Ethicon) i, per a la resta de contingut (descripció, ús, consell clínic), tot completament traduït als 3 idiomes de l'app — no un simple text fix en un únic idioma.
- **Aprèn**: flashcards i quiz d'opció múltiple amb millor puntuació guardada.
- **Progrés**: seguiment local d'instruments apresos per categoria.
- **Assistent de creació d'espai de treball**: en donar d'alta un grup nou, un assistent guiat demana el tipus d'organització i l'especialitat principal, i ofereix adoptar d'entrada un paquet inicial de safates recomanades ja publicades a la Biblioteca Pública — en comptes de començar de zero.
- **Organització, no només hospital**: el grup pot ser un hospital, una clínica, una universitat, un centre de simulació, un fabricant o un equip privat (`org_type`), cadascun organitzat en diversos **espais de treball** (per especialitat, servei, formació...); tècniques, protocols i targetes de preferència pengen d'un espai, no només de l'organització sencera.
- **Model de dades relacional**: fabricant, cirurgià, especialitat i etiquetes són entitats pròpies amb les seves pròpies taules i FK, no text lliure — "no desar text quan pot existir una relació". Menys duplicació, cerques i filtres més fiables.
- **Tècniques quirúrgiques i protocols**: contingut propi de l'espai, amb **versionat i flux d'aprovació** — cada edició crea un esborrany; qui aprova el revisa, el compara camp a camp amb la versió publicada i l'aprova o el rebutja. Res se sobreescriu: hi ha historial complet i restauració a versions anteriors. Especialitat estandarditzada segons el catàleg oficial d'especialitats quirúrgiques (Real Decret 183/2008). Els passos d'un protocol es poden agrupar en **categories opcionals** (estil checklist de seguretat quirúrgica de l'OMS: Preoperatori, Anestèsia, Equipament, Instrumental, Seguretat, o una categoria pròpia).
- **Targetes de preferència**: instrumental específic per cirurgià i procediment, compartit entre el personal del mateix espai via Supabase, amb marca de "validat pel cirurgià" i el **mateix versionat i flux d'aprovació** (esborrany → revisió → publicada → arxivada) que tècniques/protocols/safates.
- **Rols granulars per espai, individuals o per equip**: Owner i Administrator a nivell d'organització; Approver, Editor i Reader assignats per espai a una persona o a un **equip sencer** d'un cop (`teams`/`team_members`) — el rol efectiu és el màxim entre el directe i l'heretat de l'equip.
- **Alta de grup per autoservei**: qualsevol persona (cap de quiròfan o qui vulgui) pot registrar la seva organització. La persona que la crea és Owner i Administrator — pot regenerar el codi d'invitació, gestionar membres, equips, rols per espai i transferir la propietat.
- **Auditoria**: registre de qui va fer què i quan sobre accions sensibles (aprovar/rebutjar, crear/esborrar documents, canvis de rol, transferència de propietat, inici de sessió), visible per a admin/owner.
- **Cobertura de coneixement i analítica d'ús**: dashboard agregat de quantes tècniques/protocols hi ha documentats per especialitat (publicats vs. en revisió) i totals d'espais/membres, més **analítica d'ús real** (instrumental i contingut més consultat, cerques més freqüents, cerques sense resultat) — agregada per organització i visible només per a admin, sense dades individuals per persona.
- **RGPD**: exportar les pròpies dades (perfil, contingut creat/aprovat, rols) com a JSON, i eliminar el compte — el contingut que s'hagi creat o aprovat es conserva anonimitzat per a l'equip ("Usuari eliminat"), no es perd el coneixement compartit.
- **Avís d'actualització** (Android/iOS): comprova si hi ha una versió més recent publicada i ho notifica sense bloquejar l'ús.
- **Multiidioma**: català per defecte, castellà i anglès seleccionables des d'una icona al mateix Inici, amb l'elecció desada al dispositiu. La landing pública segueix el mateix criteri.
- **Instrumental personalitzat de l'equip**: cada espai de treball pot donar d'alta el seu propi instrumental (amb variants i foto), privat a aquell hospital/espai — mai es barreja amb el catàleg global ni és visible fora del teu equip. Cada foto pujada per un equip porta un avís explícit de que no està verificada per Instriq (a diferència de les del catàleg global, amb llicència lliure comprovada).
- **Mode sense connexió**: tècniques, protocols i targetes de preferència es cauen localment i es poden consultar sense xarxa; crear o editar contingut sense connexió es posa a la cua i es sincronitza només en recuperar-la.
- **Notificacions push**: avís quan un contingut entra en revisió, s'aprova o es rebutja (Firebase Cloud Messaging), sense dependre d'obrir l'app per assabentar-se'n.
- **Mode de Treball**: cada persona activa un únic mode (instrumentista, supervisió de quiròfan, esterilització/CSSD, infermeria quirúrgica, cirurgià/ana, estudiant, docent), canviable a l'instant des de la capçalera. No és un sistema de permisos — només reordena quina informació de cada instrument es mostra primer segons aquest mode, sense amagar mai la resta de la fitxa.
- **Esterilització estructurada**: cada instrument pot portar un o diversos mètodes d'esterilització (vapor, plasma de peròxid, òxid d'etilè, baixa temperatura, d'un sol ús, no esterilitzable) amb els seus propis paràmetres (temperatura, temps, pressió, cicle recomanat, compatibilitat, restriccions), més una fitxa tècnica (fabricant, IFU, manteniment, inspecció, vida útil) — no és text lliure, és una dada consultable.
- **Safates d'instrumental**: sets d'instrumental (caixes/safates) amb checklist d'instruments, quantitat esperada i posició física de cadascun, fotos, versionat i flux d'aprovació igual que tècniques/protocols, duplicar una safata com a base d'una altra, i **sessions reals de preparació**: cada muntatge físic després de rentat/esterilització queda registrat ítem a ítem, amb control de qualitat/validació d'una altra persona (o la mateixa) sobre aquesta sessió concreta.
- **Biblioteca Pública amb traduccions comunitàries**: tècniques/protocols, safates i instrumental publicats a nivell públic (no lligats a cap organització), amb el mateix flux esborrany → revisió → publicació. Qualsevol contribuïdor pot proposar una traducció d'un contingut ja publicat a un altre idioma (ca/es/en): es clona com un esborrany independent en el nou idioma, que passa pel mateix flux de revisió — mai traducció automàtica, sempre revisat per una persona. **Les meves aportacions**: pantalla dedicada perquè un contribuïdor trobi i reprengui els seus propis esborranys de contingut públic, encara no publicats.
- **Disseny propi i navegació responsive**: sistema de disseny unificat (tipografia, color, espaiats) amb una única experiència de navegació — barra lateral en escriptori, navegació inferior en mòbil — igual a totes les pantalles; el contingut es centra amb una amplada màxima en pantalles grans, en comptes d'estirar-se de vora a vora.
- **Inici centrat en la cerca**: la pantalla d'inici s'obre amb un cercador global (instrumental, tècniques, protocols, targetes, safates), activitat recent i preferits, en comptes d'un dashboard estàtic.
- **Mode clar/fosc** amb interruptor manual persistent.

## Stack tècnic

- **Flutter** (Dart) — Android, iOS i Web des del mateix codi.
- **Supabase** — Auth (email/contrasenya), Postgres amb Row Level Security, Storage (fotos d'instrumental personalitzat), Edge Functions, API REST autogenerada.
- **Firebase Cloud Messaging** — enviament de notificacions push (disparades per un Database Webhook sobre el log d'auditoria).
- **Resend** — email transaccional de Supabase Auth (confirmació de compte, recuperar contrasenya) des de `hola@instriq.org`.
- **connectivity_plus + shared_preferences** — detecció de connexió i caché/cua de sincronització per al mode sense connexió (sense base de dades local nova).
- **shared_preferences** per a progrés i preferència de tema local (funciona sense compte).

## Estructura del projecte

```
lib/
  l10n/         # ARB (català/castellà/anglès) + AppLocalizations generat (flutter gen-l10n)
  models/       # Instrument, PreferenceCard(Version), GroupDocument(Version, ProtocolStep), Workspace(Role/Member),
                # Organization (= grup, amb org_type), AuditEntry, HospitalContentStats, CustomInstrument(Variant),
                # WorkMode, SterilizationMethodEntry/InstrumentTechnicalInfo, Tray(Version, Item),
                # Manufacturer, Surgeon, SpecialtyEntity, Tag, ReferenceDocument, Team, UsageStats
  data/         # Catàleg d'instrumental (118) i especialitats quirúrgiques estàndard
  design_system/ # Tokens (color, tipografia, espaiat) i components compartits del sistema visual
  navigation/   # Shell responsive (StatefulShellRoute): barra lateral en escriptori, navegació inferior en mòbil
  services/     # Supabase, auth, perfil/organització, espais, progrés, tema, idioma, compte (RGPD),
                # versió de l'app, auditoria, analítica d'ús, instrumental personalitzat,
                # connectivitat, caché/cua de sincronització sense connexió, notificacions push,
                # esterilització, safates, equips (teams), targetes de preferència (versionat)
  screens/
    auth/       # Entrada única (unir-se/crear grup amb compte en el mateix formulari), login, flux de connexió
    admin/      # Gestió de l'organització (codi, membres, equips, propietat)
    ...         # Inici (cerca global), Catàleg, Aprèn, progrés, espais, tècniques/protocols,
                # targetes de preferència (versionat), compte i privacitat, auditoria, cobertura de
                # coneixement i analítica d'ús, instrumental personalitzat de l'equip, safates,
                # Biblioteca Pública (contingut i traduccions), les meves aportacions
  utils/        # Generador de codi d'invitació
supabase/
  schema_v*.sql    # Esquema SQL (executa en ordre: schema.sql → schema_v29_public_library.sql → ...)
  functions/       # Edge Functions (send-push: envia notificacions via FCM a partir del log d'auditoria)
```

## Desenvolupament

```bash
flutter pub get
flutter run                 # dispositiu/emulador Android o iOS connectat
flutter run -d chrome        # navegador
```

### Backend (Supabase)

1. Crea un projecte a [supabase.com](https://supabase.com).
2. Al SQL Editor, executa en ordre tots els `supabase/schema_v*.sql` (i `schema.sql` primer):
   `schema.sql` → `schema_v2_hospital_admin.sql` → `schema_v3_fix_rls_recursion.sql` → `schema_v4_group_documents.sql` → `schema_v5_group_document_versions.sql` → `schema_v6_workspaces.sql` → `schema_v7_roles.sql` → `schema_v8_app_config.sql` → `schema_v9_gdpr.sql` → `schema_v10_audit.sql` → `schema_v11_analytics.sql` → `schema_v12_push_notifications.sql` → `schema_v13_custom_instruments.sql` → `schema_v14_security_hardening.sql` → `schema_v15_clinical_knowledge_model.sql` → `schema_v16_community_photos.sql` → `schema_v17_fix_anon_sterilization_read.sql` → `schema_v18_work_mode_favorites_recent.sql` → `schema_v19_core_domain_model.sql` → `schema_v20_organizations_rename.sql` → `schema_v21_teams_and_login_audit.sql` → `schema_v22_preference_card_versioning.sql` → `schema_v23_usage_analytics.sql` → `schema_v24_knowledge_links.sql` → `schema_v25_tray_preparation.sql` → `schema_v26_learning_progress.sql` → `schema_v27_contributors.sql` → `schema_v28_preference_card_constraints_fix.sql` → `schema_v29_public_library.sql` → `schema_v30_hospital_admin_promotion.sql` → `schema_v31_profile_security_hardening.sql` → `schema_v32_cssd_workspace.sql` → `schema_v33_public_knowledge_links_and_profile.sql` → `schema_v34_rpc_grants_hardening.sql` → `schema_v35_rpc_grants_hardening_fix.sql` → `schema_v36_public_growth_counter.sql` → `schema_v37_fix_stale_updated_at_triggers.sql` → `schema_v38_epic2_expansion.sql` → `schema_v39_custom_instrument_versioning.sql` → `schema_v40_duplicate_content.sql` → `schema_v41_invitations.sql` → `schema_v42_tray_adoption.sql` → `schema_v43_security_hardening.sql` → `schema_v44_storage_path_validation.sql` → `schema_v45_catalog_content_reports.sql` → `schema_v46_feature_suggestions.sql` → `schema_v47_authz_null_bypass_fix.sql` → `schema_v48_public_instruments.sql` → `schema_v49_workspace_wizard.sql` → `schema_v50_public_translations.sql`.
3. Copia la URL i la **publishable key** (Project Settings → API) a `lib/services/supabase_config.dart`. És pública/segura de fer commit — la seguretat real la dona Row Level Security, no el secret d'aquesta key.
4. Per a les notificacions push: desplega `supabase/functions/send-push` (`supabase functions deploy send-push`), afegeix el secret `FCM_SERVICE_ACCOUNT_JSON` (JSON del service account de Firebase) a Edge Functions → Secrets, i confirma que existeixi un Database Webhook o trigger que cridi aquesta funció en cada `insert` sobre `audit_log` (`schema_v12` ja deixa el trigger llest si el teu projecte té `pg_net`).
5. Per a les invitacions per email: desplega `supabase/functions/send-invitation-email` (`supabase functions deploy send-invitation-email`), afegeix el secret `RESEND_API_KEY` (diferent del SMTP que ja fa servir Supabase Auth per als seus propis correus), i configura al dashboard (Database → Webhooks) un webhook sobre `insert` a `invitations` que apunti a aquesta funció.
6. Tots dos webhooks anteriors s'han d'autenticar davant la seva funció amb un secret compartit, perquè ningú amb la publishable key pública els pugui invocar directament (veure `schema_v43_security_hardening.sql`): genera un valor aleatori, desa'l com a secret `WEBHOOK_SHARED_SECRET` a Edge Functions → Secrets (per a totes dues funcions), desa'l també a Supabase Vault amb el nom `webhook_shared_secret` (`select vault.create_secret('<valor>', 'webhook_shared_secret', '...')`, `trigger_send_push()` ja el llegeix d'allà), i afegeix la capçalera `X-Webhook-Secret: <mateix valor>` al webhook d'`invitations` que vas configurar al pas anterior.
7. Per a l'instrumental personalitzat: confirma que el bucket privat `custom-instrument-photos` existeix a Storage (la migració `schema_v13` el crea; en alguns projectes cal crear-lo a mà des del dashboard amb el mateix nom).
8. Executa `flutterfire configure` (requereix un projecte Firebase) per generar `lib/firebase_options.dart` i el `google-services.json`/`GoogleService-Info.plist` de cada plataforma — cap dels tres es fa commit (veure `.gitignore`): són claus de client Firebase, no secretes en si mateixes, però cadascú les genera contra el seu propi projecte en comptes de compartir-ne un de comú. La protecció real d'aquestes claus és restringir-les a Google Cloud Console (paquet Android + SHA-1, bundle iOS, referrer HTTP a Web), no mantenir-les fora del repositori.

## Desplegament

- **App** (`app.instriq.org`): Vercel. El repositori inclou `vercel.json` + `vercel_build.sh` — com que Vercel no porta Flutter preinstal·lat, l'script clona l'SDK stable a cada build, genera les localitzacions (`flutter gen-l10n`) i compila amb `flutter build web --release`. N'hi ha prou amb importar el repositori a Vercel (framework preset "Other") i connectar el subdomini des de Cloudflare amb un CNAME a `cname.vercel-dns.com`. `lib/firebase_options.dart` no es fa commit (veure `.gitignore` — claus de client Firebase, segures d'exposar només si estan restringides a Google Cloud Console, però cada entorn genera les seves en comptes de compartir un fitxer comú); `vercel_build.sh` el regenera en build time a partir d'aquestes variables d'entorn de Vercel (Project Settings → Environment Variables), amb els valors de l'app **Web** a Firebase Console → Project Settings → General:
  - `FIREBASE_WEB_API_KEY`, `FIREBASE_WEB_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_AUTH_DOMAIN`, `FIREBASE_STORAGE_BUCKET`, `FIREBASE_MEASUREMENT_ID`.
- **Landing** (`instriq.org` i `www.instriq.org`): carpeta `landing/`, HTML estàtic sense build, servit per un Cloudflare Worker (Route `instriq.org/*` i `www.instriq.org/*`, tots dos registres DNS proxied). Català per defecte, amb selector ES/EN persistit a `localStorage` **i** a la URL (`?lang=es`/`?lang=en`) — cada variant té el seu propi `hreflang`/canonical, perquè els cercadors puguin indexar les tres versions, no només la catalana. Capçaleres de seguretat (`landing/_headers`: CSP, X-Frame-Options, HSTS...). Inclou la política de privacitat (`landing/privacidad.html`).
- **Android (Google Play)**: `targetSdk`/`compileSdk` 36 (Android 16), requisit de Google Play des de 2026-08-31 — Flutter 3.44.8, AGP 9.0.1, Kotlin 2.3.20, Gradle 9.1.0, JDK 17. AAB signat generat (`android/app/instriq-release.jks`, `android/key.properties` no versionat); falta només la pujada manual a Play Console.

## Llicències

- **Codi**: [AGPL-3.0](LICENSE).
- **Documentació**: CC BY-SA 4.0.
- **Fotos d'instrumental**: Wikimedia Commons amb llicència lliure verificada (CC0/CC-BY/CC-BY-SA); l'atribució de cadascuna es mostra a la mateixa app, al costat de la imatge.

## Estat / roadmap

**v1.0.0** (2026-09-30). El projecte continua en desenvolupament actiu. Tot el que hi ha a la secció "Funcionalitats" de dalt ja està desplegat i funcionant en producció.

- **Historial complet de tot el que s'ha lliurat** (ordre cronològic, amb el context/bug/decisió de cada entrada): **[docs/CHANGELOG.md](docs/CHANGELOG.md)**.
- **Pendent** (EPICs de producte, deute tècnic i revisió arquitectònica prèvia a cadascun): **[docs/BACKLOG.md](docs/BACKLOG.md)**.

## Patrocina

Instriq és gratuït i sense inversors, mantingut fora d'hores. Si et resulta útil, pots patrocinar el projecte a [GitHub Sponsors](https://github.com/sponsors/mikeyoshio) — qualsevol aportació ajuda a cobrir el cost del servidor i el temps dedicat.

## Contacte

[hola@instriq.org](mailto:hola@instriq.org)
