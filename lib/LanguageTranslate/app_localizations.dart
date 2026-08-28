import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale? locale;

  AppLocalizations({
    this.locale,
  });

  // A static method to obtain an instance of AppLocalizations in the context
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // A LocalizationsDelegate for this localization class
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // A map to store the localized strings
  late Map<String, String> _localizedStrings;

  // Method to load localized strings from JSON files
  Future loadJsonLanguage() async {
    String jsonString =
        await rootBundle.loadString("assets/lang/${locale!.languageCode}.json");

    // Parse the JSON string into a map
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    // Convert the map values to strings and store them in the _localizedStrings map
    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
  }

  // Method to translate a key into a localized string
  String translate(String key) => _localizedStrings[key] ?? "";

  // Method to translate a key with dynamic arguments
  String translateWithArgs(String key, Map<String, dynamic> args) {
    String translation = _localizedStrings[key] ?? "";

    // Replace placeholders in the translation string with actual values from args
    args.forEach((key, value) {
      translation = translation.replaceAll("{$key}", value.toString());
    });

    return translation;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Define the supported locales (e.g., 'en' for English, 'ar' for Arabic)
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Create an instance of AppLocalizations and load the appropriate JSON file
    AppLocalizations localizations = AppLocalizations(locale: locale);
    await localizations.loadJsonLanguage();
    return localizations;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
