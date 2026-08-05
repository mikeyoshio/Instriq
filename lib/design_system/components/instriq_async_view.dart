import 'package:flutter/material.dart';

import '../tokens.dart';
import 'instriq_button.dart';

/// Contrato único loading / vacío / error-con-reintento para cualquier carga
/// de lista o detalle. Sustituye el patrón `catch(_) { loading = false }` que
/// convierte un fallo de red en un falso "no hay nada" — el error real se
/// conserva y se ofrece un botón de reintento explícito.
class InstriqAsyncView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data)? isEmpty;
  final WidgetBuilder? emptyBuilder;
  final String Function(Object error) errorMessage;
  final String retryLabel;

  const InstriqAsyncView({
    super.key,
    required this.load,
    required this.builder,
    required this.errorMessage,
    required this.retryLabel,
    this.isEmpty,
    this.emptyBuilder,
  });

  @override
  State<InstriqAsyncView<T>> createState() => InstriqAsyncViewState<T>();
}

class InstriqAsyncViewState<T> extends State<InstriqAsyncView<T>> {
  bool _loading = true;
  Object? _error;
  T? _data;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(InstriqSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: InstriqSpacing.md),
              Text(
                widget.errorMessage(_error!),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: InstriqSpacing.lg),
              InstriqButton.secondary(label: widget.retryLabel, onPressed: reload),
            ],
          ),
        ),
      );
    }
    final data = _data as T;
    if (widget.isEmpty != null && widget.isEmpty!(data)) {
      return widget.emptyBuilder?.call(context) ?? const SizedBox.shrink();
    }
    return widget.builder(context, data);
  }
}
