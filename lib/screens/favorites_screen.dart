import 'package:flutter/material.dart';

import '../services/favorites_service.dart';
import '../widgets/movie_card.dart';

class FavoritesScreen extends StatelessWidget {
  final FavoritesService favoritesService;

  const FavoritesScreen({super.key, required this.favoritesService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites'), centerTitle: true),
      body: ListenableBuilder(
        listenable: favoritesService,
        builder: (context, _) {
          final favorites = favoritesService.favorites;

          if (favorites.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No favorites yet.\nTap the heart on a movie to save it.',
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: favorites.length,
            itemBuilder: (context, index) => MovieCard(
              movie: favorites[index],
              favoritesService: favoritesService,
            ),
          );
        },
      ),
    );
  }
}
