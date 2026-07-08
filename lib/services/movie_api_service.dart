import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/movie.dart';

class MoviePage {
  final List<Movie> movies;
  final int page;
  final int totalPages;

  MoviePage({required this.movies, required this.page, required this.totalPages});

  bool get hasMore => page < totalPages;
}

class MovieApiService {
  final Dio _dio = Dio(
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

  Future<MoviePage> fetchPopular({required int page}) async {
    try {
      final response = await _dio.get(
        '/movie/popular',
        queryParameters: {'page': page, 'language': 'en-US'},
      );
      final data = response.data as Map<String, dynamic>;
      return MoviePage(
        movies: (data['results'] as List)
            .map((js) => Movie.fromJson(js))
            .toList(),
        page: data['page'],
        totalPages: data['total_pages'],
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid TMDB token');
      }
      throw Exception('Network error: ${e.message}');
    }
  }
}
