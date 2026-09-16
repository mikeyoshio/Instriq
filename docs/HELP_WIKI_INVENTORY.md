# Inventario de funcionalidades — wiki de ayuda

Índice de trabajo para construir el centro de ayuda (`lib/screens/help/`,
`lib/help/help_content.dart`) y la página web equivalente
(`landing/ayuda/`). Generado mediante una revisión sistemática de las ~73
pantallas de `lib/screens/` (septiembre 2026); úsalo como checklist al
añadir artículos nuevos, no como documentación de producto en sí.

Cada entrada: qué hace, en qué pantalla(s) vive, y quién puede acceder
(invitado / cuenta / cuenta+espacio con rol mínimo / admin de hospital /
colaborador aprobado). Roles de espacio: Reader < Editor < Approver <
Administrator (este último se deriva siempre de ser admin de hospital).
Niveles de colaborador: Contributor < Reviewer < Editorial Board.

## Estado

`[x]` ya tiene artículo real (con capturas) en `help_content.dart` /
`landing/ayuda/index.html`. `[ ]` pendiente.

## 1. Primeros pasos

- [x] Bienvenida de 3 pasos (`onboarding_screen.dart`) — invitado.
- [x] Elegir idioma (`widgets/language_picker.dart`) — invitado.
- [ ] Cambiar tema claro/oscuro (`profile_hub_screen.dart`) — invitado.
- [ ] Iniciar sesión con cuenta existente (`auth/sign_in_screen.dart`) — invitado.
- [ ] Recuperar contraseña (`auth/sign_in_screen.dart`, `auth/reset_password_screen.dart`) — invitado.
- [ ] Unirse a un hospital/grupo con código de invitación (`auth/group_entry_screen.dart`, `auth/hospital_connect_flow.dart`) — invitado.
- [ ] Crear un hospital/grupo nuevo (`auth/group_entry_screen.dart`) — invitado.
- [ ] Aceptar/declinar invitación por email (`auth/accept_invitation_screen.dart`) — invitado, ruta `/invite/:token`.
- [x] Cerrar sesión (`profile_hub_screen.dart`) — cuenta (artículo "Tu cuenta: preferencias, privacidad y sincronización", junto con los entry points de Mi cuenta/privacidad y Problemas de sincronización).

## 2. Catálogo y consulta de instrumental

- [x] Explorar y filtrar el catálogo global (`catalog_screen.dart`) — invitado.
- [x] Consultar la ficha de un instrumento (`instrument_detail_screen.dart`) — invitado.
- [ ] Búsqueda global unificada desde Inicio (`home_screen.dart`) — invitado/cuenta+espacio.
- [ ] Marcar/quitar favorito — cuenta.
- [ ] Subir foto de la comunidad — cuenta.
- [ ] Moderar fotos pendientes (`community_photos_review_screen.dart`) — admin hospital.
- [ ] Reportar/resolver incidencia — cuenta+hospital / admin·Approver.
- [ ] Ficha de fabricante (`manufacturer_detail_screen.dart`) — invitado.
- [ ] Ficha de especialidad (`specialty_detail_screen.dart`) — invitado/cuenta+espacio.
- [ ] Ficha de etiqueta (`tag_detail_screen.dart`) — invitado/cuenta.
- [ ] Ficha de cirujano (`surgeon_detail_screen.dart`) — cuenta+espacio.
- [x] Catálogo de suturas (`suture_catalog_screen.dart`, `suture_detail_screen.dart`) — invitado.

## 3. Bandejas (trays)

