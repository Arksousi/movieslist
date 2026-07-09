import 'movie.dart';

/// One page of a paginated movie list.
class MoviePage {
  final List<Movie> movies;
  final int page;
  final int totalPages;

  const MoviePage({
    required this.movies,
    required this.page,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;
}
