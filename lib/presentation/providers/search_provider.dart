import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/album.dart';
import '../../domain/models/artist.dart';
import '../../domain/models/playlist.dart';
import '../../domain/models/song.dart';
import 'service_providers.dart';

enum SearchFilter {
  all,
  songs,
  artists,
  albums,
  playlists,
}

class SearchResults {
  final String query;
  final List<Song> songs;
  final List<Artist> artists;
  final List<Album> albums;
  final List<Playlist> playlists;
  final bool isLoading;
  final String? error;

  const SearchResults({
    this.query = '',
    this.songs = const [],
    this.artists = const [],
    this.albums = const [],
    this.playlists = const [],
    this.isLoading = false,
    this.error,
  });

  bool get isEmpty =>
      !isLoading &&
      query.isNotEmpty &&
      songs.isEmpty &&
      artists.isEmpty &&
      albums.isEmpty &&
      playlists.isEmpty;

  bool get hasContent =>
      songs.isNotEmpty ||
      artists.isNotEmpty ||
      albums.isNotEmpty ||
      playlists.isNotEmpty;
}

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchFilterProvider = StateProvider<SearchFilter>((ref) => SearchFilter.all);

final searchResultsProvider = FutureProvider.autoDispose<SearchResults>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) {
    return const SearchResults();
  }

  final repo = ref.watch(musicRepositoryProvider);

  try {
    final results = await Future.wait([
      repo.searchSongs(query),
      repo.searchArtists(query),
      repo.searchAlbums(query),
      repo.searchPlaylists(query),
    ]);

    return SearchResults(
      query: query,
      songs: results[0] as List<Song>,
      artists: results[1] as List<Artist>,
      albums: results[2] as List<Album>,
      playlists: results[3] as List<Playlist>,
      isLoading: false,
    );
  } catch (e) {
    return SearchResults(
      query: query,
      isLoading: false,
      error: 'حدث خطأ أثناء البحث، يرجى المحاولة مرة أخرى',
    );
  }
});

