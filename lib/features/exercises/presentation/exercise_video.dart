import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/exercises/data/exercise_repository.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/video_player_sheet.dart';

/// Plays an exercise video: a **hosted** clip ([storagePath]) streams inline via
/// a Supabase signed URL; otherwise an external [url] opens in the browser
/// (YouTube/Vimeo links). No-op if neither is set.
Future<void> playExerciseVideo(
  BuildContext context, {
  String? storagePath,
  String? url,
}) async {
  final l = AppLocalizations.of(context);

  if (storagePath != null && storagePath.trim().isNotEmpty) {
    try {
      final signed = await ExerciseRepository.signedVideoUrl(storagePath);
      if (context.mounted) await showVideoPlayerSheet(context, signed);
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message, blur: false);
    }
    return;
  }

  if (url != null && url.trim().isNotEmpty) {
    final uri = Uri.tryParse(url);
    final ok = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppToast.show(context, title: l.couldNotOpenVideo, blur: false);
    }
  }
}