- [ ] Ver bandejas de un espacio (`trays_screen.dart`) — Reader+.
- [ ] Crear/editar borrador (`tray_form_screen.dart`) — Editor+.
- [ ] Ver ficha publicada (`tray_detail_screen.dart`) — Reader+.
- [ ] Historial de versiones / diff / restaurar (`tray_version_history_screen.dart`, `tray_diff_screen.dart`) — Reader+/Editor+.
- [ ] Duplicar — Editor+. Eliminar — Approver+.
- [ ] Registrar sesión de preparación (`tray_preparation_form_screen.dart`) — cuenta+espacio.
- [ ] Historial de preparaciones y QC (`tray_preparation_sessions_screen.dart`) — Reader+/Approver+.
- [ ] Actualizar desde origen público / dejar de seguir (`tray_detail_screen.dart`) — Editor+.

## 4. Tarjetas de preferencia

- [ ] Ver tarjetas agrupadas por cirujano (`preference_cards_screen.dart`) — Reader+.
- [ ] Crear/editar borrador (`preference_card_form_screen.dart`) — Editor+.
- [ ] Ver ficha publicada (`preference_card_detail_screen.dart`) — Reader+.
- [ ] Marcar/quitar validación del cirujano — Editor+.
- [ ] Historial de versiones / diff / restaurar — Reader+/Editor+.
- [ ] Duplicar — Editor+. Eliminar — Approver+.

## 5. Documentos de grupo (protocolos)

*Comparte pantallas con Técnicas (`kind = protocol`).*

- [ ] Ver protocolos (`group_document_list_screen.dart`) — Reader+.
- [ ] Crear/editar borrador (`group_document_form_screen.dart`) — Editor+.
- [ ] Escanear documento en papel (OCR) — Editor+.
- [ ] Ver ficha publicada (`group_document_detail_screen.dart`) — Reader+.
- [ ] Añadir/moderar vídeo educativo — cuenta+espacio / admin·Approver.
- [ ] Historial de versiones / diff / restaurar — Reader+/Editor+.
- [ ] Duplicar/Eliminar/Favorito — Editor+/Approver+/cuenta.

## 6. Técnicas quirúrgicas

*Mismas pantallas que Documentos de grupo, `kind = technique`.*

- [ ] Ver técnicas (`group_document_list_screen.dart`) — Reader+.
- [ ] Crear/editar borrador, incl. OCR (`group_document_form_screen.dart`) — Editor+.
- [ ] Ver ficha publicada, con relacionados y esterilización resumida — Reader+.
- [ ] Añadir/moderar vídeos, historial/diff/restaurar, duplicar/eliminar/favorito — igual que protocolos.

## 7. Instrumental personalizado del equipo

- [ ] Ver instrumental propio (`custom_instruments_screen.dart`) — Reader+.
- [ ] Crear/editar borrador, con variantes (`custom_instrument_form_screen.dart`) — Editor+.
- [ ] Ver ficha (`custom_instrument_detail_screen.dart`) — Reader+.
- [ ] Favorito/reportar/resolver incidencia — cuenta / cuenta+hospital / admin·Approver.
- [ ] Historial de versiones / diff / restaurar — Reader+/Approver+.
- [ ] Duplicar/Eliminar — Editor+/Approver+.

## 8. Esterilización

- [ ] Ver métodos y ficha técnica (en la ficha del instrumento) — invitado (catálogo) / Reader+ (propio).
- [ ] Editar esterilización/ficha técnica (`widgets/clinical_data_form_sheet.dart`) — admin hospital (catálogo) / Editor+ (propio).
- [ ] Historial/diff/restaurar — variable, ver detalle en la ficha completa del agente.
- [ ] Aprobar/rechazar cambios enviados a revisión — Editorial Board (catálogo) / admin·Approver (propio).

## 9. Biblioteca Pública y adopción de contenido

- [x] Qué es la Biblioteca Pública (`public_library_screen.dart`) — invitado.
- [ ] Ver ficha pública de técnica/protocolo o bandeja (`public_entity_detail_screen.dart`) — invitado.
- [ ] Proponer contenido público (`public_entity_form_screen.dart`) — Contributor aprobado.
- [ ] Adoptar una bandeja pública (`public_entity_detail_screen.dart` → `tray_form_screen.dart`) — cuenta+hospital.
- [ ] Ver perfil público de un colaborador (`contributor_public_profile_screen.dart`) — invitado.
- [ ] Revisar/aprobar propuestas públicas con comentarios editoriales (`public_library_review_queue_screen.dart`) — Editorial Board.

