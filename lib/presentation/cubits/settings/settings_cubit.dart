import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/settings_local_data_source.dart';

/// Holds app-wide preferences. Currently just the theme mode, persisted in
/// SQLite so the choice survives restarts.
class SettingsCubit extends Cubit<ThemeMode> {
  final SettingsLocalDataSource _dataSource;

  SettingsCubit(this._dataSource) : super(ThemeMode.system);

  /// Loads the persisted theme mode into memory. Call once at startup.
  Future<void> load() async {
    final saved = await _dataSource.getThemeMode();
    emit(_parse(saved));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == state) return;
    emit(mode); // update the UI instantly, then persist.
    await _dataSource.setThemeMode(mode.name);
  }

  ThemeMode _parse(String? name) => switch (name) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
