import '../../domain/entities/movie_details.dart';

class MovieDetailsModel extends MovieDetails {
  const MovieDetailsModel({
    required super.voteAverage,
    super.releaseDate,
    super.runtime,
    required super.genres,
    super.trailerKey,
  });

  factory MovieDetailsModel.fromJson(Map<String, dynamic> json) {
    return MovieDetailsModel(
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
      releaseDate: json['release_date'],
      runtime: json['runtime'],
      genres: ((json['genres'] as List?) ?? const [])
          .map((g) => g['name'] as String)
          .toList(),
      trailerKey: _extractTrailerKey(json),
    );
  }

  /// Picks the best YouTube video from the `videos` block that
  /// `append_to_response=videos` adds: an official Trailer if there is one,
  /// otherwise any YouTube video (e.g. a Teaser).
  static String? _extractTrailerKey(Map<String, dynamic> json) {
    final results = (json['videos']?['results'] as List?) ?? const [];
    final youtubeVideos = results
        .cast<Map<String, dynamic>>()
        .where((v) => v['site'] == 'YouTube')
        .toList();
    if (youtubeVideos.isEmpty) return null;
    final trailer = youtubeVideos.firstWhere(
      (v) => v['type'] == 'Trailer',
      orElse: () => youtubeVideos.first,
    );
    return trailer['key'] as String?;
  }
}
