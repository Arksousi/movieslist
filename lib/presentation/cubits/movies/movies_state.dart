import '../../../domain/entities/movie.dart';
import '../../../domain/entities/movie_category.dart';

class MoviesState {
  final List<Movie> movies;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final String? errorMessage;
  final String query;

  /// The category being browsed. Ignored while [isSearching].
  final MovieCategory category;

  const MoviesState({
    this.movies = const [],
    this.currentPage = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.errorMessage,
    this.query = '',
    this.category = MovieCategory.popular,
  });

  bool get isSearching => query.isNotEmpty;

  MoviesState copyWith({
    List<Movie>? movies,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    // Nullable field: use a sentinel so copyWith can also clear it.
    Object? errorMessage = _unset,
    String? query,
    MovieCategory? category,
  }) {
    return MoviesState(
      movies: movies ?? this.movies,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      query: query ?? this.query,
      category: category ?? this.category,
    );
  }

  static const _unset = Object();
}
