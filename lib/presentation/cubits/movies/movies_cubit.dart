import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/movie_category.dart';
import '../../../domain/usecases/get_movies.dart';
import '../../../domain/usecases/search_movies.dart';
import 'movies_state.dart';

/// Pagination, category and search state for the movie list.
class MoviesCubit extends Cubit<MoviesState> {
  final GetMovies _getMovies;
  final SearchMovies _searchMovies;

  // Incremented whenever the list is reset (new search, new category, refresh)
  // so that responses from stale in-flight requests can be discarded.
  int _generation = 0;

  MoviesCubit(this._getMovies, this._searchMovies) : super(const MoviesState());

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return; // prevents duplicate calls
    final generation = _generation;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final page = state.query.isEmpty
          ? await _getMovies(
              category: state.category,
              page: state.currentPage + 1,
            )
          : await _searchMovies(
              query: state.query,
              page: state.currentPage + 1,
            );
      if (generation != _generation || isClosed) return;
      emit(
        state.copyWith(
          movies: [...state.movies, ...page.movies],
          currentPage: page.page,
          hasMore: page.hasMore,
          isLoading: false,
        ),
      );
    } catch (e) {
      if (generation != _generation || isClosed) return;
      emit(state.copyWith(errorMessage: e.toString(), isLoading: false));
    }
  }

  Future<void> setQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed == state.query) return;
    await _reset(query: trimmed, category: state.category);
  }

  /// Switches the browsed category, dropping any active search.
  Future<void> setCategory(MovieCategory category) async {
    if (category == state.category && !state.isSearching) return;
    await _reset(query: '', category: category);
  }

  Future<void> clearSearch() => setQuery('');

  Future<void> refresh() => _reset(query: state.query, category: state.category);

  Future<void> _reset({
    required String query,
    required MovieCategory category,
  }) async {
    _generation++;
    emit(MoviesState(query: query, category: category));
    await loadNextPage();
  }
}
