import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/l10n/app_localizations.dart';

/// Plays a network video [url] inline in a modal sheet (tap to play/pause).
/// Used for hosted exercise demos (a Supabase signed URL).
Future<void> showVideoPlayerSheet(BuildContext context, String url) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _VideoPlayerView(url: url),
  );
}

class _VideoPlayerView extends StatefulWidget {
  const _VideoPlayerView({required this.url});
  final String url;

  @override
  State<_VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<_VideoPlayerView> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller
          ..addListener(_tick) // keep the scrubber/time labels live
          ..setLooping(true)
          ..play();
      }).catchError((Object e) {
        if (mounted) setState(() => _error = e);
      });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  void _toggle() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  /// Seek [seconds] relative to the current position, clamped to [0, duration].
  void _seekBy(int seconds) {
    final target = _controller.value.position + Duration(seconds: seconds);
    final duration = _controller.value.duration;
    _controller.seekTo(
      target < Duration.zero
          ? Duration.zero
          : (target > duration ? duration : target),
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // Cap the sheet height so a portrait / tall clip fits: the video takes the
    // space left between the fixed close button and the progress bar (Expanded +
    // Center), scaling within it via AspectRatio instead of forcing its own
    // height from the full sheet width (which overflowed).
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            children: [
              // Header: title + circular close button (app nav-bar style).
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).demoVideo,
                      style: AppTextStyles.heading3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Stop playback immediately, then close (dispose() also
                      // tears the controller down for back-gesture / drag close).
                      if (_ready) _controller.pause();
                      Navigator.of(context).maybePop();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Icon(Icons.close,
                          size: 20, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // A consistent black "stage" fills the available area in BOTH
              // states: the spinner (loading) and the letterboxed clip (loaded)
              // sit centered in the same footprint, so nothing jumps on load.
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    width: double.infinity,
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: _error != null
                        ? Icon(Icons.error_outline,
                            color: AppColors.textTertiary, size: 40)
                        : !_ready
                            ? CircularProgressIndicator(color: AppColors.primary)
                            : GestureDetector(
                                onTap: _toggle,
                                child: AspectRatio(
                                  aspectRatio: _controller.value.aspectRatio,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      VideoPlayer(_controller),
                                      if (!_controller.value.isPlaying)
                                        Icon(Icons.play_circle_fill,
                                            size: 64,
                                            color: AppColors.onPrimary
                                                .withValues(alpha: 0.85)),
                                    ],
                                  ),
                                ),
                              ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Controls render in both states (disabled placeholder while
              // loading) so the layout is identical before and after load.
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    final value = _controller.value;
    final isPlaying = _ready && value.isPlaying;
    final disabledTint = AppColors.textTertiary.withValues(alpha: 0.4);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scrubber with elapsed / total time (00:00 placeholders while loading).
          Row(
            children: [
              Text(_ready ? _fmt(value.position) : '00:00',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: _ready
                      ? VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: AppColors.primary,
                            bufferedColor: AppColors.surfaceBorder,
                            backgroundColor: AppColors.surfaceLight,
                          ),
                        )
                      : Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                ),
              ),
              Text(_ready ? _fmt(value.duration) : '00:00',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Transport: skip back 10s · play/pause · skip forward 10s.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.replay_10,
                    color: _ready ? AppColors.textPrimary : disabledTint),
                iconSize: 30,
                onPressed: _ready ? () => _seekBy(-10) : null,
              ),
              const SizedBox(width: AppSpacing.lg),
              IconButton(
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: _ready ? AppColors.primary : disabledTint,
                ),
                iconSize: 52,
                onPressed: _ready ? _toggle : null,
              ),
              const SizedBox(width: AppSpacing.lg),
              IconButton(
                icon: Icon(Icons.forward_10,
                    color: _ready ? AppColors.textPrimary : disabledTint),
                iconSize: 30,
                onPressed: _ready ? () => _seekBy(10) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
