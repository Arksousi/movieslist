import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/datasources/favorites_local_data_source.dart';
import 'data/datasources/movie_remote_data_source.dart';
import 'data/repositories/favorites_repository_impl.dart';
import 'data/repositories/movie_repository_impl.dart';
import 'domain/usecases/add_favorite.dart';
import 'domain/usecases/get_favorite_movies.dart';
import 'domain/usecases/get_movie_details.dart';
import 'domain/usecases/get_popular_movies.dart';
import 'domain/usecases/remove_favorite.dart';
import 'domain/usecases/search_movies.dart';
import 'presentation/controllers/favorites_controller.dart';
import 'presentation/screens/favorites_screen.dart';
import 'presentation/screens/movies_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Composition root: data layer -> domain layer -> presentation layer.
  final prefs = await SharedPreferences.getInstance();

  final movieRepository = MovieRepositoryImpl(MovieRemoteDataSource());
  final favoritesRepository = FavoritesRepositoryImpl(
    FavoritesLocalDataSource(prefs),
  );

  final favoritesController = FavoritesController(
    GetFavoriteMovies(favoritesRepository),
    AddFavorite(favoritesRepository),
    RemoveFavorite(favoritesRepository),
  );
  await favoritesController.load();

  runApp(
    MyApp(
      getPopularMovies: GetPopularMovies(movieRepository),
      searchMovies: SearchMovies(movieRepository),
      getMovieDetails: GetMovieDetails(movieRepository),
      favoritesController: favoritesController,
    ),
  );
}

class MyApp extends StatelessWidget {
  final GetPopularMovies getPopularMovies;
  final SearchMovies searchMovies;
  final GetMovieDetails getMovieDetails;
  final FavoritesController favoritesController;

  const MyApp({
    super.key,
    required this.getPopularMovies,
    required this.searchMovies,
    required this.getMovieDetails,
    required this.favoritesController,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Popular Movies',
      theme: ThemeData(colorSchemeSeed: Colors.amber, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.amber,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen(
        getPopularMovies: getPopularMovies,
        searchMovies: searchMovies,
        getMovieDetails: getMovieDetails,
        favoritesController: favoritesController,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final GetPopularMovies getPopularMovies;
  final SearchMovies searchMovies;
  final GetMovieDetails getMovieDetails;
  final FavoritesController favoritesController;

  const HomeScreen({
    super.key,
    required this.getPopularMovies,
    required this.searchMovies,
    required this.getMovieDetails,
    required this.favoritesController,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps the movies list (scroll position, loaded pages)
      // alive while the favorites tab is shown.
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          MoviesScreen(
            getPopularMovies: widget.getPopularMovies,
            searchMovies: widget.searchMovies,
            getMovieDetails: widget.getMovieDetails,
            favoritesController: widget.favoritesController,
          ),
          FavoritesScreen(
            favoritesController: widget.favoritesController,
            getMovieDetails: widget.getMovieDetails,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie),
            label: 'Movies',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }
}
