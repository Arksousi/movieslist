import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Creates and opens the app's SQLite database.
///
/// One shared `movies` table backs both features: `favorites` and
/// `page_cache` reference it by id instead of duplicating movie JSON.
class AppDatabase {
  static const _fileName = 'movies.db';
  // v2: movie_details gained trailer_key.
  // v3: added the settings key/value table (theme mode, etc.).
  static const _version = 3;

  static Future<Database> open() async {
    return openDatabase(
      p.join(await getDatabasesPath(), _fileName),
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE movies (
            id           INTEGER PRIMARY KEY,
            title        TEXT NOT NULL,
            overview     TEXT NOT NULL,
            poster_path  TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE favorites (
            movie_id  INTEGER PRIMARY KEY REFERENCES movies(id),
            added_at  INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE page_cache (
            cache_key    TEXT    NOT NULL,
            position     INTEGER NOT NULL,
            movie_id     INTEGER NOT NULL REFERENCES movies(id),
            page         INTEGER NOT NULL,
            total_pages  INTEGER NOT NULL,
            PRIMARY KEY (cache_key, position)
          )
        ''');
        await db.execute('''
          CREATE TABLE movie_details (
            movie_id      INTEGER PRIMARY KEY,
            vote_average  REAL NOT NULL,
            release_date  TEXT,
            runtime       INTEGER,
            genres        TEXT NOT NULL,
            trailer_key   TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE settings (
            key    TEXT PRIMARY KEY,
            value  TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Existing installs keep their data; new columns/tables are added in place.
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE movie_details ADD COLUMN trailer_key TEXT',
          );
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE settings (
              key    TEXT PRIMARY KEY,
              value  TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }
}
