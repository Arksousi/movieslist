import '../entities/movie_details.dart';
import '../entities/movie_page.dart';

/// Contract for fetching movies. Implemented in the data layer.
abstract class MovieRepository {
  Future<MoviePage> getPopular({required int page});

  Future<MoviePage> search({required String query, required int page});

  Future<MovieDetails> getDetails(int movieId);
}
