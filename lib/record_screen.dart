import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';

import 'clip_library_screen.dart';
import 'format.dart';
import 'l10n/errors.dart';
import 'l10n/generated/app_localizations.dart';
import 'recorder_controller.dart';
import 'settings.dart';
import 'settings_screen.dart';

String warningText(AppLocalizations l10n, String? warning) => switch (warning) {
  'low_storage' => l10n.warningLowStorage,
  'storage_error' => l10n.warningStorageError,
  'camera_error' => l10n.warningCameraError,
  'recorder_error' => l10n.warningRecorderError,
  _ => l10n.warningGeneric,
};

class RecordScreen extends StatefulWidget {
  const RecordScreen({
    super.key,
    required this.settings,
    required this.recorder,
  });

  final SettingsController settings;
  final RecorderController recorder;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen>
    with WidgetsBindingObserver {
  bool _booting = true;
  bool _starting = false;
  bool _cameraDenied = false;
  bool _browsingLibrary = false;
  Capabilities _capabilities = Capabilities.optimistic;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_browsingLibrary) {
      unawaited(_onResumed());
    }
  }

  Future<void> _onResumed() async {
    if (_cameraDenied) {
      if (!await Permission.camera.isGranted) return;
      if (!mounted) return;
      setState(() => _cameraDenied = false);
      await _bootstrap();
      return;
    }
    try {
      final status = await widget.recorder.sync();
      if (!_booting && status.state == 'idle') {
        await widget.recorder.startPreview(widget.settings.settings);
      }
    } catch (_) {
      // The next resume retries; the banner carries the visible error.
    }
  }

  Future<void> _bootstrap() async {
    final l10n = AppLocalizations.of(context);
    if (_starting) return;
    _starting = true;
    if (mounted) setState(() => _booting = true);
    try {
      final statuses = await [
        Permission.camera,
        Permission.notification,
      ].request();
      final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
      final notificationGranted =
          statuses[Permission.notification]?.isGranted ?? true;
      if (!mounted) return;
      setState(() => _cameraDenied = !cameraGranted);
      if (!cameraGranted) return;

      await widget.recorder.init();
      final storedUri = widget.settings.settings.storageUri;
      if (storedUri != null) {
        try {
          await widget.recorder.setStorageFolder(storedUri);
        } on RecorderException {
          // The folder is gone: stop showing it as the destination.
          await widget.settings.update(
            widget.settings.settings.copyWith(clearStorage: true),
          );
        }
      }
      final capabilities = await widget.recorder.getCapabilities();
      if (!mounted) return;
      setState(() => _capabilities = capabilities);

      final current = widget.settings.settings.normalize(capabilities);
      if (current != widget.settings.settings) {
        await widget.settings.update(current);
      }
      if (!capabilities.hasCamera) return;

      await _applyRetention(current);
      final status = widget.recorder.status;
      if (!status.recording && !status.isBusy) {
        await widget.recorder.startPreview(current);
      }
      if (current.autoCar) {
        await widget.recorder.enableCarMode(current);
      }
      if (!mounted) return;
      if (!notificationGranted) {
        _snack(l10n.notificationsOff);
      }
      unawaited(_maybeAskBattery());
    } on RecorderException catch (error) {
      _snack(error.text(l10n));
    } catch (_) {
      _snack(l10n.couldNotStartCamera);
    } finally {
      _starting = false;
      if (mounted) setState(() => _booting = false);
    }
  }

  Future<void> _applyRetention(Settings settings) async {
    try {
      await widget.recorder.applyRetention(settings.destroyAfterMinutes);
      await widget.recorder.setLanguage(settings.language);
    } on RecorderException {
      // Retention and language are best effort; recording is unaffected.
    }
  }

  Future<void> _maybeAskBattery() async {
    if (widget.settings.settings.batteryPromptShown) return;
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isGranted) {
      await widget.settings.markBatteryPromptShown();
      return;
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final allow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.batteryDialogTitle),
        content: Text(l10n.batteryDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.allow),
          ),
        ],
      ),
    );
    await widget.settings.markBatteryPromptShown();
    if (allow == true) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  Future<void> _toggle() async {
    final l10n = AppLocalizations.of(context);
    final status = widget.recorder.status;
    try {
      if (status.recording) {
        await widget.recorder.stopRecording();
      } else {
        await widget.recorder.startRecording(widget.settings.settings);
      }
    } on RecorderException catch (error) {
      _snack(error.text(l10n));
    }
  }

  Future<void> _openLibrary() async {
    final l10n = AppLocalizations.of(context);
    final status = widget.recorder.status;
    if (status.recording || status.isBusy) return;
    setState(() => _browsingLibrary = true);
    try {
      await widget.recorder.stopPreview();
    } on RecorderException catch (error) {
      if (!mounted) return;
      setState(() => _browsingLibrary = false);
      _snack(error.text(l10n));
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => ClipLibraryScreen(recorder: widget.recorder),
      ),
    );
    if (!mounted) return;
    setState(() => _browsingLibrary = false);
    if (_cameraDenied) return;
    try {
      final next = await widget.recorder.sync();
      if (next.state == 'idle' && !next.recording) {
        await widget.recorder.startPreview(widget.settings.settings);
      }
    } on RecorderException {
      // The record screen's banner and retry path handle a failed restart.
    }
  }

  Future<void> _openSettings() async {
    if (widget.recorder.status.recording) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          initial: widget.settings.settings,
          capabilities: _capabilities,
          onChanged: _applySettings,
          onPickFolder: _pickFolder,
          onUseAppStorage: _useAppStorage,
          onLoadTimeZones: widget.recorder.getTimeZones,
        ),
      ),
    );
  }

  Future<Settings?> _pickFolder() async {
    final l10n = AppLocalizations.of(context);
    try {
      final picked = await widget.recorder.pickStorageFolder();
      if (picked == null) return null;
      final next = widget.settings.settings.copyWith(
        storageUri: picked.uri,
        storageLabel: picked.label,
      );
      await widget.settings.update(next);
      await widget.recorder.setStorageFolder(picked.uri);
      return next;
    } on RecorderException catch (error) {
      _snack(error.text(l10n));
      return null;
    }
  }

  Future<Settings?> _useAppStorage() async {
    final l10n = AppLocalizations.of(context);
    final next = widget.settings.settings.copyWith(clearStorage: true);
    await widget.settings.update(next);
    try {
      await widget.recorder.setStorageFolder(null);
    } on RecorderException catch (error) {
      _snack(error.text(l10n));
    }
    return next;
  }

  Future<void> _applySettings(Settings next) async {
    final l10n = AppLocalizations.of(context);
    final previous = widget.settings.settings;
    await widget.settings.update(next);
    try {
      if (next.autoCar) {
        await widget.recorder.enableCarMode(next);
      } else if (previous.autoCar) {
        await widget.recorder.disableCarMode();
      }
    } on RecorderException catch (error) {
      _snack(error.text(l10n));
    }
    if (next.destroyAfterMinutes != previous.destroyAfterMinutes ||
        next.language != previous.language) {
      await _applyRetention(next);
    }
    final cameraChanged =
        previous.camera != next.camera ||
        previous.resolution != next.resolution ||
        previous.burnTimestamp != next.burnTimestamp ||
        previous.timeZone != next.timeZone;
    if (!cameraChanged || widget.recorder.status.recording) return;
    try {
      await widget.recorder.startPreview(next);
    } on RecorderException catch (error) {
      _snack(error.text(l10n));
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 144),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _booting
          ? const Center(child: CircularProgressIndicator())
          : _cameraDenied
          ? _PermissionPanel(onRetry: _bootstrap)
          : !_capabilities.hasCamera
          ? _NoCameraPanel(onRetry: _bootstrap)
          : Stack(
              fit: StackFit.expand,
              children: [
                AndroidView(viewType: 'reason/preview'),
                ListenableBuilder(
                  listenable: Listenable.merge([
                    widget.recorder,
                    widget.settings,
                  ]),
                  builder: (context, _) => _controls(context),
                ),
              ],
            ),
    );
  }

  Widget _controls(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = widget.recorder.status;
    final Widget top;
    if (status.recording) {
      top = RecordingOverlay(status: status);
    } else if (status.warning != null) {
      top = WarningBanner(warning: status.warning!);
    } else {
      top = const SizedBox.shrink();
    }

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Align(alignment: Alignment.topLeft, child: top),
                ),
                const SizedBox(width: 12),
                _RoundIconButton(
                  icon: Icons.video_library_outlined,
                  tooltip: l10n.clipsTooltip,
                  enabled: !status.recording && !status.isBusy,
                  onPressed: _openLibrary,
                ),
                const SizedBox(width: 8),
                _RoundIconButton(
                  icon: Icons.settings_outlined,
                  tooltip: l10n.settingsTooltip,
                  enabled: !status.recording,
                  onPressed: _openSettings,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            minimum: const EdgeInsets.only(bottom: 32),
            child: Center(
              child: PrimaryRecordButton(
                recording: status.recording,
                busy: status.isBusy,
                onPressed: _toggle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RecordingOverlay extends StatelessWidget {
  const RecordingOverlay({super.key, required this.status});

  final RecorderStatus status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const figures = [FontFeature.tabularFigures()];
    return Semantics(
      label: AppLocalizations.of(context).recordingLabel,
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xB3000000),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (status.state != 'recording') ...[
              Text(
                AppLocalizations.of(context).startingCamera,
                style: textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 6),
            ],
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: status.state == 'recording'
                        ? const Color(0xFFE5484D)
                        : Colors.white38,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatElapsed(status.sessionElapsedMs),
                  style: textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFeatures: figures,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${formatBytes(status.usedBytes)} / '
              '${formatBytes(status.budgetBytes)}',
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white60,
                fontFeatures: figures,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: usedFraction(status.usedBytes, status.budgetBytes),
                minHeight: 4,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Color(0xFFE5484D)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WarningBanner extends StatelessWidget {
  const WarningBanner({super.key, required this.warning});

  final String warning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 18, color: colors.onErrorContainer),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              warningText(AppLocalizations.of(context), warning),
              style: textTheme.bodySmall?.copyWith(
                color: colors.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrimaryRecordButton extends StatelessWidget {
  const PrimaryRecordButton({
    super.key,
    required this.recording,
    required this.busy,
    this.onPressed,
  });

  final bool recording;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // A camera retry keeps `busy` true while recording: stopping must stay possible.
    final spinning = busy && !recording;
    final surface = spinning
        ? const Color(0xFF2A2A2A)
        : recording
        ? const Color(0xFFE5484D)
        : const Color(0xFFF2F1ED);
    final ink = spinning
        ? Colors.white70
        : recording
        ? Colors.white
        : const Color(0xFF141414);
    final ring = recording ? const Color(0xFFE5484D) : Colors.white24;
    final corner = BorderRadius.circular(recording ? 18 : 38);

    return SizedBox(
      width: 104,
      height: 104,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x4D000000),
          border: Border.all(color: ring, width: 2),
        ),
        child: SizedBox(
          width: 72,
          height: 72,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(color: surface, borderRadius: corner),
            child: Tooltip(
              message: recording ? l10n.stopRecording : l10n.startRecording,
              child: FilledButton(
                onPressed: spinning ? null : onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  foregroundColor: ink,
                  disabledForegroundColor: ink,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: corner),
                ),
                child: spinning
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: ink,
                        ),
                      )
                    : Icon(
                        recording
                            ? Icons.stop_rounded
                            : Icons.fiber_manual_record,
                        size: 30,
                        color: ink,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x4D000000),
      shape: const CircleBorder(side: BorderSide(color: Color(0x1FFFFFFF))),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 22),
        color: Colors.white,
        disabledColor: Colors.white30,
        tooltip: tooltip,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _PermissionPanel extends StatelessWidget {
  const _PermissionPanel({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _EmptyPanel(
      icon: Icons.videocam_off_outlined,
      title: l10n.cameraNeededTitle,
      body: l10n.cameraNeededBody,
      primaryLabel: l10n.tryAgain,
      onPrimary: onRetry,
      secondaryLabel: l10n.openSettings,
      onSecondary: () => openAppSettings(),
    );
  }
}

class _NoCameraPanel extends StatelessWidget {
  const _NoCameraPanel({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _EmptyPanel(
      icon: Icons.videocam_outlined,
      title: l10n.noCameraTitle,
      body: l10n.noCameraBody,
      primaryLabel: l10n.checkAgain,
      onPrimary: onRetry,
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
