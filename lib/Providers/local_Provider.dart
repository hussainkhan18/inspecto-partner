import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/LanguageTranslate/l10n.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!L10n.all.contains(locale)) return;

    _locale = locale;
    notifyListeners();
  }
}
