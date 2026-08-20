import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Rumantsch ('rm') is one of the app's supported locales, but
// flutter_localizations ships no Romansh translations for Flutter's built-in
// Material and Cupertino widgets. Without a MaterialLocalizations for the
// active locale, every Scaffold, AppBar, NavigationBar and date widget throws
// "No MaterialLocalizations found." at build time.
//
// These delegates claim 'rm' and serve the German strings instead — the
// language Romansh speakers in Graubünden read. Only the framework's own
// widget strings fall back; the app's strings still come from app_rm.arb.

const Locale _fallbackLocale = Locale('de');

/// Delegates that provide framework localizations for 'rm'.
///
/// Append these to [AppLocalizations.localizationsDelegates] in MaterialApp.
const List<LocalizationsDelegate<dynamic>> rmFallbackLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
  _RmMaterialLocalizationsDelegate(),
  _RmCupertinoLocalizationsDelegate(),
];

class _RmMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _RmMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'rm';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(_fallbackLocale);

  @override
  bool shouldReload(_RmMaterialLocalizationsDelegate old) => false;
}

class _RmCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _RmCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'rm';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(_fallbackLocale);

  @override
  bool shouldReload(_RmCupertinoLocalizationsDelegate old) => false;
}
