import 'generated/app_localizations.dart';
import '../recorder_controller.dart';

extension RecorderErrorText on RecorderException {
  String text(AppLocalizations l10n) => switch (code) {
    'permission_denied' => l10n.errorCameraPermission,
    'low_storage' => l10n.errorLowStorage,
    'storage_unavailable' || 'storage_error' => l10n.errorStorageUnavailable,
    'foreground_service_failed' => l10n.errorServiceFailed,
    'recording_in_progress' => l10n.errorRecordingInProgress,
    'invalid_args' => l10n.errorInvalidArgs,
    'clip_not_found' => l10n.errorClipNotFound,
    'share_failed' => l10n.errorShareFailed,
    'picker_failed' || 'folder_unavailable' => l10n.errorFolder,
    'picker_busy' => l10n.errorPickerBusy,
    // A native message is English; show the localized fallback instead.
    _ => l10n.errorRecordingFailed,
  };
}
