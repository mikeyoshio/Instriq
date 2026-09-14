import 'package:flutter/material.dart';

import '../tokens.dart';

/// Envuelve el contenido de una pantalla (típicamente el `body` de un
/// `Scaffold`) para que, en ventanas anchas (escritorio/tablet apaisada), no
/// se estire de borde a borde: se centra con un ancho máximo de columna
/// legible ([InstriqBreakpoints.maxContentWidth]). En móvil (ventana más
/// estrecha que ese máximo) es un no-op: [ConstrainedBox] solo pone un
/// tope, nunca un ancho fijo, así que el hijo sigue ocupando todo el ancho
/// disponible igual que antes de envolverlo.
///
/// Es deliberadamente el único mecanismo de layout responsive por pantalla
/// (a diferencia de `app_shell.dart`, que sí necesita un `LayoutBuilder` con
/// [InstriqBreakpoints.tablet] porque cambia de *forma* de navegación, no
/// solo de ancho): no hace falta ningún breakpoint explícito por pantalla,
/// solo envolver el contenido existente con este widget.
class InstriqResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const InstriqResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = InstriqBreakpoints.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
