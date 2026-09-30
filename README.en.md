# Instriq

🌐 [Català](README.md) · [Castellano](README.es.md) · **English**

Professional platform for collaborative knowledge in the operating room (Flutter: Android, iOS, Web). It brings together instruments, techniques, protocols and the team's real-world experience in one place, and lets any group (a hospital, an operating room, a department, a scrub team, a training center...) document its own way of working — replacing outdated paper binders with something you can carry on a tablet or phone.

Basic use (catalog, flashcards, quiz, progress) **does not require an account**. You only need to sign in if you want to join or create your group's shared workspace.

## Screenshots

| Group entry | Catalog | Detail | Flashcards |
|---|---|---|---|
| ![Group entry](docs/screenshots/welcome.png) | ![Catalog](docs/screenshots/catalogo.png) | ![Detail](docs/screenshots/detalle_instrumento.png) | ![Flashcards](docs/screenshots/flashcards.png) |

## Features

- **Catalog**: 118 instruments organized into 17 specialties/areas (General surgery, Laparoscopy and advanced energy, Robotic surgery, Trauma and orthopedics, Neurosurgery, Cardiovascular, Gynecology and obstetrics, Urology, Otolaryngology, Vascular surgery, Oral and maxillofacial surgery, Pediatric surgery, Plastic, aesthetic and reconstructive surgery, Thoracic surgery, Medical-surgical dermatology and venereology, Ophthalmology, Anesthesiology and resuscitation) and by functional category (cutting, dissection, suturing, retraction, suction, equipment and machines, special). Each instrument has a name and aliases (trade names and manufacturer, e.g. "LigaSure" by Medtronic, "Harmonic" by Ethicon) and, for the rest of the content (description, use, clinical tip), everything is fully translated into the app's 3 languages — not just fixed text in a single language.
- **Learn**: flashcards and multiple-choice quiz with best score saved.
- **Progress**: local tracking of instruments learned, by category.
- **Workspace creation wizard**: when registering a new group, a guided wizard asks for the organization type and main specialty, and offers to adopt an initial package of recommended trays already published in the Public Library — instead of starting from scratch.
- **Organization, not just hospital**: the group can be a hospital, a clinic, a university, a simulation center, a manufacturer or a private team (`org_type`), each organized into several **workspaces** (by specialty, department, training...); techniques, protocols and preference cards belong to a workspace, not just to the organization as a whole.
- **Relational data model**: manufacturer, surgeon, specialty and tags are proper entities with their own tables and FKs, not free text — "don't store text when a relationship can exist instead". Less duplication, more reliable search and filtering.
- **Surgical techniques and protocols**: content that belongs to the workspace, with **versioning and an approval workflow** — every edit creates a draft; the approver reviews it, compares it field by field against the published version, and approves or rejects it. Nothing is ever overwritten: there's a full history and the ability to restore earlier versions. Specialty standardized according to the official catalog of surgical specialties (Royal Decree 183/2008). A protocol's steps can be grouped into **optional categories** (in the style of the WHO surgical safety checklist: Preoperative, Anesthesia, Equipment, Instruments, Safety, or a custom category).
- **Preference cards**: instruments specific to a surgeon and procedure, shared among staff in the same workspace via Supabase, with a "validated by surgeon" flag and the **same versioning and approval workflow** (draft → review → published → archived) as techniques/protocols/trays.
- **Granular per-workspace roles, individual or by team**: Owner and Administrator at the organization level; Approver, Editor and Reader assigned per workspace to a person or to an **entire team** at once (`teams`/`team_members`) — the effective role is the highest of the direct one and the one inherited from the team.
- **Self-service group registration**: anyone (an OR manager or anyone else) can register their organization. The person who creates it becomes Owner and Administrator — they can regenerate the invitation code, manage members, teams, per-workspace roles, and transfer ownership.
- **Audit log**: record of who did what and when for sensitive actions (approve/reject, create/delete documents, role changes, ownership transfer, sign-in), visible to admins/owners.
- **Knowledge coverage and usage analytics**: an aggregate dashboard of how many techniques/protocols are documented per specialty (published vs. under review) and totals of workspaces/members, plus **real usage analytics** (most-viewed instruments and content, most frequent searches, searches with no results) — aggregated per organization and visible only to admins, with no per-person individual data.
- **GDPR**: export your own data (profile, content created/approved, roles) as JSON, and delete your account — content you created or approved is kept anonymized for the team ("Deleted user"), so shared knowledge is never lost.
- **Update notice** (Android/iOS): checks whether a newer version has been published and notifies you without blocking use.
- **Multilingual**: Catalan by default, with Spanish and English selectable from an icon right on the Home screen, and the choice saved on the device. The public landing page follows the same approach.
- **Team's custom instruments**: each workspace can register its own instruments (with variants and a photo), private to that hospital/workspace — never mixed into the global catalog and never visible outside your team. Every photo uploaded by a team carries an explicit notice that it is not verified by Instriq (unlike the ones in the global catalog, which have a checked free license).
- **Offline mode**: techniques, protocols and preference cards are cached locally and can be viewed without a network connection; creating or editing content while offline is queued and synced only once connectivity is restored.
- **Push notifications**: alerts when content enters review, is approved or is rejected (Firebase Cloud Messaging), without needing to open the app to find out.
- **Work Mode**: each person activates a single mode (instrumentist, OR supervision, sterilization/CSSD, surgical nursing, surgeon, student, teacher), switchable instantly from the header. It is not a permissions system — it only reorders which information for each instrument is shown first based on that mode, without ever hiding the rest of the record.
- **Structured sterilization**: each instrument can carry one or more sterilization methods (steam, hydrogen peroxide plasma, ethylene oxide, low temperature, single-use, non-sterilizable) with their own parameters (temperature, time, pressure, recommended cycle, compatibility, restrictions), plus a technical data sheet (manufacturer, IFU, maintenance, inspection, service life) — not free text, but queryable data.
- **Instrument trays**: instrument sets (boxes/trays) with a checklist of instruments, expected quantity and physical position of each one, photos, versioning and approval workflow the same as techniques/protocols, duplicating a tray as the basis for another one, and **real preparation sessions**: every physical set-up after washing/sterilization is logged item by item, with quality control/validation by another person (or the same one) for that specific session.
- **Public Library with community translations**: techniques/protocols, trays and instruments published at the public level (not tied to any organization), with the same draft → review → publication workflow. Any contributor can propose a translation of already-published content into another language (ca/es/en): it is cloned as an independent draft in the new language, which goes through the same review workflow — never machine translation, always reviewed by a person. **My contributions**: a dedicated screen for a contributor to find and resume their own drafts of public content that are not yet published.
- **Custom design and responsive navigation**: a unified design system (typography, color, spacing) with a single navigation experience — a sidebar on desktop, bottom navigation on mobile — the same across every screen; content is centered with a maximum width on large screens, instead of stretching edge to edge.
- **Search-centered Home**: the home screen opens with a global search bar (instruments, techniques, protocols, cards, trays), recent activity and favorites, instead of a static dashboard.
- **Light/dark mode** with a persistent manual toggle.