## 10. Organización y espacios de trabajo

- [x] Ver espacios (`workspace_list_screen.dart`) — cuenta+hospital.
- [ ] Crear/renombrar espacio — admin hospital.
- [x] Ver colecciones de un espacio (`workspace_detail_screen.dart`) — Reader+ (mismo artículo "Consultar los espacios de trabajo").
- [ ] Elegir modo de trabajo activo (`navigation/work_mode_header.dart`) — cuenta+hospital.

## 11. Roles y miembros del equipo

- [ ] Asignar rol a un miembro (`manage_workspace_members_screen.dart`) — admin hospital.
- [ ] Asignar rol a un equipo entero — admin hospital.
- [ ] Crear/eliminar equipos (`manage_teams_screen.dart`) — admin hospital.

## 12. Aprendizaje (flashcards/quiz/repaso)

- [x] Elegir modo de repaso (`learn_screen.dart`) — invitado.
- [x] Flashcards (`flashcards_screen.dart`) — invitado.
- [x] Quiz de opción múltiple (`quiz_screen.dart`) — invitado.
- [ ] Repaso contextual de un instrumento, Leitner (`review_session_screen.dart`) — invitado.
- [x] Ver mi progreso (`progress_screen.dart`) — invitado (local) / cuenta (sincronizado).

## 13. Colaboradores y revisión de contenido

- [ ] Solicitar ser colaborador (`contributor_application_form_screen.dart`) — cuenta.
- [ ] Revisar candidaturas (`contributor_review_queue_screen.dart`) — Editorial Board.
- [ ] Editar mi perfil público de colaborador (`contributor_profile_screen.dart`) — Contributor aprobado.
- [ ] Bandeja única de revisión (`review_inbox_screen.dart`) — variable.
- [ ] Revisar cambios de contenido de espacio, 6 pestañas (`group_document_review_queue_screen.dart`) — admin·Approver.
- [ ] Revisar cambios del catálogo global (`global_catalog_review_queue_screen.dart`) — Editorial Board.

## 14. Sincronización offline

- [ ] Consultar contenido sin conexión (banner en trays/preference_cards/group_document lists) — Reader+.
- [ ] Crear/editar/enviar a revisión sin conexión (4 formularios) — Editor+.
- [ ] Ver y descartar avisos de sincronización fallida (`sync_issues_screen.dart`) — cuenta.

## 15. Notificaciones y actividad

- [ ] Recibir notificaciones push — cuenta.
- [ ] Actividad reciente y favoritos en Inicio — cuenta.
- [ ] Pestaña Actividad (`activity_screen.dart`) — admin·Approver.
- [ ] Registro de auditoría (`audit_log_screen.dart`) — admin hospital.

## 16. Perfil y privacidad (GDPR)

- [ ] Exportar mis datos (`account_privacy_screen.dart`) — cuenta.
- [ ] Eliminar mi cuenta — cuenta.

## 17. Administración de hospital

- [ ] Gestionar código de invitación (`admin/manage_hospital_screen.dart`) — admin hospital.
- [ ] Invitar por email con rol/espacio asignados — admin hospital.
- [ ] Ver miembros, promover/expulsar, transferir propiedad — admin hospital / Owner.
- [ ] Panel de cobertura de conocimiento y uso (`knowledge_dashboard_screen.dart`) — admin hospital.

---

La mayoría de lo pendiente requiere una cuenta autenticada (y en varios
casos un hospital/espacio de trabajo con contenido real) para capturar
pantallas reales -- no se han simulado ni inventado capturas. Retomar en
cuanto haya una cuenta de prueba disponible.
