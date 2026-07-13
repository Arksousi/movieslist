import 'package:sqflite/sqflite.dart';

/// Persists simple app preferences as key/value rows in SQLite.
class SettingsLocalDataSource {
  final Database _db;

  SettingsLocalDataSource(this._db);

  static const _themeKey = 'theme_mode';

  /// Returns the stored theme mode name ('system' | 'light' | 'dark'),
  /// or null if the user hasn't chosen one yet.
  Future<String?> getThemeMode() async {
    final rows = await _db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_themeKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> setThemeMode(String value) async {
    await _db.insert('settings', {
      'key': _themeKey,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
