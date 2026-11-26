import 'package:material_ui/material_ui.dart';

import 'generated/app_localizations.dart';

/// Material strings come from material_ui: its widgets only accept its own
/// [MaterialLocalizations], not the flutter/material one.
final appLocalizationDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

const appSupportedLocales = AppLocalizations.supportedLocales;

/// Flutter would fall back to the first supported locale, which is German.
/// A phone in a language the app does not have should read English instead.
Locale resolveAppLocale(List<Locale>? locales, Iterable<Locale> supported) {
  for (final locale in locales ?? const <Locale>[]) {
    for (final candidate in supported) {
      if (candidate.languageCode == locale.languageCode) return candidate;
    }
  }
  return const Locale('en');
}
