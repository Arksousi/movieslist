import 'package:flutter/material.dart';

import '../../domain/entities/movie.dart';
import '../../domain/entities/movie_details.dart';
import '../../domain/usecases/get_movie_details.dart';
import '../controllers/favorites_controller.dart';

class MovieDetailsScreen extends StatefulWidget {
  final Movie movie;
  final FavoritesController favoritesController;
  final GetMovieDetails getMovieDetails;

  const MovieDetailsScreen({
    super.key,
    required this.movie,
    required this.favoritesController,
    required this.getMovieDetails,
  });

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  MovieDetails? _details;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final details = await widget.getMovieDetails(widget.movie.id);
      if (!mounted) return;
      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    return Scaffold(
      appBar: AppBar(
        title: Text(movie.title),
        actions: [
          ListenableBuilder(
            listenable: widget.favoritesController,
            builder: (context, _) {
              final isFavorite = widget.favoritesController.isFavorite(
                movie.id,
              );
              return IconButton(
                onPressed: () => widget.favoritesController.toggle(movie),
                tooltip: isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : null,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _Poster(url: movie.posterUrl)),
            const SizedBox(height: 16),
            Text(
              movie.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDetailsSection(),
            const SizedBox(height: 16),
            Text('Overview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              movie.overview.isEmpty
                  ? 'No overview available.'
                  : movie.overview,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    if (_isLoading) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Loading details…'),
        ],
      );
    }

    if (_errorMessage != null) {
      return Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 18,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 6),
          const Expanded(child: Text('Could not load details.')),
          TextButton(onPressed: _loadDetails, child: const Text('Retry')),
        ],
      );
    }

    final details = _details;
    if (details == null) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          avatar: const Icon(Icons.star, size: 18, color: Colors.amber),
          label: Text(details.voteAverage.toStringAsFixed(1)),
        ),
        if (details.releaseYear != null)
          Chip(
            avatar: const Icon(Icons.calendar_today, size: 16),
            label: Text(details.releaseYear!),
          ),
        if (details.runtime != null && details.runtime! > 0)
          Chip(
            avatar: const Icon(Icons.schedule, size: 18),
            label: Text('${details.runtime} min'),
          ),
        for (final genre in details.genres) Chip(label: Text(genre)),
      ],
    );
  }
}

class _Poster extends StatelessWidget {
  final String? url;

  const _Poster({required this.url});

  static const double _width = 220;
  static const double _height = 330;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: _width,
      height: _height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.movie_outlined, size: 48),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: url == null
          ? placeholder
          : Image.network(
              url!,
              width: _width,
              height: _height,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder,
              errorBuilder: (context, error, stackTrace) => placeholder,
            ),
    );
  }
}
