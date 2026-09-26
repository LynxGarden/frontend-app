import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';

/// Plays a network video [url] inline in a modal sheet (tap to play/pause).
/// Used for hosted exercise demos (a Supabase signed URL).
Future<void> showVideoPlayerSheet(BuildContext context, String url) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
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
          ..setLooping(true)
          ..play();
      }).catchError((Object e) {
        if (mounted) setState(() => _error = e);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            AspectRatio(
              aspectRatio: _ready ? _controller.value.aspectRatio : 16 / 9,
              child: _error != null
                  ? const Center(
                      child: Icon(Icons.error_outline, color: Colors.white54, size: 40))
                  : !_ready
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : GestureDetector(
                          onTap: _toggle,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(_controller),
                              if (!_controller.value.isPlaying)
                                const Icon(Icons.play_circle_fill,
                                    size: 64, color: Colors.white70),
                            ],
                          ),
                        ),
            ),
            if (_ready)
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(playedColor: AppColors.forest),
              ),
          ],
        ),
      ),
    );
  }
}
