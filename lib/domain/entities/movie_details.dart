/// Extra information about a movie, shown on the details screen.
class MovieDetails {
  final double voteAverage;
  final String? releaseDate;
  final int? runtime;
  final List<String> genres;

  const MovieDetails({
    required this.voteAverage,
    this.releaseDate,
    this.runtime,
    required this.genres,
  });

  String? get releaseYear => (releaseDate == null || releaseDate!.length < 4)
      ? null
      : releaseDate!.substring(0, 4);
}
