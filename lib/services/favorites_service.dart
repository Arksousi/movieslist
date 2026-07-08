import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/movie.dart';

/// Holds the favorite movies in memory and persists them as a JSON list
/// in SharedPreferences, so favorites survive app restarts.
class FavoritesService extends ChangeNotifier {
  static const _prefsKey = 'favorite_movies';

  final SharedPreferences _prefs;
  final Map<int, Movie> _favorites;

  FavoritesService(this._prefs) : _favorites = _load(_prefs);

  static Map<int, Movie> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return {};
    try {
      final list = (jsonDecode(raw) as List)
          .map((js) => Movie.fromJson(js as Map<String, dynamic>));
      return {for (final movie in list) movie.id: movie};
    } catch (_) {
      return {};
    }
  }

  List<Movie> get favorites => _favorites.values.toList();

  bool isFavorite(int movieId) => _favorites.containsKey(movieId);

  Future<void> toggle(Movie movie) async {
    if (_favorites.containsKey(movie.id)) {
      _favorites.remove(movie.id);
    } else {
      _favorites[movie.id] = movie;
    }
    notifyListeners();
    await _prefs.setString(
      _prefsKey,
      jsonEncode(_favorites.values.map((m) => m.toJson()).toList()),
    );
  }
}
