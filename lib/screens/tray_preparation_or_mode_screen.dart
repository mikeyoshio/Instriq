import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/tray.dart';
import '../models/tray_preparation_session.dart';
import '../services/custom_instrument_service.dart';
import '../services/tray_preparation_service.dart';

const _bg = Color(0xFF0A0F0D);
const _cardBg = Color(0xFF121815);
const _cardBorder = Color(0xFF202B26);
const _doneBg = Color(0xFF123832);
const _doneBorder = Color(0xFF1E5B50);
const _track = Color(0xFF1C2521);
const _textPrimary = Color(0xFFF4F6F4);
const _textMuted = Color(0xFF7C9B93);
const _warnBg = Color(0xFF3A2A12);
const _warnBorder = Color(0xFF6B4A1D);
const _warnAccent = Color(0xFFF5A524);
const _accent = InstriqColors.accentDark;

class _ItemDraft {
  final TrayItem item;
  bool resolved = false;
  bool present = true;
  late int actualQty;
  String? note;

  _ItemDraft(this.item) : actualQty = item.expectedQty;

  bool get isException => !present || actualQty != item.expectedQty || (note?.isNotEmpty ?? false);
}

/// Checklist de preparación de bandeja pensada para usarse dentro de
/// quirófano o la sala de montaje: filas grandes para tocar con guante,
/// fondo oscuro para no deslumbrar bajo la luz del campo, un único acento
/// de color y salida protegida con mantener pulsado. Sustituye al antiguo
/// formulario plano (TrayPreparationFormScreen) para el mismo flujo de
/// "Preparar bandeja".
class TrayPreparationOrModeScreen extends StatefulWidget {
  final Tray tray;

  const TrayPreparationOrModeScreen({super.key, required this.tray});

  @override
  State<TrayPreparationOrModeScreen> createState() => _TrayPreparationOrModeScreenState();
}

