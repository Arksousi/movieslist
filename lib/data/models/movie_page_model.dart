import '../../domain/entities/movie_page.dart';
import 'movie_model.dart';

class MoviePageModel extends MoviePage {
  const MoviePageModel({
    required super.movies,
    required super.page,
    required super.totalPages,
  });

  factory MoviePageModel.fromJson(Map<String, dynamic> json) {
    return MoviePageModel(
      movies: (json['results'] as List)
          .map((js) => MovieModel.fromJson(js))
          .toList(),
      page: json['page'],
      totalPages: json['total_pages'],
    );
  }
}
