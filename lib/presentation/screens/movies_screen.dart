import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/movie_category.dart';
import '../cubits/movies/movies_cubit.dart';
import '../cubits/movies/movies_state.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_grid.dart';
import '../widgets/skeleton_movie_card.dart';
import 'movie_details_screen.dart';

/// Tab labels for the browsable categories. The TMDB path lives in the data
/// layer; only the wording belongs here.
extension on MovieCategory {
  String get label => switch (this) {
    MovieCategory.popular => 'Popular',
    MovieCategory.topRated => 'Top Rated',
    MovieCategory.nowPlaying => 'Now Playing',
    MovieCategory.upcoming => 'Upcoming',
  };
}

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _tabController = TabController(
      length: MovieCategory.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Switching category abandons any in-progress search and starts the new
  /// list from the top.
  void _onCategorySelected(int index) {
    _searchDebounce?.cancel();
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {}); // hides the search field's clear button
    context.read<MoviesCubit>().setCategory(MovieCategory.values[index]);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _onScroll() {
    // Start fetching a bit before the user actually hits the bottom.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      context.read<MoviesCubit>().loadNextPage();
    }
  }

  void _onSearchChanged(String text) {
    setState(() {}); // updates the clear button
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<MoviesCubit>().setQuery(text);
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {});
    context.read<MoviesCubit>().clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<MoviesCubit, MoviesState>(
          buildWhen: (prev, curr) =>
              prev.isSearching != curr.isSearching ||
              prev.category != curr.category,
          builder: (context, state) => Text(
            state.isSearching ? 'Search Results' : state.category.label,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
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
              TabBar(
                controller: _tabController,
                onTap: _onCategorySelected,
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                tabs: [
                  for (final category in MovieCategory.values)
                    Tab(text: category.label),
                ],
              ),
            ],
          ),
        ),
      ),
      body: BlocBuilder<MoviesCubit, MoviesState>(
        builder: (context, state) => _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MoviesState state) {
    final cubit = context.read<MoviesCubit>();

    if (state.movies.isEmpty && state.isLoading) {
      // Skeleton placeholders while the first page loads.
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: movieGridDelegate(context),
        itemCount: 6,
        itemBuilder: (context, index) => const SkeletonMovieCard(),
      );
    }

    if (state.movies.isEmpty && state.errorMessage != null) {
      return _ErrorView(
        message: state.errorMessage!,
        onRetry: cubit.loadNextPage,
      );
    }

    if (state.movies.isEmpty) {
      return Center(
        child: Text(
          state.isSearching
              ? 'No results for "${state.query}".'
              : 'No movies found.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        gridDelegate: movieGridDelegate(context),
        itemCount: state.movies.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.movies.length) {
            return _LoadMoreIndicator(
              errorMessage: state.errorMessage,
              onRetry: cubit.loadNextPage,
            );
          }
          final movie = state.movies[index];
          return MovieCard(
            movie: movie,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MovieDetailsScreen(movie: movie),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const _LoadMoreIndicator({required this.errorMessage, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              'Failed to load more movies',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton.icon(
              onPressed: onRetry,
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
