import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/datasources/favorites_local_data_source.dart';
import '../../data/datasources/movie_local_data_source.dart';
import '../../data/datasources/movie_remote_data_source.dart';
import '../../data/datasources/settings_local_data_source.dart';
import '../../data/repositories/favorites_repository_impl.dart';
import '../../data/repositories/movie_repository_impl.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/repositories/movie_repository.dart';
import '../../domain/usecases/add_favorite.dart';
import '../../domain/usecases/get_favorite_movies.dart';
import '../../domain/usecases/get_movie_details.dart';
import '../../domain/usecases/get_movies.dart';
import '../../domain/usecases/remove_favorite.dart';
import '../../domain/usecases/search_movies.dart';
import '../../presentation/cubits/favorites/favorites_cubit.dart';
import '../../presentation/cubits/movie_details/movie_details_cubit.dart';
import '../../presentation/cubits/movies/movies_cubit.dart';
import '../../presentation/cubits/settings/settings_cubit.dart';
import '../database/app_database.dart';
import '../services/notification_service.dart';

/// Global service locator.
final sl = GetIt.instance;

/// Registers every dependency: data layer -> domain layer -> cubits.
Future<void> initDependencies() async {
  // Guard against double registration if this ever runs twice (e.g. a hot
  // restart that re-enters main without clearing the isolate).
  if (sl.isRegistered<Database>()) return;

  // External — the SQLite database backing favorites and the offline cache.
  sl.registerSingleton<Database>(await AppDatabase.open());

  // Local notifications for "remind me to watch" reminders.
  final notificationService = NotificationService();
  await notificationService.init();
  sl.registerSingleton<NotificationService>(notificationService);

  // Data sources
  sl.registerLazySingleton(() => MovieRemoteDataSource());
  sl.registerLazySingleton(() => MovieLocalDataSource(sl()));
  sl.registerLazySingleton(() => FavoritesLocalDataSource(sl()));
  sl.registerLazySingleton(() => SettingsLocalDataSource(sl()));

  // Repositories (bound to their domain interfaces)
  sl.registerLazySingleton<MovieRepository>(
    () => MovieRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetMovies(sl()));
  sl.registerLazySingleton(() => SearchMovies(sl()));
  sl.registerLazySingleton(() => GetMovieDetails(sl()));
  sl.registerLazySingleton(() => GetFavoriteMovies(sl()));
  sl.registerLazySingleton(() => AddFavorite(sl()));
  sl.registerLazySingleton(() => RemoveFavorite(sl()));

  // Cubits. Favorites is a lazy singleton because its state is shared by
  // every screen; the others are factories (fresh instance per screen).
  sl.registerLazySingleton(() => FavoritesCubit(sl(), sl(), sl()));
  sl.registerLazySingleton(() => SettingsCubit(sl()));
  sl.registerFactory(() => MoviesCubit(sl(), sl()));
  sl.registerFactory(() => MovieDetailsCubit(sl()));
}
