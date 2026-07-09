import 'package:flutter/foundation.dart';

import '../../domain/entities/movie.dart';
import '../../domain/usecases/add_favorite.dart';
import '../../domain/usecases/get_favorite_movies.dart';
import '../../domain/usecases/remove_favorite.dart';

/// Holds the favorites state for the UI and delegates persistence to the
/// domain use cases.
class FavoritesController extends ChangeNotifier {
  final GetFavoriteMovies _getFavoriteMovies;
  final AddFavorite _addFavorite;
  final RemoveFavorite _removeFavorite;

  final Map<int, Movie> _favorites = {};

  FavoritesController(
    this._getFavoriteMovies,
    this._addFavorite,
    this._removeFavorite,
  );

  List<Movie> get favorites => _favorites.values.toList();

  bool isFavorite(int movieId) => _favorites.containsKey(movieId);

  /// Loads persisted favorites into memory. Call once at startup.
  Future<void> load() async {
    final saved = await _getFavoriteMovies();
    _favorites
      ..clear()
      ..addEntries(saved.map((m) => MapEntry(m.id, m)));
    notifyListeners();
  }

  Future<void> toggle(Movie movie) async {
    if (_favorites.containsKey(movie.id)) {
      _favorites.remove(movie.id);
      notifyListeners();
      await _removeFavorite(movie.id);
    } else {
      _favorites[movie.id] = movie;
      notifyListeners();
      await _addFavorite(movie);
    }
  }
}