## Tech stack

- **Flutter** (Dart) — Android, iOS and Web from the same codebase.
- **Supabase** — Auth (email/password), Postgres with Row Level Security, Storage (custom instrument photos), Edge Functions, auto-generated REST API.
- **Firebase Cloud Messaging** — sends push notifications (triggered by a Database Webhook on the audit log).
- **Resend** — Supabase Auth's transactional email (account confirmation, password recovery) sent from `hola@instriq.org`.
- **connectivity_plus + shared_preferences** — connectivity detection and sync cache/queue for offline mode (no new local database).
- **shared_preferences** for progress and local theme preference (works without an account).

## Project structure

```
lib/
  l10n/         # ARB (Catalan/Spanish/English) + generated AppLocalizations (flutter gen-l10n)
  models/       # Instrument, PreferenceCard(Version), GroupDocument(Version, ProtocolStep), Workspace(Role/Member),
                # Organization (= group, with org_type), AuditEntry, HospitalContentStats, CustomInstrument(Variant),
                # WorkMode, SterilizationMethodEntry/InstrumentTechnicalInfo, Tray(Version, Item),
                # Manufacturer, Surgeon, SpecialtyEntity, Tag, ReferenceDocument, Team, UsageStats
  data/         # Instrument catalog (118) and standard surgical specialties
  design_system/ # Tokens (color, typography, spacing) and shared components of the visual system
  navigation/   # Responsive shell (StatefulShellRoute): sidebar on desktop, bottom navigation on mobile
  services/     # Supabase, auth, profile/organization, workspaces, progress, theme, language, account (GDPR),
                # app version, audit, usage analytics, custom instruments,
                # connectivity, offline sync cache/queue, push notifications,
                # sterilization, trays, teams, preference cards (versioning)
  screens/
    auth/       # Single entry point (join/create group with account in the same form), login, sign-in flow
    admin/      # Organization management (code, members, teams, ownership)
    ...         # Home (global search), Catalog, Learn, progress, workspaces, techniques/protocols,
                # preference cards (versioning), account and privacy, audit, knowledge coverage and
                # usage analytics, team's custom instruments, trays,
                # Public Library (content and translations), my contributions
  utils/        # Invitation code generator
supabase/
  schema_v*.sql    # SQL schema (run in order: schema.sql → schema_v29_public_library.sql → ...)
  functions/       # Edge Functions (send-push: sends notifications via FCM from the audit log)
```

