/// Core business object of the app. Pure Dart — no JSON, no framework code.
class Movie {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;

  const Movie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
  });

  String? get posterUrl =>
      posterPath == null ? null : 'https://image.tmdb.org/t/p/w500$posterPath';
}
