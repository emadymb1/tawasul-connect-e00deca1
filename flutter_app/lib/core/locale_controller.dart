import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Arabic is the default; the user can switch to English at any time.
class LocaleController extends StateNotifier<Locale> {
  LocaleController() : super(const Locale('ar')) {
    _restore();
  }

  static const _key = 'tawasul.locale';

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code == 'en' || code == 'ar') state = Locale(code!);
  }

  Future<void> set(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  Future<void> toggle() =>
      set(state.languageCode == 'ar' ? const Locale('en') : const Locale('ar'));
}

final localeControllerProvider =
    StateNotifierProvider<LocaleController, Locale>((ref) => LocaleController());