## Development

```bash
flutter pub get
flutter run                 # connected Android/iOS device or emulator
flutter run -d chrome        # browser
```

### Backend (Supabase)

1. Create a project at [supabase.com](https://supabase.com).
2. In the SQL Editor, run all the `supabase/schema_v*.sql` files in order (with `schema.sql` first):
   `schema.sql` → `schema_v2_hospital_admin.sql` → `schema_v3_fix_rls_recursion.sql` → `schema_v4_group_documents.sql` → `schema_v5_group_document_versions.sql` → `schema_v6_workspaces.sql` → `schema_v7_roles.sql` → `schema_v8_app_config.sql` → `schema_v9_gdpr.sql` → `schema_v10_audit.sql` → `schema_v11_analytics.sql` → `schema_v12_push_notifications.sql` → `schema_v13_custom_instruments.sql` → `schema_v14_security_hardening.sql` → `schema_v15_clinical_knowledge_model.sql` → `schema_v16_community_photos.sql` → `schema_v17_fix_anon_sterilization_read.sql` → `schema_v18_work_mode_favorites_recent.sql` → `schema_v19_core_domain_model.sql` → `schema_v20_organizations_rename.sql` → `schema_v21_teams_and_login_audit.sql` → `schema_v22_preference_card_versioning.sql` → `schema_v23_usage_analytics.sql` → `schema_v24_knowledge_links.sql` → `schema_v25_tray_preparation.sql` → `schema_v26_learning_progress.sql` → `schema_v27_contributors.sql` → `schema_v28_preference_card_constraints_fix.sql` → `schema_v29_public_library.sql` → `schema_v30_hospital_admin_promotion.sql` → `schema_v31_profile_security_hardening.sql` → `schema_v32_cssd_workspace.sql` → `schema_v33_public_knowledge_links_and_profile.sql` → `schema_v34_rpc_grants_hardening.sql` → `schema_v35_rpc_grants_hardening_fix.sql` → `schema_v36_public_growth_counter.sql` → `schema_v37_fix_stale_updated_at_triggers.sql` → `schema_v38_epic2_expansion.sql` → `schema_v39_custom_instrument_versioning.sql` → `schema_v40_duplicate_content.sql` → `schema_v41_invitations.sql` → `schema_v42_tray_adoption.sql` → `schema_v43_security_hardening.sql` → `schema_v44_storage_path_validation.sql` → `schema_v45_catalog_content_reports.sql` → `schema_v46_feature_suggestions.sql` → `schema_v47_authz_null_bypass_fix.sql` → `schema_v48_public_instruments.sql` → `schema_v49_workspace_wizard.sql` → `schema_v50_public_translations.sql`.
3. Copy the URL and the **publishable key** (Project Settings → API) into `lib/services/supabase_config.dart`. It's public/safe to commit — the real security comes from Row Level Security, not from keeping this key secret.
4. For push notifications: deploy `supabase/functions/send-push` (`supabase functions deploy send-push`), add the `FCM_SERVICE_ACCOUNT_JSON` secret (Firebase service account JSON) under Edge Functions → Secrets, and confirm there's a Database Webhook or trigger that calls this function on every `insert` into `audit_log` (`schema_v12` already sets up the trigger for you if your project has `pg_net`).
5. For email invitations: deploy `supabase/functions/send-invitation-email` (`supabase functions deploy send-invitation-email`), add the `RESEND_API_KEY` secret (different from the SMTP that Supabase Auth already uses for its own emails), and set up a webhook in the dashboard (Database → Webhooks) on `insert` into `invitations` pointing to this function.
6. Both webhooks above must authenticate to their function with a shared secret, so that no one with the public publishable key can invoke them directly (see `schema_v43_security_hardening.sql`): generate a random value, save it as the `WEBHOOK_SHARED_SECRET` secret under Edge Functions → Secrets (for both functions), also save it in Supabase Vault under the name `webhook_shared_secret` (`select vault.create_secret('<value>', 'webhook_shared_secret', '...')`, `trigger_send_push()` already reads it from there), and add the `X-Webhook-Secret: <same value>` header to the `invitations` webhook you configured in the previous step.
7. For custom instruments: confirm that the private `custom-instrument-photos` bucket exists in Storage (the `schema_v13` migration creates it; on some projects you'll need to create it manually from the dashboard with the same name).
8. Run `flutterfire configure` (requires a Firebase project) to generate `lib/firebase_options.dart` and each platform's `google-services.json`/`GoogleService-Info.plist` — none of the three are committed (see `.gitignore`): they're Firebase client keys, not secret in themselves, but each person generates their own against their own project instead of sharing one in common. The real protection for these keys is restricting them in Google Cloud Console (Android package + SHA-1, iOS bundle, HTTP referrer for Web), not keeping them out of the repository.

## Deployment

- **App** (`app.instriq.org`): Vercel. The repository includes `vercel.json` + `vercel_build.sh` — since Vercel doesn't come with Flutter preinstalled, the script clones the stable SDK on every build, generates the localizations (`flutter gen-l10n`) and builds with `flutter build web --release`. It's enough to import the repository into Vercel (framework preset "Other") and point the subdomain from Cloudflare with a CNAME to `cname.vercel-dns.com`. `lib/firebase_options.dart` is not committed (see `.gitignore` — Firebase client keys, safe to expose only if they're restricted in Google Cloud Console, but each environment generates its own instead of sharing one common file); `vercel_build.sh` regenerates it at build time from these Vercel environment variables (Project Settings → Environment Variables), using the values from the **Web** app in Firebase Console → Project Settings → General:
  - `FIREBASE_WEB_API_KEY`, `FIREBASE_WEB_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_AUTH_DOMAIN`, `FIREBASE_STORAGE_BUCKET`, `FIREBASE_MEASUREMENT_ID`.
- **Landing** (`instriq.org` and `www.instriq.org`): `landing/` folder, static HTML with no build step, served by a Cloudflare Worker (Route `instriq.org/*` and `www.instriq.org/*`, both DNS records proxied). Catalan by default, with an ES/EN selector persisted to `localStorage` **and** in the URL (`?lang=es`/`?lang=en`) — each variant has its own `hreflang`/canonical, so search engines can index all three versions, not just the Catalan one. Security headers (`landing/_headers`: CSP, X-Frame-Options, HSTS...). Includes the privacy policy (`landing/privacidad.html`).
- **Android (Google Play)**: `targetSdk`/`compileSdk` 36 (Android 16), a Google Play requirement as of 2026-08-31 — Flutter 3.44.8, AGP 9.0.1, Kotlin 2.3.20, Gradle 9.1.0, JDK 17. Signed AAB already generated (`android/app/instriq-release.jks`, `android/key.properties` not versioned); only the manual upload to Play Console is left.

## Licenses

- **Code**: [AGPL-3.0](LICENSE).
- **Documentation**: CC BY-SA 4.0.
- **Instrument photos**: Wikimedia Commons under a verified free license (CC0/CC-BY/CC-BY-SA); each one's attribution is shown right in the app, next to the image.

## Status / roadmap

**v1.0.0** (2026-09-30). The project continues under active development. Everything in the "Features" section above is already deployed and running in production.

- **Full history of everything that's been shipped** (chronological order, with the context/bug/decision behind each entry): **[docs/CHANGELOG.md](docs/CHANGELOG.md)**.
- **Pending** (product EPICs, technical debt and the architectural review behind each one): **[docs/BACKLOG.md](docs/BACKLOG.md)**.

## Sponsor

Instriq is free and has no investors, maintained outside working hours. If you find it useful, you can sponsor the project on [GitHub Sponsors](https://github.com/sponsors/mikeyoshio) — any contribution helps cover the server costs and the time invested.

## Contact

[hola@instriq.org](mailto:hola@instriq.org)
