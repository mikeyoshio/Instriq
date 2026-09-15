import 'package:flutter/material.dart';

/// Un paso numerado dentro de un artículo de ayuda, con captura opcional.
class HelpStep {
  final String text;
  final String? image;

  const HelpStep({required this.text, this.image});
}

/// Un "cómo hacer X" completo: icono, título, una frase de contexto y los
/// pasos. Los textos llegan ya resueltos desde `AppLocalizations` -- ver
/// `help_content.dart`, donde se construye la lista completa dentro de un
/// `build()` (no hay lookup dinámico por clave: las claves de
/// `AppLocalizations` son getters tipados, no un mapa).
class HelpArticle {
  final String id;
  final IconData icon;
  final String title;
  final String intro;
  final List<HelpStep> steps;

  const HelpArticle({
    required this.id,
    required this.icon,
    required this.title,
    required this.intro,
    required this.steps,
  });
}

class HelpCategory {
  final String title;
  final List<HelpArticle> articles;

  const HelpCategory({required this.title, required this.articles});
}
