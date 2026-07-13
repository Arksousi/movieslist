import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/favorites/favorites_cubit.dart';
import '../cubits/favorites/favorites_state.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_grid.dart';
import 'movie_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites'), centerTitle: true),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          final favorites = state.movies;

          if (favorites.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No favorites yet.\nTap the heart on a movie to save it.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: movieGridDelegate(context),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final movie = favorites[index];
              return MovieCard(
                movie: movie,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MovieDetailsScreen(movie: movie),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
