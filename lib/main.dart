import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/di/injector.dart';
import 'presentation/cubits/favorites/favorites_cubit.dart';
import 'presentation/cubits/movies/movies_cubit.dart';
import 'presentation/cubits/settings/settings_cubit.dart';
import 'presentation/screens/favorites_screen.dart';
import 'presentation/screens/movies_screen.dart';
import 'presentation/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initDependencies();
  await sl<FavoritesCubit>().load();
  await sl<SettingsCubit>().load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FavoritesCubit>.value(value: sl<FavoritesCubit>()),
        BlocProvider<SettingsCubit>.value(value: sl<SettingsCubit>()),
        BlocProvider<MoviesCubit>(
          create: (_) => sl<MoviesCubit>()..loadNextPage(),
        ),
      ],
      child: BlocBuilder<SettingsCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp(
          title: 'Popular Movies',
          theme: ThemeData(colorSchemeSeed: Colors.amber, useMaterial3: true),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.amber,
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          themeMode: themeMode,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
        children: const [MoviesScreen(), FavoritesScreen(), SettingsScreen()],
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
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
