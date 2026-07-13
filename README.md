# 🎬 Movies App

[![Release APK](https://github.com/Arksousi/movieslist/actions/workflows/release-apk.yml/badge.svg)](https://github.com/Arksousi/movieslist/actions/workflows/release-apk.yml)

A Flutter application that displays popular movies from [The Movie Database (TMDB)](https://www.themoviedb.org/), with infinite scrolling, search, offline support, and persistent favorites — built with **Clean Architecture**, **Cubit (flutter_bloc)** state management, and **get_it** dependency injection.

---

## 📥 Download

**[⬇️ Download the latest APK](https://github.com/Arksousi/movieslist/releases/latest/download/movies.apk)**

Every push to `main` rebuilds this APK and republishes it, so the link above always points at the newest build. Because all builds share one signing key, a new APK installs straight over the old app — your favorites and cached data are preserved.

---

## 🔄 Continuous Integration

`.github/workflows/release-apk.yml` runs on every push to `main` (and on demand via **Run workflow**):

1. **Analyze** — `flutter analyze`, plus `flutter test` if a `test/` directory exists. Pull requests stop here.
2. **Build & publish** — builds a signed release APK and rolls the `latest` GitHub Release forward. This job only runs if step 1 passes, so a broken build is never published.

`--build-number` is set from the workflow run number, giving each APK an increasing `versionCode` so Android treats it as an upgrade.

### Required repository secrets

Set these under **Settings → Secrets and variables → Actions**:

| Secret | What it is |
|---|---|
| `TMDB_TOKEN` | Your TMDB v4 read access token. CI writes it into `.env` at build time. |
| `ANDROID_KEYSTORE_BASE64` | The release keystore, base64-encoded. |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password. |
| `ANDROID_KEY_ALIAS` | Key alias (e.g. `upload`). |
| `ANDROID_KEY_PASSWORD` | Key password. |

### Generating the keystore (once)

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# PowerShell — base64 it for the ANDROID_KEYSTORE_BASE64 secret:
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
```

> ⚠️ **Back the `.jks` file up and never commit it.** All builds must be signed with the same key — if you lose it, future APKs can no longer install over an already-installed app; users would have to uninstall first and lose their local data. `.gitignore` blocks `*.jks`, `*.keystore`, and `android/key.properties`.

Locally, `android/key.properties` is absent, so release builds fall back to the debug key and `flutter run --release` keeps working with no setup.

> 🔓 **Note on the token:** `.env` is bundled into the APK as an asset, so `TMDB_TOKEN` is extractable from any published build. This is inherent to a client-side app — treat the token as public once shipped, not as a secret.

---

## ✅ Features

### Required
| Feature | How it's done |
|---|---|
| Fetch movies | TMDB `GET /movie/popular` via Dio |
| Movie list | Poster, title, 3-line overview, favorite heart on every card |
| Pagination | Infinite scroll — next page loads 400px before the bottom |
| Duplicate-call prevention | `isLoading`/`hasMore` guard + request generation counter |
| Loading indicators | Skeleton shimmer cards on first load, footer spinner on load-more |
| Error messages | Full-screen error view + inline "failed to load more", both with **Retry** |
| Favorites | Add / remove from any screen, instant sync everywhere |
| Local persistence | Favorites stored in a **SQLite database** — survive app restarts |
| Navigation | Bottom `NavigationBar` with Movies and Favorites tabs |

### Bonus
| Feature | How it's done |
|---|---|
| 🔍 Search | Debounced (400ms) app-bar search → `/search/movie`, fully paginated |
| 🔄 Pull to refresh | `RefreshIndicator` on the movie list |
| 🌙 Dark mode | `darkTheme` + `ThemeMode.system` — follows the device setting |
| 💀 Skeleton loading | Animated shimmer placeholder cards |
| 🔁 Retry buttons | On both first-page and load-more failures |
| 📄 Details screen | Rating, year, runtime, genres from `/movie/{id}` |
| 📴 **Offline mode** | The SQLite database caches every API response — the app works without internet |
| 📱 Orientation support | 1-column list in portrait, 2-column grid in landscape; details screen switches to a side-by-side layout |

---

## 🚀 Getting Started

### 1. Prerequisites
- Flutter SDK (stable channel)
- A free TMDB account with an **API Read Access Token (v4)** — create one at
  [themoviedb.org → Settings → API](https://www.themoviedb.org/settings/api)

### 2. Configure the API token
Create a file named `.env` in the project root (it is git-ignored, so your token is never committed):

```env
TMDB_TOKEN=your_tmdb_v4_read_access_token_here
```

### 3. Run

```bash
flutter pub get
flutter run
```

> **Android emulator note:** if TMDB requests time out on an emulator, start it with an explicit DNS server:
> `emulator -avd <name> -dns-server 8.8.8.8`

---

## 🏗️ Architecture

The app follows **Clean Architecture** with three layers. The golden rule: **dependencies only point inward** — the domain layer knows nothing about Flutter, Dio, Hive, or SharedPreferences.

```
┌─────────────────── PRESENTATION ───────────────────┐
│   Screens & Widgets ──BlocBuilder──► Cubits        │  Flutter + flutter_bloc
└─────────────────────────┬──────────────────────────┘
                          │ calls use cases
┌─────────────────── DOMAIN ─────────────────────────┐
│   Use cases ──► Repository interfaces              │  pure Dart
│   Entities: Movie, MovieDetails, MoviePage         │
└─────────────────────────┬──────────────────────────┘
                          │ interfaces implemented by
┌─────────────────── DATA ───────────────────────────┐
│   Repository implementations                       │
│    ├─ MovieRemoteDataSource   → Dio / TMDB API     │
│    ├─ MovieLocalDataSource    → SQLite (offline)   │
│    └─ FavoritesLocalDataSource→ SQLite (favorites) │
└────────────────────────────────────────────────────┘
```

### Project structure

```
lib/
├── main.dart                          # entry point + MultiBlocProvider + tabs
├── core/
│   ├── di/
│   │   └── injector.dart              # get_it service locator — wires everything
│   └── database/
│       └── app_database.dart          # SQLite schema: movies, favorites,
│                                      #   page_cache, movie_details
├── domain/                            # ── PURE DART, no frameworks ──
│   ├── entities/
│   │   ├── movie.dart                 # id, title, overview, posterPath
│   │   ├── movie_details.dart         # rating, year, runtime, genres
│   │   └── movie_page.dart            # one page of results + hasMore
│   ├── repositories/
│   │   ├── movie_repository.dart      # contract: getPopular / search / getDetails
│   │   └── favorites_repository.dart  # contract: getFavorites / add / remove
│   └── usecases/                      # one class per business action
│       ├── get_popular_movies.dart
│       ├── search_movies.dart
│       ├── get_movie_details.dart
│       ├── get_favorite_movies.dart
│       ├── add_favorite.dart
│       └── remove_favorite.dart
├── data/
│   ├── models/                        # entities + JSON (extend the entities)
│   │   ├── movie_model.dart
│   │   ├── movie_details_model.dart
│   │   └── movie_page_model.dart
│   ├── datasources/
│   │   ├── movie_remote_data_source.dart    # Dio: the only file that knows TMDB
│   │   ├── movie_local_data_source.dart     # SQLite: offline response cache
│   │   └── favorites_local_data_source.dart # SQLite: favorites table
│   └── repositories/
│       ├── movie_repository_impl.dart       # network-first + cache fallback
│       └── favorites_repository_impl.dart   # load-modify-save
└── presentation/
    ├── cubits/
    │   ├── movies/            # MoviesCubit + MoviesState (list, pagination, search)
    │   ├── movie_details/     # MovieDetailsCubit + sealed states
    │   └── favorites/         # FavoritesCubit + FavoritesState (shared app-wide)
    ├── screens/
    │   ├── movies_screen.dart
    │   ├── favorites_screen.dart
    │   └── movie_details_screen.dart
    └── widgets/
        ├── movie_card.dart
        ├── skeleton_movie_card.dart
        └── movie_grid.dart    # 1 column portrait / 2 columns landscape
```

---

## ⚙️ How everything works

### App startup
1. `main()` calls `initDependencies()` ([lib/core/di/injector.dart](lib/core/di/injector.dart)) — the **composition root**. get_it registers the whole graph bottom-up: SQLite database → data sources → repositories (bound to their **domain interfaces**) → use cases → cubits.
2. `FavoritesCubit.load()` reads persisted favorites into memory.
3. `runApp` wraps the app in a `MultiBlocProvider`; `MoviesCubit` immediately loads page 1.
4. `HomeScreen` hosts the two tabs in an `IndexedStack`, so the movie list keeps its scroll position while you visit Favorites.

### Dependency injection (get_it)
- `registerSingleton` — built upfront (the SQLite `Database` — opening it needs `await`).
- `registerLazySingleton` — one shared instance, built on first use (data sources, repositories, use cases, `FavoritesCubit` — favorites are one app-wide truth).
- `registerFactory` — fresh instance per request (`MoviesCubit`, `MovieDetailsCubit` — each screen gets its own state).

Repositories are registered **by interface** (`sl.registerLazySingleton<MovieRepository>(() => MovieRepositoryImpl(...))`), so the rest of the app never sees a concrete class — swap in a fake for testing without touching anything else.

### Pagination (MoviesCubit)
```
scroll near bottom → loadNextPage()
  ├─ guard: if (isLoading || !hasMore) return   ← prevents duplicate calls
  ├─ fetch page currentPage + 1
  └─ emit: movies + new page, hasMore = page < totalPages
```

### Search
Typing is debounced 400ms in the widget; the cubit resets the list and switches the use case from `GetPopularMovies` to `SearchMovies`. A **generation counter** discards responses from stale in-flight requests (e.g. the response for "mat" arriving after you already searched "matrix").

### Favorites flow
```
tap ♥ → FavoritesCubit.toggle(movie)
  ├─ emit new state FIRST  → every heart in the app updates instantly
  └─ then persist: AddFavorite/RemoveFavorite use case
        → FavoritesRepositoryImpl
        → FavoritesLocalDataSource → SQLite (upsert into movies,
          insert/delete in favorites; loading JOINs the two tables)
```
Hearts use `context.select(...)`, so each card rebuilds only when *its own* movie's flag changes.

### Offline mode (SQLite)
`MovieRepositoryImpl` is **network-first with cache fallback**:
```
try TMDB ── success ──► cache in SQLite ──► return fresh data
   └── DioException ──► cached copy exists? ── yes ──► return cached data
                                └────────────── no ───► friendly error + Retry
```
The schema ([app_database.dart](lib/core/database/app_database.dart)) is relational: one shared `movies` table, with `favorites` and `page_cache` referencing it by id (`page_cache` keeps the API ordering via a `position` column and keys like `popular_1` / `search_matrix_2`), and a `movie_details` table for the extras. Reads JOIN the tables back into entities.
Because this lives behind the `MovieRepository` interface, **no UI or domain code changed** to gain offline support.

### Details screen
Opens instantly with the data it already has (title/poster/overview from the list), while a per-screen `MovieDetailsCubit` fetches rating/year/runtime/genres. Its state is a **sealed class** (`DetailsLoading / DetailsLoaded / DetailsError`) rendered with an exhaustive `switch`.

### Orientation
- Lists: `movieGridDelegate` → 1 column in portrait, 2 in landscape.
- Details: `OrientationBuilder` → poster above the info (portrait) or beside it (landscape).

### Error handling
`DioException`s never reach the UI — the repository translates them into friendly messages (`Invalid TMDB token` for 401, offline message otherwise). Every load path has loading, error + Retry, and empty states. Missing/failed poster images fall back to a placeholder.

---

## 📦 Packages

| Package | Purpose |
|---|---|
| `dio` | HTTP client for the TMDB API |
| `flutter_bloc` | Cubit state management |
| `get_it` | Dependency injection (service locator) |
| `sqflite` | SQLite database — favorites persistence + offline response cache |
| `flutter_dotenv` | Loads the TMDB token from `.env` |

---

## 🧪 Verifying the app

1. **Pagination** — scroll to the bottom: a spinner appears and the next page loads; keep scrolling, no duplicates.
2. **Search** — type "matrix": results replace the list; clear to return to Popular.
3. **Favorites** — tap a heart, check the Favorites tab, restart the app: still there.
4. **Offline** — load the list once, enable airplane mode, kill and reopen the app: movies load from the Hive cache; a movie whose details you visited shows its chips offline too.
5. **Orientation** — rotate the device: the list becomes a 2-column grid; the details screen goes side-by-side.
