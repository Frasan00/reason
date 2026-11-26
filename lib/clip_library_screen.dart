import 'package:material_ui/material_ui.dart';

import 'clip_player_screen.dart';
import 'format.dart';
import 'l10n/errors.dart';
import 'l10n/generated/app_localizations.dart';
import 'recorder_controller.dart';

class ClipLibraryScreen extends StatefulWidget {
  const ClipLibraryScreen({super.key, required this.recorder});

  final RecorderController recorder;

  @override
  State<ClipLibraryScreen> createState() => _ClipLibraryScreenState();
}

class _ClipLibraryScreenState extends State<ClipLibraryScreen> {
  List<ClipInfo> _clips = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final clips = await widget.recorder.listClips();
      if (!mounted) return;
      setState(() {
        _clips = clips;
        _loading = false;
      });
    } on RecorderException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.text(l10n);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).couldNotReadClips;
        _loading = false;
      });
    }
  }

  void _play(ClipInfo clip) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (context) => ClipPlayerScreen(clip: clip)),
    );
  }

  Future<void> _share(ClipInfo clip) async {
    final l10n = AppLocalizations.of(context);
    try {
      await widget.recorder.shareClip(clip.name);
    } on RecorderException catch (error) {
      _snack(error.text(l10n));
    }
  }

  Future<void> _delete(ClipInfo clip) async {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteClipTitle),
        content: Text(
          clip.isProtected ? l10n.deleteClipProtectedBody : l10n.deleteClipBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.recorder.deleteClip(clip.name);
      _snack(l10n.clipDeleted);
      await _load();
    } on RecorderException catch (error) {
      _snack(error.text(l10n));
    }
  }

  Future<void> _clearProtection(ClipInfo clip) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearProtectionTitle),
        content: Text(l10n.clearProtectionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.clear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.recorder.clearProtection(clip.name);
      _snack(l10n.protectionCleared);
      await _load();
    } on RecorderException catch (error) {
      _snack(error.text(l10n));
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).clipsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _LibraryError(message: _error!, onRetry: _load)
          : _clips.isEmpty
          ? const _LibraryEmpty()
          : ListView.separated(
              itemCount: _clips.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final clip = _clips[index];
                return ClipRow(
                  clip: clip,
                  onPlay: () => _play(clip),
                  onShare: () => _share(clip),
                  onDelete: () => _delete(clip),
                  onClearProtection: () => _clearProtection(clip),
                );
              },
            ),
    );
  }
}

enum _ClipAction { share, clearProtection, delete }

class ClipRow extends StatelessWidget {
  const ClipRow({
    super.key,
    required this.clip,
    required this.onPlay,
    required this.onShare,
    required this.onDelete,
    required this.onClearProtection,
  });

  final ClipInfo clip;
  final VoidCallback onPlay;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onClearProtection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(color: muted);
    return ListTile(
      onTap: onPlay,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x14FFFFFF),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Icon(Icons.play_arrow_rounded, size: 22, color: muted),
      ),
      title: Text(
        formatClipStart(
          clip.startEpochMs,
          locale: l10n.localeName,
          today: l10n.today,
        ),
      ),
      subtitle: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(formatDuration(clip.durationMs), style: subtitleStyle),
          Text('·', style: subtitleStyle),
          Text(formatBytes(clip.sizeBytes), style: subtitleStyle),
          if (clip.isProtected) ...[
            Text('·', style: subtitleStyle),
            Icon(Icons.lock_outline, size: 14, color: muted),
            Text(l10n.protected, style: subtitleStyle),
          ],
        ],
      ),
      trailing: PopupMenuButton<_ClipAction>(
        tooltip: l10n.clipActions,
        onSelected: (action) => switch (action) {
          _ClipAction.share => onShare(),
          _ClipAction.clearProtection => onClearProtection(),
          _ClipAction.delete => onDelete(),
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: _ClipAction.share, child: Text(l10n.share)),
          if (clip.isProtected)
            PopupMenuItem(
              value: _ClipAction.clearProtection,
              child: Text(l10n.clearProtection),
            ),
          PopupMenuItem(
            value: _ClipAction.delete,
            child: Text(
              l10n.delete,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryEmpty extends StatelessWidget {
  const _LibraryEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.noClipsTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              l10n.noClipsBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
