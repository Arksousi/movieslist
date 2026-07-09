import '../entities/movie.dart';
import '../repositories/favorites_repository.dart';

class AddFavorite {
  final FavoritesRepository _repository;

  const AddFavorite(this._repository);

  Future<void> call(Movie movie) => _repository.addFavorite(movie);
}
