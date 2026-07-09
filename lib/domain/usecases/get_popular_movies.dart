import '../entities/movie_page.dart';
import '../repositories/movie_repository.dart';

class GetPopularMovies {
  final MovieRepository _repository;

  const GetPopularMovies(this._repository);

  Future<MoviePage> call({required int page}) =>
      _repository.getPopular(page: page);
}
