import 'package:sqflite/sqflite.dart';

import '../models/movie_model.dart';

/// Persists favorites in SQLite: a `favorites` table referencing the shared
/// `movies` table, so favorites survive app restarts.
class FavoritesLocalDataSource {
  final Database _db;

  FavoritesLocalDataSource(this._db);

  Future<List<MovieModel>> loadFavorites() async {
    final rows = await _db.rawQuery('''
      SELECT m.id, m.title, m.overview, m.poster_path
      FROM favorites f
      JOIN movies m ON m.id = f.movie_id
      ORDER BY f.added_at
    ''');
    // Column names match the TMDB JSON keys, so fromJson parses a DB row too.
    return rows.map(MovieModel.fromJson).toList();
  }

  Future<void> addFavorite(MovieModel movie) async {
    await _db.transaction((txn) async {
      await txn.insert(
        'movies',
        movie.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert('favorites', {
        'movie_id': movie.id,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> removeFavorite(int movieId) async {
    await _db.delete('favorites', where: 'movie_id = ?', whereArgs: [movieId]);
  }
}
