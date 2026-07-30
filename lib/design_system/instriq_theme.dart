import 'package:flutter/material.dart';

import 'tokens.dart';

/// Construye el `ThemeData` de la app desde los tokens de [InstriqColors]/
/// [InstriqTypography] en vez de un `colorSchemeSeed` automático: el
/// `ColorScheme` queda fijado explícitamente para ambos modos.
class InstriqTheme {
  InstriqTheme._();

  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: InstriqColors.accent,
      onPrimary: InstriqColors.onAccent,
      secondary: InstriqColors.accent,
      onSecondary: InstriqColors.onAccent,
      error: InstriqColors.error,
      onError: Colors.white,
      surface: InstriqColors.surfaceLight,
      onSurface: InstriqColors.textPrimaryLight,
      surfaceContainerHighest: InstriqColors.surfaceVariantLight,
      onSurfaceVariant: InstriqColors.textSecondaryLight,
      outline: InstriqColors.borderLight,
      outlineVariant: InstriqColors.borderLight,
    );
    return _build(scheme, InstriqColors.backgroundLight);
  }

  static ThemeData get dark {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: InstriqColors.accentDark,
      onPrimary: InstriqColors.onAccentDark,
      secondary: InstriqColors.accentDark,
      onSecondary: InstriqColors.onAccentDark,
      error: InstriqColors.errorDark,
      onError: Color(0xFF690005),
      surface: InstriqColors.surfaceDark,
      onSurface: InstriqColors.textPrimaryDark,
      surfaceContainerHighest: InstriqColors.surfaceVariantDark,
      onSurfaceVariant: InstriqColors.textSecondaryDark,
      outline: InstriqColors.borderDark,
      outlineVariant: InstriqColors.borderDark,
    );
    return _build(scheme, InstriqColors.backgroundDark);
  }

  static ThemeData _build(ColorScheme scheme, Color background) {
    final textTheme = InstriqTypography.textTheme(scheme.onSurface, scheme.onSurfaceVariant);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: InstriqRadius.mdRadius,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        labelType: NavigationRailLabelType.all,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: InstriqRadius.smRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(borderRadius: InstriqRadius.smRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: InstriqRadius.smRadius),
        ),
      ),
    );
  }
}
