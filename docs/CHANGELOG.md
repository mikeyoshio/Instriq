# Historial de canvis

Registre cronològic de tot el que s'ha lliurat a Instriq. Per al que queda pendent (EPICs de producte i deute tècnic), veure **[BACKLOG.md](BACKLOG.md)**.

## 1.0.0 — 2026-09-30

- Fotos reals d'instrumental amb llicència lliure (parcial, la resta segueix amb icona per categoria)
- Landing informativa + política de privacitat a `instriq.org` i `www.instriq.org`
- Organització → Espais de treball
- Tècniques quirúrgiques i protocols, amb versionat i flux d'aprovació, i passos categoritzables tipus OMS
- Rols granulars per espai (Owner, Administrator, Approver, Editor, Reader)
- Exportar/eliminar compte (RGPD)
- Avís d'actualització de l'app
- Interfície en català (per defecte), castellà i anglès — app i landing
- Auditoria d'accions sensibles (aprovar/rebutjar, rols, propietat, crear/esborrar documents)
- Cobertura de coneixement documentat per especialitat (publicat vs. en revisió)
- Instrumental personalitzat de l'equip, amb fotos i variants, privat per espai
- Mode sense connexió amb cua de sincronització
- Notificacions push (Firebase Cloud Messaging)
- Mode de Treball (instrumentista, supervisió, esterilització, infermeria, cirurgià, estudiant, docent) — mode únic i actiu, reordena la fitxa d'instrument sense amagar res
- Esterilització estructurada per instrument (mètode, paràmetres, fitxa tècnica/IFU/fabricant)
- Safates d'instrumental: checklist, fotos, versionat i aprovació
- Disseny propi i navegació responsive (sidebar escriptori / bottom-nav mòbil, un únic sistema visual)
- Inici centrat en cerca global, amb activitat recent i preferits
- Model de dades relacional: fabricant, cirurgià, especialitat i etiquetes com a entitats, no text lliure
- Organització generalitzada (hospital, clínica, universitat, centre de simulació, fabricant, equip privat)
- Rols assignats a equips sencers, a més de a persones individuals
- Auditoria d'inici de sessió (a més d'accions sensibles)
- Analítica d'ús real per organització (instrumental/contingut més vist, cerques, cerques sense resultat)
- Versionat i flux d'aprovació a targetes de preferència (abans s'editaven directament)
- Actualització de toolchain per al requisit de Google Play de `targetSdk` 36/Android 16 (Flutter, AGP, Kotlin, Gradle, JDK 17)
- Design System propi consolidat: components genèrics (historial/diff de versió, cua de revisió, llistat d'entitat-retroenllaç, formulari/detall de Biblioteca Pública) substituint patrons triplicats; selector d'espai de treball que es salta el pas quan només n'hi ha un; embut d'autenticació unificat en una sola pantalla (unir-se/crear grup amb compte al mateix formulari, sense pantalla d'èxit dedicada)
- Auditoria de seguretat completa (RLS, funcions `security definer`, coherència client-servidor) amb les troballes crítiques corregides: sense auto-promoció a admin, `organizations` ja no és llegible per qualsevol, expulsar/promoure un membre passa per funció verificada al servidor
- Segona ronda d'auditoria de seguretat (2026-09) sobre les migracions més recents (`schema_v43_security_hardening.sql`): `organizations.owner_id` ja no es pot modificar directament (mateix guard de columna que `profiles`, només `transfer_hospital_ownership()` el pot canviar); `group_document_videos` ja no exposa vídeos pendents/rebutjats a qualsevol membre de l'espai; les Edge Functions `send-push`/`send-invitation-email` exigeixen un secret compartit (`WEBHOOK_SHARED_SECRET`, desat també a Supabase Vault) per no poder-se invocar directament amb la publishable key pública — abans permetia enviar correus/notificacions arbitraris suplantant Instriq
- SEO de la landing: `hreflang` real per a les 3 variants d'idioma (abans només la catalana era indexable), metadades Open Graph/Twitter traduïbles, schema `Organization`, capçaleres de seguretat
- Tercera ronda d'auditoria de seguretat (2026-09, `docs/SECURITY_AUDIT_2026-09.md`): corregit un fallo crític en ~34 funcions `security definer` on el guard `rol not in (llista)` no rebutjava qui no tenia cap rol (NULL tractat com a fals en PL/pgSQL) — qualsevol compte acabat de registrar podia escriure en organitzacions alienes; tancat també el mateix forat d'`EXECUTE` a `anon` (ja corregit una vegada per a una altra funció) en 17 funcions addicionals
- Cerca tolerant a errates a tot el catàleg i els llistats (`lib/utils/fuzzy_match.dart`, distància de Levenshtein acotada + normalització d'accents) — abans exigia coincidència exacta de subcadena
- Avís de contingut desactualitzat (més de 12 mesos sense revisar) en tècniques/protocols, safates i targetes de preferència publicades
- Exportar/imprimir en PDF el checklist d'una safata, els passos d'una tècnica/protocol o una targeta de preferència (`lib/services/pdf_export.dart`, paquets `pdf`/`printing`)
- Instrumental a la Biblioteca Pública: tercer tipus de contingut comunitari (junt amb tècniques/protocols i safates), amb foto pujada per qui col·labora (amb avís de no verificada, a diferència de les del catàleg global) — visible també des del cercador global d'Inici
- "Les meves aportacions": pantalla perquè un contribuïdor trobi i reprengui els seus propis esborranys de contingut públic encara no publicats, des de qualsevol dels 3 tipus (tècniques/protocols, safates, instrumental)
- Assistent de creació d'espai de treball: elecció del tipus d'organització i l'especialitat principal en donar d'alta un grup, amb oferiment d'adoptar un paquet inicial de safates recomanades ja publicades a la Biblioteca Pública
- Traduccions comunitàries de la Biblioteca Pública: cada idioma (ca/es/en) d'un contingut públic és una fila independent enllaçada per un `translation_group_id` compartit; proposar una traducció clona el contingut publicat en un esborrany nou en l'idioma triat, que passa pel mateix flux de revisió — mai traducció automàtica
- Catàleg 100% traduït als 3 idiomes: el nom de cada instrument (abans fix en castellà, amb 8 excepcions ja en català per inconsistència) passa a ser traduït com la resta de camps; els àlies (noms comercials/sinònims) es normalitzen a l'anglès quan són un terme descriptiu genèric, mantenint intactes els noms de marca/fabricant/epònim (que ja eren invariants per naturalesa)
- Auditoria SEO de la landing i correcció de metadades incompletes (Open Graph/Twitter, sitemap) a les pàgines secundàries
- Auditoria de rendiment: debounce de la cerca en viu d'Inici (abans recalculava tot el catàleg i el contingut d'espai a cada tecla), peticions de xarxa independents llançades en paral·lel en comptes de seqüencials a 6 pantalles, `ManufacturerService` usant per fi la seva pròpia caché, fotos amb `cached_network_image` (abans es tornaven a descarregar a cada arrencada en fred) i arrencada de l'app no bloquejant a l'espera del perfil
- Quarta ronda d'auditoria (7 dimensions) de cara a la v1.0: seguretat neta (l'única troballa candidata era el model wiki-style intencionat de la Biblioteca Pública, no un forat real); corregit que esborrar el compte fallava per a qualsevol equip privat amb safates/instrumental/esterilització propis (faltava `ON DELETE CASCADE`); corregida una trampa d'accessibilitat real al mode quiròfan (la sortida per lector de pantalla mai es completava); sutures i el dashboard de cobertura de coneixement completament traduïts (mateix bug que el catàleg d'instrumental); ample màxim en escriptori aplicat a les 4 pestanyes principals i 11 pantalles més que faltaven; cobertura de tests de 11 a 29, incloent un bug real trobat de pas (`PreferenceCardVersion.copyWith` no reiniciava "validat pel cirurgià" en editar l'instrumental d'una versió ja validada)
- Catàleg d'instrumental ampliat de 118 a 216 entrades: investigat i redactat per especialitat amb cerca web real (mai inventat), verificat de forma escèptica i independent abans d'afegir-se — 56 propostes descartades per no superar la verificació. Revisió addicional de traducció ca/es/en sobre les 98 noves (8 revisors, un per especialitat): 38 problemes reals corregits (errors d'arrel catalana com "craneal"→"cranial", mots castellans colats al català, confusions clíniques com llitera/taula d'operacions, un fals amic, restes d'anglès sense traduir)
- Mode sense connexió ampliat a la Biblioteca Pública (abans no en tenia cap: tècniques/protocols/safates/instrumental públics fallaven directament sense xarxa, a diferència del contingut propi d'organització que ja requeia a `OfflineCacheService` des de l'EPIC 7) i nova funcionalitat "Descarrega per a ús sense connexió" a Perfil: precarrega deliberadament el catàleg sencer (fotos incloses), tota la Biblioteca Pública i, si hi ha sessió iniciada, el contingut de cada espai de treball propi — en comptes de dependre només de la caché passiva (el que ja s'havia vist en línia)
