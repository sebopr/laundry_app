import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavaplan/l10n/app_localizations.dart';
import 'package:lavaplan/l10n/rm_fallback_localizations.dart';

// Regression test for "No MaterialLocalizations found." — flutter_localizations
// has no Romansh, so 'rm' needs the fallback delegates to build Material
// widgets at all.

void main() {
  test('flutter_localizations has no Romansh of its own', () {
    expect(
      GlobalMaterialLocalizations.delegate.isSupported(const Locale('rm')),
      isFalse,
    );
    expect(
      DefaultMaterialLocalizations.delegate.isSupported(const Locale('rm')),
      isFalse,
    );
  });

  testWidgets('rm builds Material widgets and falls back to German',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('rm'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          ...AppLocalizations.localizationsDelegates,
          ...rmFallbackLocalizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(title: const Text('Rumantsch')),
          body: const SizedBox.shrink(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Rumantsch'), findsOneWidget);

    final BuildContext context = tester.element(find.byType(Scaffold));
    // App strings still come from app_rm.arb ...
    expect(AppLocalizations.of(context)!.localeName, 'rm');
    expect(AppLocalizations.of(context)!.fieldPassword, 'Pled-clav');
    // ... while the framework's own strings fall back to German.
    expect(MaterialLocalizations.of(context).okButtonLabel, 'OK');
    expect(MaterialLocalizations.of(context).cancelButtonLabel, 'Abbrechen');
  });
}
