import '../../domain/entities/movie_details.dart';

class MovieDetailsModel extends MovieDetails {
  const MovieDetailsModel({
    required super.voteAverage,
    super.releaseDate,
    super.runtime,
    required super.genres,
  });

  factory MovieDetailsModel.fromJson(Map<String, dynamic> json) {
    return MovieDetailsModel(
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
      releaseDate: json['release_date'],
      runtime: json['runtime'],
      genres: ((json['genres'] as List?) ?? const [])
          .map((g) => g['name'] as String)
          .toList(),
    );
  }
}
