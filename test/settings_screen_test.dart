import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reason/l10n/generated/app_localizations.dart';
import 'package:reason/l10n/l10n.dart';
import 'package:reason/settings.dart';
import 'package:reason/settings_screen.dart';

Widget settingsApp(
  Settings settings, {
  Locale locale = const Locale('en'),
  ValueChanged<Settings>? onChanged,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: appLocalizationDelegates,
    supportedLocales: appSupportedLocales,
    home: SettingsScreen(
      initial: settings,
      capabilities: Capabilities.optimistic,
      onChanged: (next) async => onChanged?.call(next),
      onPickFolder: () async => null,
      onUseAppStorage: () async => null,
    ),
  );
}

void main() {
  testWidgets('each tab shows its category', (tester) async {
    await tester.pumpWidget(settingsApp(Settings.defaults));
    expect(find.text('Resolution'), findsOneWidget);

    await tester.tap(find.text('Storage'));
    await tester.pumpAndSettle();
    expect(find.text('Storage budget'), findsOneWidget);
    expect(find.text('Destroy after'), findsOneWidget);

    await tester.tap(find.text('Car'));
    await tester.pumpAndSettle();
    expect(find.text('Start in the car'), findsOneWidget);
  });

  testWidgets('destroy after offers presets and a custom value', (
    tester,
  ) async {
    await tester.pumpWidget(settingsApp(Settings.defaults));
    await tester.tap(find.text('Storage'));
    await tester.pumpAndSettle();

    expect(find.text('Never'), findsOneWidget);
    expect(find.text('1 hour'), findsOneWidget);
    expect(find.text('1 day'), findsOneWidget);
    expect(find.text('7 days'), findsOneWidget);

    await tester.tap(find.text('Custom').last);
    await tester.pumpAndSettle();
    expect(find.text('Set'), findsOneWidget);
  });

  testWidgets('a custom duration is stored in minutes', (tester) async {
    Settings? saved;
    await tester.pumpWidget(
      settingsApp(Settings.defaults, onChanged: (next) => saved = next),
    );
    await tester.tap(find.text('Storage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '2');
    await tester.tap(find.text('Minutes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hours').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();

    expect(saved?.destroyAfterMinutes, 120);
    expect(find.text('2 Hours'), findsOneWidget);
  });

  testWidgets('italian labels come from the arb file', (tester) async {
    await tester.pumpWidget(
      settingsApp(Settings.defaults, locale: const Locale('it')),
    );
    expect(find.text('Risoluzione'), findsOneWidget);

    await tester.tap(find.text('Archiviazione'));
    await tester.pumpAndSettle();
    expect(find.text('Elimina dopo'), findsOneWidget);
    expect(find.text('Mai'), findsOneWidget);
  });

  testWidgets('every language has its own strings', (tester) async {
    await tester.pumpWidget(settingsApp(Settings.defaults));
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    for (final name in [
      'English',
      'Italiano',
      'Français',
      'Español',
      'Deutsch',
    ]) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
  });

  test('each supported locale is translated', () async {
    expect(appSupportedLocales.length, 5);
    for (final locale in appSupportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      expect(l10n.settings, isNotEmpty, reason: '$locale');
      expect(l10n.destroyAfter, isNotEmpty, reason: '$locale');
      expect(l10n.numberRange(1, 5), contains('5'), reason: '$locale');
    }
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    for (final locale in appSupportedLocales.where(
      (l) => l.languageCode != 'en',
    )) {
      final l10n = await AppLocalizations.delegate.load(locale);
      expect(l10n.settings, isNot(english.settings), reason: '$locale');
    }
  });
}
