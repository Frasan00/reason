import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reason/l10n/l10n.dart';
import 'package:reason/recorder_controller.dart';
import 'package:reason/record_screen.dart';
import 'package:reason/settings.dart';
import 'package:reason/settings_screen.dart';

/// Smallest phone size the app should survive, with a large font setting.
const _phone = Size(360, 640);

Future<void> _useSmallPhone(WidgetTester tester, {double textScale = 1}) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Widget _app(Locale locale, Widget home) => MaterialApp(
  locale: locale,
  localizationsDelegates: appLocalizationDelegates,
  supportedLocales: appSupportedLocales,
  home: home,
);

void main() {
  for (final locale in appSupportedLocales) {
    testWidgets('settings fit a small phone in ${locale.languageCode}', (
      tester,
    ) async {
      await _useSmallPhone(tester, textScale: 1.3);
      await tester.pumpWidget(
        _app(
          locale,
          SettingsScreen(
            initial: Settings.defaults,
            capabilities: Capabilities.optimistic,
            onChanged: (_) async {},
            onPickFolder: () async => null,
            onUseAppStorage: () async => null,
            onLoadTimeZones: () async => const ['UTC', 'Europe/Rome'],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final controller = DefaultTabController.of(
        tester.element(find.byType(TabBarView)),
      );
      for (var index = 0; index < 5; index++) {
        controller.animateTo(index);
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${locale.languageCode} tab $index',
        );
      }
    });

    testWidgets('recording overlay fits a small phone in '
        '${locale.languageCode}', (tester) async {
      await _useSmallPhone(tester, textScale: 1.3);
      await tester.pumpWidget(
        _app(
          locale,
          const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: RecordingOverlay(
                status: RecorderStatus(
                  state: 'recording',
                  camera: 'rear',
                  resolution: '1080p',
                  segmentMinutes: 3,
                  budgetBytes: 2 * 1024 * 1024 * 1024,
                  sessionElapsedMs: 3661000,
                  segmentIndex: 12,
                  usedBytes: 1900 * 1024 * 1024,
                  freeBytes: 1024 * 1024 * 1024,
                  recording: true,
                  warning: 'low_storage',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('01:01:01'), findsOneWidget);
    });
  }
}
