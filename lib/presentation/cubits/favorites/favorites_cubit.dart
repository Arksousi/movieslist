import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/movie.dart';
import '../../../domain/usecases/add_favorite.dart';
import '../../../domain/usecases/get_favorite_movies.dart';
import '../../../domain/usecases/remove_favorite.dart';
import 'favorites_state.dart';

/// App-wide favorites state, shared by every screen.
class FavoritesCubit extends Cubit<FavoritesState> {
  final GetFavoriteMovies _getFavoriteMovies;
  final AddFavorite _addFavorite;
  final RemoveFavorite _removeFavorite;

  FavoritesCubit(
    this._getFavoriteMovies,
    this._addFavorite,
    this._removeFavorite,
  ) : super(const FavoritesState());

  /// Loads persisted favorites into memory. Call once at startup.
  Future<void> load() async {
    final saved = await _getFavoriteMovies();
    emit(FavoritesState(favorites: {for (final m in saved) m.id: m}));
  }

  Future<void> toggle(Movie movie) async {
    final favorites = Map<int, Movie>.from(state.favorites);
    final isRemoving = favorites.containsKey(movie.id);
    if (isRemoving) {
      favorites.remove(movie.id);
    } else {
      favorites[movie.id] = movie;
    }
    // Emit first so the UI updates instantly; persist afterwards.
    emit(FavoritesState(favorites: favorites));
    if (isRemoving) {
      await _removeFavorite(movie.id);
    } else {
      await _addFavorite(movie);
    }
  }
}
