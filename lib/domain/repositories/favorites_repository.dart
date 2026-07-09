import '../entities/movie.dart';

/// Contract for persisting favorite movies. Implemented in the data layer.
abstract class FavoritesRepository {
  Future<List<Movie>> getFavorites();

  Future<void> addFavorite(Movie movie);

  Future<void> removeFavorite(int movieId);
}
