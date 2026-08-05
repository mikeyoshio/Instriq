import 'package:flutter/material.dart';

import '../tokens.dart';

/// Tipo de campo escalar comparado por [FieldDiffDescriptor].
enum FieldKind { text, boolean }

/// Descriptor de un campo escalar a comparar entre dos versiones de [T].
class FieldDiffDescriptor<T> {
  final String label;
  final FieldKind kind;
  final String? Function(T version)? textValueOf;
  final bool Function(T version)? boolValueOf;

  const FieldDiffDescriptor._({
    required this.label,
    required this.kind,
    this.textValueOf,
    this.boolValueOf,
  });

  factory FieldDiffDescriptor.text({required String label, required String? Function(T version) valueOf}) {
    return FieldDiffDescriptor._(label: label, kind: FieldKind.text, textValueOf: valueOf);
  }

  factory FieldDiffDescriptor.boolean({required String label, required bool Function(T version) valueOf}) {
    return FieldDiffDescriptor._(label: label, kind: FieldKind.boolean, boolValueOf: valueOf);
  }
}

/// Descriptor de una lista de ítems (instrumental de una bandeja, ids
/// relacionados, pasos de protocolo...) a comparar entre dos versiones de
/// [T], cada ítem de tipo [I].
///
/// [displayOf] es obligatorio a nivel de tipo: no hay forma de construir un
/// [SetDiffDescriptor] sin decidir explícitamente cómo se muestra un ítem —
/// esto es lo que impide que un id crudo sin resolver se cuele en pantalla
/// (bug antiguo de `group_document_diff_screen.dart`, donde
/// `relatedInstrumentIds`/`relatedTrayIds` se mostraban tal cual).
class SetDiffDescriptor<T, I> {
  final String label;
  final List<I> Function(T version) itemsOf;
  final String Function(I item) keyOf;
  final String Function(I item) displayOf;

  /// Opcional: si dos ítems tienen la misma [keyOf] pero distinto
  /// [fingerprintOf] entre versiones, se renderizan como "Modificado" en vez
  /// de desaparecer silenciosamente en "sin cambios". Pensado para detectar
  /// cambios de cantidad/posición en el instrumental de una bandeja sin que
  /// cuenten como alta+baja.
  final String? Function(I item)? fingerprintOf;

  const SetDiffDescriptor({
    required this.label,
    required this.itemsOf,
    required this.keyOf,
    required this.displayOf,
    this.fingerprintOf,
  });
}

/// Comparación campo a campo entre dos versiones de contenido (bandeja,
/// documento, tarjeta de preferencia...): qué cambió, no un diff de texto
/// letra a letra. Consolida `_FieldDiff`/`_BoolFieldDiff`/`_ChangeTile`, casi
/// idénticos en las 3 pantallas de diff que existían antes.
///
/// No incluye `Scaffold`/`AppBar`: es contenido de página, igual que
/// [InstriqAsyncView] — el punto de crida mantiene su propio título (rango
/// de versiones) porque solo él sabe cómo formatearlo con l10n.
class InstriqVersionDiff<T> extends StatelessWidget {
  final T older;
  final T newer;
  final List<FieldDiffDescriptor<T>> fields;
  final List<SetDiffDescriptor<T, dynamic>> sets;
  final String noChangesLabel;

  /// Etiqueta para un ítem detectado como modificado (misma key, distinto
  /// fingerprint) — recibe el texto ya resuelto de [SetDiffDescriptor.displayOf].
  final String Function(String itemDisplay) modifiedLabelOf;

  const InstriqVersionDiff({
    super.key,
    required this.older,
    required this.newer,
    required this.fields,
    required this.sets,
    required this.noChangesLabel,
    required this.modifiedLabelOf,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(InstriqSpacing.xl),
      children: [
        for (final field in fields) _buildField(context, field),
        for (final set in sets) ..._buildSet(context, set),
      ],
    );
  }

  Widget _buildField(BuildContext context, FieldDiffDescriptor<T> field) {
    switch (field.kind) {
      case FieldKind.text:
        return _FieldDiff(
          label: field.label,
          oldValue: field.textValueOf!(older) ?? '—',
          newValue: field.textValueOf!(newer) ?? '—',
        );
      case FieldKind.boolean:
        return _BoolFieldDiff(
          label: field.label,
          oldValue: field.boolValueOf!(older),
          newValue: field.boolValueOf!(newer),
        );
    }
  }

  List<Widget> _buildSet(BuildContext context, SetDiffDescriptor<T, dynamic> set) {
    final oldItems = set.itemsOf(older);
    final newItems = set.itemsOf(newer);
    final oldByKey = {for (final item in oldItems) set.keyOf(item): item};
    final newByKey = {for (final item in newItems) set.keyOf(item): item};

    final addedKeys = newByKey.keys.where((k) => !oldByKey.containsKey(k)).toList();
    final removedKeys = oldByKey.keys.where((k) => !newByKey.containsKey(k)).toList();
    final commonKeys = oldByKey.keys.where((k) => newByKey.containsKey(k)).toList();
    final fingerprintOf = set.fingerprintOf;
    final modifiedKeys = fingerprintOf == null
        ? const <String>[]
        : commonKeys.where((k) => fingerprintOf(oldByKey[k]) != fingerprintOf(newByKey[k])).toList();

    final noChanges = addedKeys.isEmpty && removedKeys.isEmpty && modifiedKeys.isEmpty;
    final neutralColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return [
      const SizedBox(height: InstriqSpacing.xl),
      Text(set.label, style: Theme.of(context).textTheme.titleMedium),
      if (noChanges)
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(noChangesLabel))
      else ...[
        ...addedKeys.map((k) => _ChangeTile(
              icon: Icons.add,
              color: Colors.green,
              text: set.displayOf(newByKey[k]),
            )),
        ...removedKeys.map((k) => _ChangeTile(
              icon: Icons.remove,
              color: Colors.red,
              text: set.displayOf(oldByKey[k]),
            )),
        ...modifiedKeys.map((k) => _ChangeTile(
              icon: Icons.edit,
              color: neutralColor,
              text: modifiedLabelOf(set.displayOf(newByKey[k])),
            )),
      ],
    ];
  }
}

class _FieldDiff extends StatelessWidget {
  final String label;
  final String oldValue;
  final String newValue;

  const _FieldDiff({required this.label, required this.oldValue, required this.newValue});

  @override
  Widget build(BuildContext context) {
    final changed = oldValue != newValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          if (!changed)
            Text(newValue)
          else ...[
            Text(oldValue, style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
            Text(newValue, style: const TextStyle(color: Colors.green)),
          ],
        ],
      ),
    );
  }
}

class _BoolFieldDiff extends StatelessWidget {
  final String label;
  final bool oldValue;
  final bool newValue;

  const _BoolFieldDiff({required this.label, required this.oldValue, required this.newValue});

  Widget _icon(bool value) => Icon(
        value ? Icons.check_circle : Icons.cancel_outlined,
        color: value ? Colors.green : Colors.grey,
        size: 20,
      );

  @override
  Widget build(BuildContext context) {
    final changed = oldValue != newValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Row(
            children: [
              _icon(oldValue),
              if (changed) ...[
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16),
                const SizedBox(width: 8),
                _icon(newValue),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ChangeTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _ChangeTile({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon, color: color), title: Text(text), dense: true);
  }
}
