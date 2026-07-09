import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/movie.dart';
import '../../domain/usecases/get_movie_details.dart';
import '../../domain/usecases/get_popular_movies.dart';
import '../../domain/usecases/search_movies.dart';
import '../controllers/favorites_controller.dart';
import '../widgets/movie_card.dart';
import '../widgets/skeleton_movie_card.dart';
import 'movie_details_screen.dart';

class MoviesScreen extends StatefulWidget {
  final GetPopularMovies getPopularMovies;
  final SearchMovies searchMovies;
  final GetMovieDetails getMovieDetails;
  final FavoritesController favoritesController;

  const MoviesScreen({
    super.key,
    required this.getPopularMovies,
    required this.searchMovies,
    required this.getMovieDetails,
    required this.favoritesController,
  });

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  final List<Movie> _movies = [];
  String _query = '';
  // Incremented whenever the list is reset (new search, refresh) so that
  // responses from stale in-flight requests can be discarded.
  int _generation = 0;
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
    _searchDebounce?.cancel();
    _searchController.dispose();
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

  void _onSearchChanged(String text) {
    setState(() {}); // updates the clear button
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final query = text.trim();
      if (query == _query) return;
      _query = query;
      _resetAndLoad();
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    if (_query.isEmpty) {
      setState(() {});
      return;
    }
    _query = '';
    _resetAndLoad();
  }

  Future<void> _resetAndLoad() async {
    setState(() {
      _generation++;
      _movies.clear();
      _currentPage = 0;
      _hasMore = true;
      _isLoading = false;
      _errorMessage = null;
    });
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return; // prevents duplicate calls
    final generation = _generation;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final page = _query.isEmpty
          ? await widget.getPopularMovies(page: _currentPage + 1)
          : await widget.searchMovies(query: _query, page: _currentPage + 1);
      if (!mounted || generation != _generation) return;
      setState(() {
        _movies.addAll(page.movies);
        _currentPage = page.page;
        _hasMore = page.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openDetails(Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieDetailsScreen(
          movie: movie,
          favoritesController: widget.favoritesController,
          getMovieDetails: widget.getMovieDetails,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_query.isEmpty ? 'Popular Movies' : 'Search Results'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search movies…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear search',
                        onPressed: _clearSearch,
                      ),
                filled: true,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_movies.isEmpty && _isLoading) {
      // Skeleton placeholders while the first page loads.
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 6,
        itemBuilder: (context, index) => const SkeletonMovieCard(),
      );
    }

    if (_movies.isEmpty && _errorMessage != null) {
      return _ErrorView(message: _errorMessage!, onRetry: _loadNextPage);
    }

    if (_movies.isEmpty) {
      return Center(
        child: Text(
          _query.isEmpty ? 'No movies found.' : 'No results for "$_query".',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _resetAndLoad,
      child: ListenableBuilder(
        listenable: widget.favoritesController,
        builder: (context, _) => ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: _movies.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _movies.length) {
              return _buildLoadMoreIndicator();
            }
            final movie = _movies[index];
            return MovieCard(
              movie: movie,
              favoritesController: widget.favoritesController,
              onTap: () => _openDetails(movie),
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
