import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import 'format.dart';
import 'l10n/generated/app_localizations.dart';
import 'recorder_controller.dart';

class ClipPlayerScreen extends StatefulWidget {
  const ClipPlayerScreen({super.key, required this.clip});

  final ClipInfo clip;

  @override
  State<ClipPlayerScreen> createState() => _ClipPlayerScreenState();
}

class _ClipPlayerScreenState extends State<ClipPlayerScreen> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final previous = _controller;
    _controller = null;
    if (previous != null) await previous.dispose();
    if (!mounted) return;
    setState(() => _error = null);

    final controller = VideoPlayerController.contentUri(
      Uri.parse(widget.clip.uri),
    );
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _controller = controller);
    try {
      await controller.initialize();
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).couldNotPlayClip);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          formatClipStartFull(
            widget.clip.startEpochMs,
            locale: l10n.localeName,
          ),
          style: theme.textTheme.titleMedium,
        ),
        actions: [
          if (widget.clip.isProtected)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Tooltip(
                message: l10n.protected,
                child: const Icon(Icons.lock_outline, size: 20),
              ),
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _init,
              child: Text(AppLocalizations.of(context).tryAgain),
            ),
          ],
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          _PlayerControls(controller: controller),
        ],
      ),
    );
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return Container(
          color: Colors.black,
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: theme.colorScheme.primary,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white12,
                ),
              ),
              Row(
                children: [
                  IconButton.filled(
                    onPressed: value.isPlaying
                        ? controller.pause
                        : controller.play,
                    icon: Icon(
                      value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF2F1ED),
                      foregroundColor: const Color(0xFF141414),
                      minimumSize: const Size(44, 44),
                    ),
                    tooltip: value.isPlaying
                        ? AppLocalizations.of(context).pause
                        : AppLocalizations.of(context).play,
                  ),
                  const Spacer(),
                  Text(
                    '${formatDuration(value.position.inMilliseconds)} / '
                    '${formatDuration(value.duration.inMilliseconds)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
