import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reason/clip_library_screen.dart';
import 'package:reason/l10n/l10n.dart';
import 'package:reason/record_screen.dart';
import 'package:reason/recorder_controller.dart';

/// A MaterialApp with the app's real delegates, in the given language.
Widget app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  localizationsDelegates: appLocalizationDelegates,
  supportedLocales: appSupportedLocales,
  home: child,
);

const _recording = RecorderStatus(
  state: 'recording',
  camera: 'rear',
  resolution: '1080p',
  segmentMinutes: 3,
  budgetBytes: 2 * 1024 * 1024 * 1024,
  sessionElapsedMs: 3661000,
  segmentIndex: 1,
  usedBytes: 512 * 1024 * 1024,
  freeBytes: 1024 * 1024 * 1024,
  recording: true,
);

void main() {
  testWidgets('overlay shows recording state', (tester) async {
    await tester.pumpWidget(
      app(const Scaffold(body: RecordingOverlay(status: _recording))),
    );
    expect(find.text('01:01:01'), findsOneWidget);
    expect(find.textContaining('512.0 MB'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('record button switches icon', (tester) async {
    await tester.pumpWidget(
      app(
        Scaffold(
          body: PrimaryRecordButton(
            recording: false,
            busy: false,
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.fiber_manual_record), findsOneWidget);

    await tester.pumpWidget(
      app(
        Scaffold(
          body: PrimaryRecordButton(
            recording: true,
            busy: false,
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
  });

  testWidgets('busy button shows a spinner and is disabled', (tester) async {
    await tester.pumpWidget(
      app(
        Scaffold(
          body: PrimaryRecordButton(
            recording: false,
            busy: true,
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('warning banner maps the code', (tester) async {
    await tester.pumpWidget(
      app(const Scaffold(body: WarningBanner(warning: 'low_storage'))),
    );
    expect(
      find.text('Recording stopped. Less than 500 MB free'),
      findsOneWidget,
    );
  });

  testWidgets('clip row shows duration, size, protection and opens', (
    tester,
  ) async {
    final clip = ClipInfo(
      name: '1700000000000.mp4',
      uri: 'content://test/1700000000000.mp4',
      startEpochMs: DateTime.now().millisecondsSinceEpoch,
      sizeBytes: 512 * 1024 * 1024,
      durationMs: 3 * 60 * 1000,
      isProtected: true,
    );
    var played = false;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: ClipRow(
            clip: clip,
            onPlay: () => played = true,
            onShare: () {},
            onDelete: () {},
            onClearProtection: () {},
          ),
        ),
      ),
    );
    expect(find.text('3:00'), findsOneWidget);
    expect(find.text('512.0 MB'), findsOneWidget);
    expect(find.text('Protected'), findsOneWidget);
    await tester.tap(find.byType(ListTile));
    expect(played, isTrue);
  });

  testWidgets('clip row offers clear protection only when protected', (
    tester,
  ) async {
    ClipInfo clip({required bool isProtected}) => ClipInfo(
      name: '1700000000000.mp4',
      uri: 'content://test/1700000000000.mp4',
      startEpochMs: DateTime.now().millisecondsSinceEpoch,
      sizeBytes: 1024,
      durationMs: 60000,
      isProtected: isProtected,
    );

    Widget row(ClipInfo value) => app(
      Scaffold(
        body: ClipRow(
          clip: value,
          onPlay: () {},
          onShare: () {},
          onDelete: () {},
          onClearProtection: () {},
        ),
      ),
    );

    await tester.pumpWidget(row(clip(isProtected: true)));
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Clear protection'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(row(clip(isProtected: false)));
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Clear protection'), findsNothing);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('clip row dates follow the italian locale', (tester) async {
    final clip = ClipInfo(
      name: '1700000000000.mp4',
      uri: 'content://test/1700000000000.mp4',
      startEpochMs: DateTime(2026, 11, 24, 18, 42).millisecondsSinceEpoch,
      sizeBytes: 1024,
      durationMs: 60000,
      isProtected: false,
    );
    await tester.pumpWidget(
      app(
        Scaffold(
          body: ClipRow(
            clip: clip,
            onPlay: () {},
            onShare: () {},
            onDelete: () {},
            onClearProtection: () {},
          ),
        ),
        locale: const Locale('it'),
      ),
    );
    expect(find.text('24 nov 18:42'), findsOneWidget);
    expect(find.text('Protetta'), findsNothing);
  });

  testWidgets('stop stays available while the camera retries', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: PrimaryRecordButton(
            recording: true,
            busy: true,
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.byType(FilledButton));
    expect(pressed, isTrue);
  });

  testWidgets('overlay says the camera is starting until a file is open', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const Scaffold(
          body: RecordingOverlay(
            status: RecorderStatus(
              state: 'starting',
              camera: 'rear',
              resolution: '1080p',
              segmentMinutes: 3,
              budgetBytes: 2 * 1024 * 1024 * 1024,
              sessionElapsedMs: 4000,
              segmentIndex: 0,
              usedBytes: 0,
              freeBytes: 1024 * 1024 * 1024,
              recording: true,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Starting the camera'), findsOneWidget);
  });

  test('an unknown phone language reads as English', () {
    expect(
      resolveAppLocale([const Locale('pt', 'BR')], appSupportedLocales),
      const Locale('en'),
    );
    expect(
      resolveAppLocale([const Locale('de', 'AT')], appSupportedLocales),
      const Locale('de'),
    );
    expect(resolveAppLocale(null, appSupportedLocales), const Locale('en'));
  });
}
