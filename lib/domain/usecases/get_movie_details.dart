import '../entities/movie_details.dart';
import '../repositories/movie_repository.dart';

class GetMovieDetails {
  final MovieRepository _repository;

  const GetMovieDetails(this._repository);

  Future<MovieDetails> call(int movieId) => _repository.getDetails(movieId);
}
