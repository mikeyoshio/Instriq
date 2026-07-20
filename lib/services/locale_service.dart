import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idioma de la app. Por defecto català — no el idioma del dispositivo —
/// salvo que la persona ya haya elegido uno explícitamente antes.
class LocaleService {
  LocaleService._();
  static final LocaleService instance = LocaleService._();

  static const _key = 'locale_code';
  static const defaultLocale = Locale('ca');

  final ValueNotifier<Locale> locale = ValueNotifier(defaultLocale);
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs?.getString(_key);
    if (stored != null) {
      locale.value = Locale(stored);
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    locale.value = newLocale;
    await _prefs?.setString(_key, newLocale.languageCode);
  }
}
