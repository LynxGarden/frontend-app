import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/storage/local_storage_service.dart';

/// List vs. grid layout for a browse screen.
enum ViewMode { list, grid }

/// A persisted list/grid toggle, keyed per screen (e.g. 'programs', 'exercises')
/// so each browse surface remembers its own preference across launches.
class ViewModeNotifier extends StateNotifier<ViewMode> {
  ViewModeNotifier(this._prefsKey, {ViewMode fallback = ViewMode.list})
      : super(_read(_prefsKey, fallback));

  final String _prefsKey;

  static ViewMode _read(String key, ViewMode fallback) {
    final saved = LocalStorageService.getString('view_mode_$key');
    if (saved == 'grid') return ViewMode.grid;
    if (saved == 'list') return ViewMode.list;
    return fallback;
  }

  void set(ViewMode mode) {
    if (mode == state) return;
    state = mode;
    LocalStorageService.setString(
        'view_mode_$_prefsKey', mode == ViewMode.grid ? 'grid' : 'list');
  }

  void toggle() =>
      set(state == ViewMode.list ? ViewMode.grid : ViewMode.list);
}

/// Family keyed by a screen id. Default: exercises→grid, everything else→list.
final viewModeProvider =
    StateNotifierProvider.family<ViewModeNotifier, ViewMode, String>(
  (ref, key) => ViewModeNotifier(
    key,
    fallback: key == 'exercises' ? ViewMode.grid : ViewMode.list,
  ),
);
