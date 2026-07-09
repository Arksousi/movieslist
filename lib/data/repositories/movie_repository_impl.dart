import 'package:dio/dio.dart';

import '../../domain/entities/movie_details.dart';
import '../../domain/entities/movie_page.dart';
import '../../domain/repositories/movie_repository.dart';
import '../datasources/movie_remote_data_source.dart';

class MovieRepositoryImpl implements MovieRepository {
  final MovieRemoteDataSource _remoteDataSource;

  const MovieRepositoryImpl(this._remoteDataSource);

  @override
  Future<MoviePage> getPopular({required int page}) =>
      _guard(() => _remoteDataSource.fetchPopular(page: page));

  @override
  Future<MoviePage> search({required String query, required int page}) =>
      _guard(() => _remoteDataSource.searchMovies(query: query, page: page));

  @override
  Future<MovieDetails> getDetails(int movieId) =>
      _guard(() => _remoteDataSource.fetchDetails(movieId));

  /// Maps transport-level errors to messages the presentation layer can show.
  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid TMDB token');
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}
