import '../entities/movie_page.dart';
import '../repositories/movie_repository.dart';

class SearchMovies {
  final MovieRepository _repository;

  const SearchMovies(this._repository);

  Future<MoviePage> call({required String query, required int page}) =>
      _repository.search(query: query, page: page);
}
