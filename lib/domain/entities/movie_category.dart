/// A browsable movie list. The API path and the display label are mapped in
/// the data and presentation layers respectively, so the domain stays free of
/// both TMDB and UI concerns.
enum MovieCategory { popular, topRated, nowPlaying, upcoming }
