import 'package:flutter/material.dart';

/// Layout values shared by every movie list in the app.
///
/// Portrait shows one card per row; landscape shows two so the extra
/// width is used instead of stretching cards edge to edge.
int movieGridColumns(BuildContext context) =>
    MediaQuery.of(context).orientation == Orientation.landscape ? 2 : 1;

SliverGridDelegate movieGridDelegate(BuildContext context) {
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: movieGridColumns(context),
    crossAxisSpacing: 12,
    // Card content is 129px tall (12px padding * 2 + 105px poster) plus the
    // card's own 12px bottom margin.
    mainAxisExtent: 141,
  );
}
