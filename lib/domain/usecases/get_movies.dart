import '../entities/movie_category.dart';
import '../entities/movie_page.dart';
import '../repositories/movie_repository.dart';

class GetMovies {
  final MovieRepository _repository;

  const GetMovies(this._repository);

  Future<MoviePage> call({
    required MovieCategory category,
    required int page,
  }) => _repository.getMovies(category: category, page: page);
}
