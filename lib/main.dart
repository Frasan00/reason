import 'package:material_ui/material_ui.dart';

import 'l10n/l10n.dart';
import 'record_screen.dart';
import 'recorder_controller.dart';
import 'settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = SettingsStore();
  Settings initial;
  try {
    initial = await store.load();
  } catch (_) {
    initial = Settings.defaults;
  }

  runApp(
    ReasonApp(
      settings: SettingsController(initial, store),
      recorder: RecorderController(),
    ),
  );
}

class ReasonApp extends StatelessWidget {
  const ReasonApp({super.key, required this.settings, required this.recorder});

  final SettingsController settings;
  final RecorderController recorder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'reason',
        debugShowCheckedModeBanner: false,
        locale: switch (settings.settings.language.localeCode) {
          final code? => Locale(code),
          null => null,
        },
        localizationsDelegates: appLocalizationDelegates,
        supportedLocales: appSupportedLocales,
        localeListResolutionCallback: resolveAppLocale,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF9AA0A6),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.black,
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF2F1ED),
              foregroundColor: const Color(0xFF141414),
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF262626),
            contentTextStyle: TextStyle(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        home: RecordScreen(settings: settings, recorder: recorder),
      ),
    );
  }
}
