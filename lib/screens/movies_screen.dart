import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/favorites_service.dart';
import '../services/movie_api_service.dart';
import '../widgets/movie_card.dart';

class MoviesScreen extends StatefulWidget {
  final FavoritesService favoritesService;

  const MoviesScreen({super.key, required this.favoritesService});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final MovieApiService _api = MovieApiService();
  final ScrollController _scrollController = ScrollController();

  final List<Movie> _movies = [];
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNextPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Start fetching a bit before the user actually hits the bottom.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return; // prevents duplicate calls
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final page = await _api.fetchPopular(page: _currentPage + 1);
      if (!mounted) return;
      setState(() {
        _movies.addAll(page.movies);
        _currentPage = page.page;
        _hasMore = page.hasMore;
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

  Future<void> _refresh() async {
    setState(() {
      _movies.clear();
      _currentPage = 0;
      _hasMore = true;
    });
    await _loadNextPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Popular Movies'), centerTitle: true),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_movies.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_movies.isEmpty && _errorMessage != null) {
      return _ErrorView(message: _errorMessage!, onRetry: _loadNextPage);
    }

    if (_movies.isEmpty) {
      return const Center(child: Text('No movies found.'));
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListenableBuilder(
        listenable: widget.favoritesService,
        builder: (context, _) => ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: _movies.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _movies.length) {
              return _buildLoadMoreIndicator();
            }
            return MovieCard(
              movie: _movies[index],
              favoritesService: widget.favoritesService,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              'Failed to load more movies',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton.icon(
              onPressed: _loadNextPage,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
