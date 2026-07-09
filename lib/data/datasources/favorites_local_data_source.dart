import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/movie_model.dart';

/// Persists the favorites list as a JSON string in SharedPreferences.
class FavoritesLocalDataSource {
  static const _prefsKey = 'favorite_movies';

  final SharedPreferences _prefs;

  FavoritesLocalDataSource(this._prefs);

  List<MovieModel> loadFavorites() {
    final raw = _prefs.getString(_prefsKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((js) => MovieModel.fromJson(js as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFavorites(List<MovieModel> movies) async {
    await _prefs.setString(
      _prefsKey,
      jsonEncode(movies.map((m) => m.toJson()).toList()),
    );
  }
}
