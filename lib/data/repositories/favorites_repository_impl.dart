import '../../domain/entities/movie.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_local_data_source.dart';
import '../models/movie_model.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesLocalDataSource _localDataSource;

  const FavoritesRepositoryImpl(this._localDataSource);

  @override
  Future<List<Movie>> getFavorites() => _localDataSource.loadFavorites();

  @override
  Future<void> addFavorite(Movie movie) =>
      _localDataSource.addFavorite(MovieModel.fromEntity(movie));

  @override
  Future<void> removeFavorite(int movieId) =>
      _localDataSource.removeFavorite(movieId);
}
