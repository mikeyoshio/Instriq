import 'package:flutter/material.dart';

/// Paleta con sesgo hacia un único acento (familia teal), declarada como
/// tokens explícitos en vez de generarse desde un `colorSchemeSeed`: así el
/// contraste texto/superficie/borde queda fijado a mano en vez de
/// depender del algoritmo de Material You.
class InstriqColors {
  InstriqColors._();

  // Acento (teal).
  static const accent = Color(0xFF0F766E);
  static const accentDark = Color(0xFF5EEAD4);
  static const onAccent = Color(0xFFFFFFFF);
  static const onAccentDark = Color(0xFF00332E);

  // Superficie/fondo — light.
  static const backgroundLight = Color(0xFFFAFAF9);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceVariantLight = Color(0xFFF2F1EF);
  static const borderLight = Color(0xFFE2E0DC);

  // Superficie/fondo — dark.
  static const backgroundDark = Color(0xFF121412);
  static const surfaceDark = Color(0xFF1B1D1B);
  static const surfaceVariantDark = Color(0xFF262924);
  static const borderDark = Color(0xFF34382F);

  // Texto — light.
  static const textPrimaryLight = Color(0xFF1C1C1A);
  static const textSecondaryLight = Color(0xFF57574F);

  // Texto — dark.
  static const textPrimaryDark = Color(0xFFECEDE9);
  static const textSecondaryDark = Color(0xFFB2B4A9);

  static const error = Color(0xFFBA1A1A);
  static const errorDark = Color(0xFFFFB4AB);

  // Colores por estado de contenido (borrador/revisión/publicado/archivado).
  static const statusDraft = Color(0xFF78716C);
  static const statusInReview = Color(0xFFB45309);
  static const statusPublished = Color(0xFF15803D);
  static const statusArchived = Color(0xFF57534E);
}

/// Escala de espaciado 4/8/12/16/24/32/48: cualquier padding/gap del design
/// system se referencia a uno de estos valores, nunca a un número suelto.
class InstriqSpacing {
  InstriqSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

class InstriqRadius {
  InstriqRadius._();

  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;

  static const smRadius = BorderRadius.all(Radius.circular(sm));
  static const mdRadius = BorderRadius.all(Radius.circular(md));
  static const lgRadius = BorderRadius.all(Radius.circular(lg));
}

/// TextTheme completo: Manrope para títulos/display, Inter para cuerpo.
class InstriqTypography {
  InstriqTypography._();

  static const _display = 'Manrope';
  static const _body = 'Inter';

  static TextTheme textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: _display,
        fontSize: 57,
        fontWeight: FontWeight.w800,
        height: 1.12,
        color: primary,
      ),
      displayMedium: TextStyle(
        fontFamily: _display,
        fontSize: 45,
        fontWeight: FontWeight.w800,
        height: 1.16,
        color: primary,
      ),
      displaySmall: TextStyle(
        fontFamily: _display,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.22,
        color: primary,
      ),
      headlineLarge: TextStyle(
        fontFamily: _display,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontFamily: _display,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.29,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontFamily: _display,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.33,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontFamily: _display,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.27,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: _body,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontFamily: _body,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.43,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontFamily: _body,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontFamily: _body,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
        color: primary,
      ),
      bodySmall: TextStyle(
        fontFamily: _body,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
        color: secondary,
      ),
      labelLarge: TextStyle(
        fontFamily: _body,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.43,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontFamily: _body,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.33,
        color: primary,
      ),
      labelSmall: TextStyle(
        fontFamily: _body,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.45,
        color: secondary,
      ),
    );
  }
}