class _TrayPreparationOrModeScreenState extends State<TrayPreparationOrModeScreen> {
  List<CustomInstrument> _customInstruments = [];
  late List<_ItemDraft> _drafts;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final items = widget.tray.publishedVersion?.items ?? const <TrayItem>[];
    _drafts = items.map(_ItemDraft.new).toList();
    _load();
  }

  Future<void> _load() async {
    try {
      await CustomInstrumentService.instance.fetchForWorkspace(widget.tray.workspaceId);
      _customInstruments = CustomInstrumentService.instance.instruments;
    } catch (_) {
      // Sin bloquear la checklist: se muestra el id crudo si falla.
    }
    if (mounted) setState(() => _loading = false);
  }

  void _toggleRow(_ItemDraft draft) {
    setState(() {
      draft.resolved = !draft.resolved;
      draft.present = true;
      draft.actualQty = draft.item.expectedQty;
      draft.note = null;
    });
  }

  Future<void> _openExceptionSheet(_ItemDraft draft) async {
    final l10n = AppLocalizations.of(context)!;
    bool present = draft.present;
    int qty = draft.actualQty;
    final noteController = TextEditingController(text: draft.note ?? '');

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft.item.resolveName(_customInstruments),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.orModeIsPresentLabel, style: const TextStyle(color: _textPrimary, fontSize: 15)),
                      Switch(
                        value: present,
                        activeThumbColor: _accent,
                        onChanged: (v) => setSheetState(() {
                          present = v;
                          if (!v) {
                            qty = 0;
                          } else if (qty == 0) {
                            qty = draft.item.expectedQty;
                          }
                        }),
                      ),
                    ],
                  ),
                  if (present) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.actualQtyLabel, style: const TextStyle(color: _textPrimary, fontSize: 15)),
                        Row(
                          children: [
                            _StepperButton(icon: Icons.remove, onTap: () => setSheetState(() {
                              if (qty > 0) qty--;
                            })),
                            SizedBox(
                              width: 40,
                              child: Center(
                                child: Text(
                                  '$qty',
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: _textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            _StepperButton(icon: Icons.add, onTap: () => setSheetState(() => qty++)),
                          ],
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: noteController,
                    style: const TextStyle(color: _textPrimary),
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.itemNoteLabel,
                      labelStyle: const TextStyle(color: _textMuted),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _accent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: _bg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        setState(() {
                          draft.present = present;
                          draft.actualQty = qty;
                          draft.note = noteController.text.trim().isEmpty ? null : noteController.text.trim();
                          draft.resolved = true;
                        });
                        Navigator.of(sheetContext).pop();
                      },
                      child: Text(l10n.save),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      final results = _drafts
          .map((d) => TrayPreparationItemResult(
                instrumentRefType: d.item.instrumentRefType,
                instrumentRefId: d.item.instrumentRefId,
                expectedQty: d.item.expectedQty,
                actualQty: d.actualQty,
                present: d.present,
                note: d.note,
              ))
          .toList();
      await TrayPreparationService.instance.createSession(widget.tray.id, results);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = _drafts.length;
    final done = _drafts.where((d) => d.resolved).length;
    final allResolved = total > 0 && done == total;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.orModeExitToast), duration: const Duration(seconds: 2)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _buildHeader(l10n, done, total),
                    Expanded(
                      child: total == 0
                          ? Center(
                              child: Text(l10n.trayNoItemsYet, style: const TextStyle(color: _textMuted)),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
                              itemCount: total,
                              itemBuilder: (_, i) => _buildRow(l10n, _drafts[i]),
                            ),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: _loading || total == 0
            ? null
            : SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  color: _bg,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: allResolved ? _accent : _track,
                        foregroundColor: allResolved ? _bg : const Color(0xFF5A6B64),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: (allResolved && !_saving) ? _submit : null,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _bg),
                            )
                          : Text(
                              l10n.submitPreparationAction,
                              style: const TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, int done, int total) {
    final fraction = total == 0 ? 0.0 : done / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _HoldToExitControl(
                      label: l10n.orModeHoldToExit,
                      onConfirmExit: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    Text(
                      l10n.orModeTitle.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: _accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.tray.publishedVersion?.name ?? l10n.prepareTrayTitle,
                  style: const TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w800, fontSize: 24, color: _textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: fraction,
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                    backgroundColor: _track,
                    valueColor: const AlwaysStoppedAnimation(_accent),
                  ),
                ),
                Text(
                  '$done/$total',
                  style: const TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w800, fontSize: 15, color: _textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(AppLocalizations l10n, _ItemDraft draft) {
    final resolved = draft.resolved;
    final exception = resolved && draft.isException;
    final bg = exception ? _warnBg : (resolved ? _doneBg : _cardBg);
    final border = exception ? _warnBorder : (resolved ? _doneBorder : _cardBorder);
    final badgeText = exception
        ? '×${draft.actualQty}'
        : (draft.item.position != null && draft.item.position!.isNotEmpty
            ? '${draft.item.position} · ×${draft.item.expectedQty}'
            : '×${draft.item.expectedQty}');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _toggleRow(draft),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                AnimatedScale(
                  scale: resolved ? 1.06 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.elasticOut,
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: resolved ? (exception ? _warnAccent : _accent) : Colors.transparent,
                      border: Border.all(
                        color: resolved ? (exception ? _warnAccent : _accent) : const Color(0xFF33413A),
                        width: 2.5,
                      ),
                    ),
                    child: resolved
                        ? Icon(exception ? Icons.priority_high_rounded : Icons.check_rounded, size: 20, color: _bg)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    draft.item.resolveName(_customInstruments),
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                      color: resolved && !exception ? const Color(0xFF8FB6AE) : _textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _openExceptionSheet(draft),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: exception ? const Color(0xFF4A3416) : _track,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: exception ? _warnAccent : const Color(0xFFCBD5D0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _track,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 18, color: _textPrimary),
        ),
      ),
    );
  }
}

class _HoldToExitControl extends StatefulWidget {
  final VoidCallback onConfirmExit;
  final String label;

  const _HoldToExitControl({required this.onConfirmExit, required this.label});

  @override
  State<_HoldToExitControl> createState() => _HoldToExitControlState();
}

class _HoldToExitControlState extends State<_HoldToExitControl> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          HapticFeedback.mediumImpact();
          widget.onConfirmExit();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _controller.forward(from: 0),
      onLongPressEnd: (_) => _controller.reverse(),
      onLongPressCancel: () => _controller.reverse(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => SizedBox(
              width: 20,
              height: 20,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(BorderSide(color: Color(0xFF2A3530), width: 2.5)),
                    ),
                  ),
                  if (_controller.value > 0)
                    CircularProgressIndicator(
                      value: _controller.value,
                      strokeWidth: 2.5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation(_accent),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            widget.label.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: _textMuted),
          ),
        ],
      ),
    );
  }
}
