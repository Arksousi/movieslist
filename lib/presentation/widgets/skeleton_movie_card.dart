import 'package:flutter/material.dart';

/// A shimmering placeholder shaped like a MovieCard, shown while the
/// first page of movies is loading.
class SkeletonMovieCard extends StatefulWidget {
  const SkeletonMovieCard({super.key});

  @override
  State<SkeletonMovieCard> createState() => _SkeletonMovieCardState();
}

class _SkeletonMovieCardState extends State<SkeletonMovieCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlight = Theme.of(context).colorScheme.surfaceContainerHigh;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimmerBox(
              width: 70,
              height: 105,
              base: base,
              highlight: highlight,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(
                    width: double.infinity,
                    height: 16,
                    base: base,
                    highlight: highlight,
                  ),
                  const SizedBox(height: 8),
                  _shimmerBox(
                    width: double.infinity,
                    height: 12,
                    base: base,
                    highlight: highlight,
                  ),
                  const SizedBox(height: 6),
                  _shimmerBox(
                    width: double.infinity,
                    height: 12,
                    base: base,
                    highlight: highlight,
                  ),
                  const SizedBox(height: 6),
                  _shimmerBox(
                    width: 140,
                    height: 12,
                    base: base,
                    highlight: highlight,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    required Color base,
    required Color highlight,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (rect) {
              final t = _controller.value;
              return LinearGradient(
                colors: [base, highlight, base],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment(-1.0 + 3.0 * t, 0),
                end: Alignment(0.0 + 3.0 * t, 0),
              ).createShader(rect);
            },
            child: Container(width: width, height: height, color: base),
          ),
        );
      },
    );
  }
}
