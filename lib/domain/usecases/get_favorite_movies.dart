import '../entities/movie.dart';
import '../repositories/favorites_repository.dart';

class GetFavoriteMovies {
  final FavoritesRepository _repository;

  const GetFavoriteMovies(this._repository);

  Future<List<Movie>> call() => _repository.getFavorites();
}
