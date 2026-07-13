import '../../domain/entities/movie_category.dart';

/// Maps a [MovieCategory] to its TMDB identifier.
///
/// The same string is used for the endpoint segment (`/movie/top_rated`) and
/// the SQLite cache-key prefix (`top_rated_1`), so the two can never drift.
extension MovieCategoryApi on MovieCategory {
  String get path => switch (this) {
    MovieCategory.popular => 'popular',
    MovieCategory.topRated => 'top_rated',
    MovieCategory.nowPlaying => 'now_playing',
    MovieCategory.upcoming => 'upcoming',
  };
}
