import '../../domain/entities/movie.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_local_data_source.dart';
import '../models/movie_model.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesLocalDataSource _localDataSource;

  const FavoritesRepositoryImpl(this._localDataSource);

  @override
  Future<List<Movie>> getFavorites() async => _localDataSource.loadFavorites();

  @override
  Future<void> addFavorite(Movie movie) async {
    final favorites = _localDataSource.loadFavorites();
    if (favorites.any((m) => m.id == movie.id)) return;
    favorites.add(MovieModel.fromEntity(movie));
    await _localDataSource.saveFavorites(favorites);
  }

  @override
  Future<void> removeFavorite(int movieId) async {
    final favorites = _localDataSource.loadFavorites();
    favorites.removeWhere((m) => m.id == movieId);
    await _localDataSource.saveFavorites(favorites);
  }
}
