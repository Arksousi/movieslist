import 'package:dio/dio.dart';

class Movie {
  final int id;
  final String title;
  final String overview;

  Movie({required this.id, required this.title, required this.overview});

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      overview: json['overview'],
    );
  }
}

class MovieApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
      headers: {
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI3Zjg1N2Q2ZjYxYWE1ZjM5NjZlYTkwMWI2NzY4ZjUyZiIsIm5iZiI6MTc4MzQwODM3OC4wNzIsInN1YiI6IjZhNGNhNmZhMjc1N2MzYjA5NGZkY2FkMiIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.8FsWeVWkDIyyqiVDG-LmUkWFjs7tvT1mtA0Rg1k_UK8',
        'Accept': 'application/json',
      },
    ),
  );

  Future<List> fetchMovies({required int page}) async {
    try {
      final response = await _dio.get(
        '/movie/popular',
        queryParameters: {'page': page, 'language': 'en-US'},
      );
      if (response.statusCode == 200) {
        return response.data['results'];
      } else if (response.statusCode == 401) {
        throw Exception('Invalid Token');
      } else {
        throw Exception('Network Error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}

void main() async {
  try {
    final MovieApiService movieApiService = MovieApiService();
    final List results = await movieApiService.fetchMovies(page: 1);
    for (final js in results) {
      final movie = Movie.fromJson(js);
      print('${movie.id} - ${movie.title}\n${movie.overview}\n');
    }
  } catch (e) {
    print('error on fetching movies $e');
  }
}
