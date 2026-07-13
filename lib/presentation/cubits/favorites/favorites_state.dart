import '../../../domain/entities/movie.dart';

class FavoritesState {
  final Map<int, Movie> favorites;

  const FavoritesState({this.favorites = const {}});

  List<Movie> get movies => favorites.values.toList();

  bool isFavorite(int movieId) => favorites.containsKey(movieId);
}
