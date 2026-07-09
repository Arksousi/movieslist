import 'package:flutter/material.dart';

import '../../domain/entities/movie.dart';
import '../../domain/usecases/get_movie_details.dart';
import '../controllers/favorites_controller.dart';
import '../widgets/movie_card.dart';
import 'movie_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final FavoritesController favoritesController;
  final GetMovieDetails getMovieDetails;

  const FavoritesScreen({
    super.key,
    required this.favoritesController,
    required this.getMovieDetails,
  });

  void _openDetails(BuildContext context, Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieDetailsScreen(
          movie: movie,
          favoritesController: favoritesController,
          getMovieDetails: getMovieDetails,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites'), centerTitle: true),
      body: ListenableBuilder(
        listenable: favoritesController,
        builder: (context, _) {
          final favorites = favoritesController.favorites;

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

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final movie = favorites[index];
              return MovieCard(
                movie: movie,
                favoritesController: favoritesController,
                onTap: () => _openDetails(context, movie),
              );
            },
          );
        },
      ),
    );
  }
}
