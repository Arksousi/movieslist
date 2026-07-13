import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/get_movie_details.dart';
import 'movie_details_state.dart';

class MovieDetailsCubit extends Cubit<MovieDetailsState> {
  final GetMovieDetails _getMovieDetails;

  MovieDetailsCubit(this._getMovieDetails) : super(const DetailsLoading());

  Future<void> load(int movieId) async {
    emit(const DetailsLoading());
    try {
      final details = await _getMovieDetails(movieId);
      if (isClosed) return;
      emit(DetailsLoaded(details));
    } catch (e) {
      if (isClosed) return;
      emit(DetailsError(e.toString()));
    }
  }
}
