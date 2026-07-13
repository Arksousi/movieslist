import '../../../domain/entities/movie_details.dart';

sealed class MovieDetailsState {
  const MovieDetailsState();
}

class DetailsLoading extends MovieDetailsState {
  const DetailsLoading();
}

class DetailsLoaded extends MovieDetailsState {
  final MovieDetails details;

  const DetailsLoaded(this.details);
}

class DetailsError extends MovieDetailsState {
  final String message;

  const DetailsError(this.message);
}
