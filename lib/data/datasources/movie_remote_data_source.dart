import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../domain/entities/movie_category.dart';
import '../models/movie_category_api.dart';
import '../models/movie_details_model.dart';
import '../models/movie_page_model.dart';

/// Talks to the TMDB REST API. Throws [DioException] on network failures.
class MovieRemoteDataSource {
  final Dio _dio;

  MovieRemoteDataSource({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.themoviedb.org/3',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {
                'Authorization': 'Bearer ${dotenv.env['TMDB_TOKEN']}',
                'Accept': 'application/json',
              },
            ),
          );

  Future<MoviePageModel> fetchCategory({
    required MovieCategory category,
    required int page,
  }) async {
    final response = await _dio.get(
      '/movie/${category.path}',
      queryParameters: {'page': page, 'language': 'en-US'},
    );
    return MoviePageModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MoviePageModel> searchMovies({
    required String query,
    required int page,
  }) async {
    final response = await _dio.get(
      '/search/movie',
      queryParameters: {
        'query': query,
        'page': page,
        'language': 'en-US',
        'include_adult': false,
      },
    );
    return MoviePageModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MovieDetailsModel> fetchDetails(int movieId) async {
    final response = await _dio.get(
      '/movie/$movieId',
      // append_to_response bundles the trailer list into the same request.
      queryParameters: {'language': 'en-US', 'append_to_response': 'videos'},
    );
    return MovieDetailsModel.fromJson(response.data as Map<String, dynamic>);
  }
}
