import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../core/di/injector.dart';
import '../../core/services/notification_service.dart';
import '../../domain/entities/movie.dart';
import '../cubits/favorites/favorites_cubit.dart';
import '../cubits/movie_details/movie_details_cubit.dart';
import '../cubits/movie_details/movie_details_state.dart';

class MovieDetailsScreen extends StatelessWidget {
  final Movie movie;

  const MovieDetailsScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MovieDetailsCubit>()..load(movie.id),
      child: Scaffold(
        appBar: AppBar(
          title: Text(movie.title),
          actions: [
            _FavoriteAction(movie: movie),
            _DetailsMenu(movie: movie),
          ],
        ),
        body: OrientationBuilder(
          builder: (context, orientation) {
            // Landscape: poster on the left, info beside it, so the wide
            // screen isn't wasted. Portrait: poster on top, info below.
            if (orientation == Orientation.landscape) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Poster(url: movie.posterUrl),
                    const SizedBox(width: 16),
                    Expanded(child: _MovieInfo(movie: movie)),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _Poster(url: movie.posterUrl)),
                  const SizedBox(height: 16),
                  _MovieInfo(movie: movie),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Title, detail chips and overview — shared by both orientations.
class _MovieInfo extends StatelessWidget {
  final Movie movie;

  const _MovieInfo({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movie.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _DetailsSection(movieId: movie.id),
        const SizedBox(height: 16),
        Text('Overview', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          movie.overview.isEmpty ? 'No overview available.' : movie.overview,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const _TrailerSection(),
      ],
    );
  }
}

/// Embedded YouTube trailer, shown once details are loaded and only when
/// the movie actually has one.
class _TrailerSection extends StatelessWidget {
  const _TrailerSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MovieDetailsCubit, MovieDetailsState>(
      builder: (context, state) {
        if (state case DetailsLoaded(
          :final details,
        ) when details.trailerKey != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Trailer', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _TrailerPlayer(
                  // New key forces a fresh player if another movie loads.
                  key: ValueKey(details.trailerKey),
                  videoId: details.trailerKey!,
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _TrailerPlayer extends StatefulWidget {
  final String videoId;

  const _TrailerPlayer({super.key, required this.videoId});

  @override
  State<_TrailerPlayer> createState() => _TrailerPlayerState();
}

class _TrailerPlayerState extends State<_TrailerPlayer> {
  late final YoutubePlayerController _controller =
      YoutubePlayerController.fromVideoId(
        videoId: widget.videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(controller: _controller, aspectRatio: 16 / 9);
  }
}

enum _MenuAction { toggleFavorite, remindToWatch }

/// The ⋮ overflow menu in the app bar corner.
class _DetailsMenu extends StatelessWidget {
  final Movie movie;

  const _DetailsMenu({required this.movie});

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.select<FavoritesCubit, bool>(
      (cubit) => cubit.state.isFavorite(movie.id),
    );

    return PopupMenuButton<_MenuAction>(
      tooltip: 'More options',
      onSelected: (action) => switch (action) {
        _MenuAction.toggleFavorite => context.read<FavoritesCubit>().toggle(
          movie,
        ),
        _MenuAction.remindToWatch => _pickReminderTime(context),
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _MenuAction.toggleFavorite,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            title: Text(
              isFavorite ? 'Remove from favorites' : 'Add to favorites',
            ),
          ),
        ),
        const PopupMenuItem(
          value: _MenuAction.remindToWatch,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.alarm),
            title: Text('Remind me to watch'),
          ),
        ),
      ],
    );
  }

  Future<void> _pickReminderTime(BuildContext context) async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'When do you want to watch "${movie.title}"?',
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null || !context.mounted) return;

    final when = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!when.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a time in the future.')),
      );
      return;
    }

    final notifications = sl<NotificationService>();
    final allowed = await notifications.requestPermission();
    if (!context.mounted) return;
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications are disabled for this app.'),
        ),
      );
      return;
    }

    await notifications.scheduleWatchReminder(
      movieId: movie.id,
      movieTitle: movie.title,
      when: when,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reminder set for ${date.day}/${date.month}/${date.year} '
          'at ${time.format(context)} 🎬',
        ),
      ),
    );
  }
}

class _FavoriteAction extends StatelessWidget {
  final Movie movie;

  const _FavoriteAction({required this.movie});

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.select<FavoritesCubit, bool>(
      (cubit) => cubit.state.isFavorite(movie.id),
    );

    return IconButton(
      onPressed: () => context.read<FavoritesCubit>().toggle(movie),
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : null,
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  final int movieId;

  const _DetailsSection({required this.movieId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MovieDetailsCubit, MovieDetailsState>(
      builder: (context, state) {
        return switch (state) {
          DetailsLoading() => const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Loading details…'),
            ],
          ),
          DetailsError() => Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 18,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 6),
              const Expanded(child: Text('Could not load details.')),
              TextButton(
                onPressed: () =>
                    context.read<MovieDetailsCubit>().load(movieId),
                child: const Text('Retry'),
              ),
            ],
          ),
          DetailsLoaded(:final details) => Wrap(
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
          ),
        };
      },
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
