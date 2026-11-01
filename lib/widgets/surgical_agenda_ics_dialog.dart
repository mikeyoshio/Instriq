/// Enlace de suscripción `.ics` a la agenda quirúrgica de un cirujano (ver
/// `lib/services/surgical_slot_service.dart` y
/// `supabase/schema_v64_surgical_agenda.sql`). Autocontenido: el cirujano se
/// elige dentro del propio diálogo vía `Autocomplete<Surgeon>` para poder
/// abrirse desde cualquier pantalla (p. ej. la AppBar de
/// `surgical_agenda_screen.dart`) sin depender de una selección previa.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/surgeon.dart';
import '../services/surgeon_service.dart';
import '../services/surgical_slot_service.dart';

Future<void> showSurgicalAgendaIcsDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    // Dato auxiliar para el Autocomplete -- mismo criterio que
    // preference_card_form_screen.dart: si falla por red, el diálogo sigue
    // siendo usable con lo que ya hubiera en caché (o vacío), no debe
    // impedir abrirlo.
    await SurgeonService.instance.fetchForOrganization();
  } catch (_) {}
  if (!context.mounted) return;

  String? surgeonId;
  String? token;
  var loadingToken = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        Future<void> loadToken(String id) async {
          setDialogState(() {
            loadingToken = true;
            token = null;
          });
          try {
            final fetched = await SurgicalSlotService.instance.getIcsToken(id);
            setDialogState(() {
              token = fetched;
              loadingToken = false;
            });
          } catch (e) {
            setDialogState(() => loadingToken = false);
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(l10n.genericError(e.toString()))));
            }
          }
        }

        Future<void> regenerate() async {
          final id = surgeonId;
          if (id == null) return;
          final confirmed = await showDialog<bool>(
            context: ctx,
            builder: (confirmCtx) => AlertDialog(
              content: Text(l10n.surgicalAgendaIcsRegenerateConfirm),
              actions: [
                TextButton(onPressed: () => Navigator.pop(confirmCtx, false), child: Text(l10n.cancel)),
                FilledButton(
                  onPressed: () => Navigator.pop(confirmCtx, true),
                  child: Text(l10n.surgicalAgendaIcsRegenerate),
                ),
              ],
            ),
          );
          if (confirmed != true) return;
          setDialogState(() => loadingToken = true);
          try {
            final fresh = await SurgicalSlotService.instance.regenerateIcsToken(id);
            setDialogState(() {
              token = fresh;
              loadingToken = false;
            });
          } catch (e) {
            setDialogState(() => loadingToken = false);
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(l10n.genericError(e.toString()))));
            }
          }
        }

        void copyToClipboard(String text) {
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(l10n.copiedToClipboard)));
        }

        final currentToken = token;
        return AlertDialog(
          title: Text(l10n.surgicalAgendaIcsDialogTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Autocomplete<Surgeon>(
                  optionsBuilder: (value) {
                    if (value.text.trim().isEmpty) return const Iterable<Surgeon>.empty();
                    return SurgeonService.instance.searchByName(value.text);
                  },
                  displayStringForOption: (s) => s.name,
                  onSelected: (s) {
                    surgeonId = s.id;
                    loadToken(s.id);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration:
                          InputDecoration(labelText: l10n.surgicalSlotSurgeonLabel, border: const OutlineInputBorder()),
                    );
                  },
                ),
                if (loadingToken) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (!loadingToken && currentToken != null) ...[
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.surgicalAgendaIcsCopyWebcal),
                    trailing: const Icon(Icons.copy),
                    onTap: () => copyToClipboard(SurgicalSlotService.instance.webcalUrl(currentToken)),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.surgicalAgendaIcsCopyHttps),
                    trailing: const Icon(Icons.copy),
                    onTap: () => copyToClipboard(SurgicalSlotService.instance.httpsIcsUrl(currentToken)),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () => launchUrl(
                      Uri.parse(SurgicalSlotService.instance.webcalUrl(currentToken)),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(l10n.surgicalAgendaIcsSubscribeDevice),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(onPressed: regenerate, child: Text(l10n.surgicalAgendaIcsRegenerate)),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(MaterialLocalizations.of(ctx).closeButtonLabel),
            ),
          ],
        );
      },
    ),
  );
}
