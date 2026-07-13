import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/movie_details_model.dart';
import '../models/movie_model.dart';
import '../models/movie_page_model.dart';

/// SQLite cache for API responses, so the app keeps working when the
/// network is unavailable. Pages are stored as ordered references into the
/// shared `movies` table; details get their own table.
class MovieLocalDataSource {
  final Database _db;

  MovieLocalDataSource(this._db);

  /// [prefix] identifies the list being cached — a category path ('popular',
  /// 'top_rated', …) or `search_<query>`. Each list therefore caches, and is
  /// served offline, independently.
  String _pageKey(String prefix, int page) => '${prefix}_$page';

  Future<void> cachePage(String prefix, int page, MoviePageModel data) async {
    final key = _pageKey(prefix, page);
    await _db.transaction((txn) async {
      await txn.delete('page_cache', where: 'cache_key = ?', whereArgs: [key]);
      for (var i = 0; i < data.movies.length; i++) {
        final movie = MovieModel.fromEntity(data.movies[i]);
        await txn.insert(
          'movies',
          movie.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await txn.insert('page_cache', {
          'cache_key': key,
          'position': i,
          'movie_id': movie.id,
          'page': data.page,
          'total_pages': data.totalPages,
        });
      }
    });
  }

  Future<MoviePageModel?> getCachedPage(String prefix, int page) async {
    final rows = await _db.rawQuery(
      '''
      SELECT m.id, m.title, m.overview, m.poster_path,
             c.page, c.total_pages
      FROM page_cache c
      JOIN movies m ON m.id = c.movie_id
      WHERE c.cache_key = ?
      ORDER BY c.position
    ''',
      [_pageKey(prefix, page)],
    );
    if (rows.isEmpty) return null;
    return MoviePageModel(
      movies: rows.map(MovieModel.fromJson).toList(),
      page: rows.first['page'] as int,
      totalPages: rows.first['total_pages'] as int,
    );
  }

  Future<void> cacheDetails(int movieId, MovieDetailsModel data) async {
    await _db.insert('movie_details', {
      'movie_id': movieId,
      'vote_average': data.voteAverage,
      'release_date': data.releaseDate,
      'runtime': data.runtime,
      'genres': jsonEncode(data.genres),
      'trailer_key': data.trailerKey,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<MovieDetailsModel?> getCachedDetails(int movieId) async {
    final rows = await _db.query(
      'movie_details',
      where: 'movie_id = ?',
      whereArgs: [movieId],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return MovieDetailsModel(
      voteAverage: row['vote_average'] as double,
      releaseDate: row['release_date'] as String?,
      runtime: row['runtime'] as int?,
      genres: (jsonDecode(row['genres'] as String) as List).cast<String>(),
      trailerKey: row['trailer_key'] as String?,
    );
  }
}
