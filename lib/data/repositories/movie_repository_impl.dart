import 'package:dio/dio.dart';

import '../../domain/entities/movie_category.dart';
import '../../domain/entities/movie_details.dart';
import '../../domain/entities/movie_page.dart';
import '../../domain/repositories/movie_repository.dart';
import '../datasources/movie_local_data_source.dart';
import '../datasources/movie_remote_data_source.dart';
import '../models/movie_category_api.dart';
import '../models/movie_page_model.dart';

/// Network-first with local-database fallback: successful responses are
/// cached in SQLite; when the network fails, previously cached data is
/// served so the app keeps working offline.
class MovieRepositoryImpl implements MovieRepository {
  final MovieRemoteDataSource _remoteDataSource;
  final MovieLocalDataSource _localDataSource;

  const MovieRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<MoviePage> getMovies({
    required MovieCategory category,
    required int page,
  }) => _pageWithCache(
    cacheKey: category.path,
    page: page,
    fetch: () => _remoteDataSource.fetchCategory(category: category, page: page),
  );

  @override
  Future<MoviePage> search({required String query, required int page}) =>
      _pageWithCache(
        cacheKey: 'search_${query.toLowerCase()}',
        page: page,
        fetch: () => _remoteDataSource.searchMovies(query: query, page: page),
      );

  @override
  Future<MovieDetails> getDetails(int movieId) async {
    try {
      final details = await _remoteDataSource.fetchDetails(movieId);
      await _localDataSource.cacheDetails(movieId, details);
      return details;
    } on DioException catch (e) {
      final cached = await _localDataSource.getCachedDetails(movieId);
      if (cached != null) return cached;
      _throwFriendly(e);
    }
  }

  /// [cacheKey] namespaces the cached rows, so every category and every search
  /// term is cached — and served back offline — independently of the others.
  Future<MoviePage> _pageWithCache({
    required String cacheKey,
    required int page,
    required Future<MoviePageModel> Function() fetch,
  }) async {
    try {
      final result = await fetch();
      await _localDataSource.cachePage(cacheKey, page, result);
      return result;
    } on DioException catch (e) {
      final cached = await _localDataSource.getCachedPage(cacheKey, page);
      if (cached != null) return cached;
      _throwFriendly(e);
    }
  }

  /// Maps transport-level errors to messages the presentation layer can show.
  Never _throwFriendly(DioException e) {
    if (e.response?.statusCode == 401) {
      throw Exception('Invalid TMDB token');
    }
    throw Exception(
      'No internet connection and no cached data available.\n(${e.message})',
    );
  }
}
