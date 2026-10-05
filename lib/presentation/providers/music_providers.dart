import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/artist.dart';
import '../../domain/models/genre.dart';
import '../../domain/models/playlist.dart';
import '../../domain/models/song.dart';
import '../../data/services/listening_history_service.dart';
import 'service_providers.dart';

final recentlyPlayedSongsProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(musicRepositoryProvider);
  return repo.getRecentlyPlayed();
});

final recommendedSongsProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(musicRepositoryProvider);
  return repo.getRecommendedSongs();
});

final popularSongsProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(musicRepositoryProvider);
  return repo.getPopularSongs();
});

final newReleasesProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(musicRepositoryProvider);
  return repo.getNewReleases();
});

final continueListeningProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(musicRepositoryProvider);
  return repo.getContinueListening();
});

final genresProvider = FutureProvider<List<Genre>>((ref) async {
  final repo = ref.watch(musicRepositoryProvider);
  return repo.getGenres();
});

final featuredArtistsProvider = FutureProvider<List<Artist>>((ref) async {
  final repo = ref.watch(musicRepositoryProvider);
  return repo.getFeaturedArtists();
});

final featuredPlaylistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final repo = ref.watch(musicRepositoryProvider);
  return repo.getFeaturedPlaylists();
});

final songsByArtistProvider = FutureProvider.family<List<Song>, String>((ref, artistId) async {
  final repo = ref.watch(musicRepositoryProvider);
  return repo.getSongsByArtist(artistId);
});

final songsByAlbumProvider = FutureProvider.family<List<Song>, String>((ref, albumId) async {
  final repo = ref.watch(musicRepositoryProvider);
  return repo.getSongsByAlbum(albumId);
});

final songsByGenreProvider = FutureProvider.family<List<Song>, String>((ref, genreId) async {
  final repo = ref.watch(musicRepositoryProvider);
  return repo.getSongsByGenre(genreId);
});

final completedSongsProvider = FutureProvider<List<Song>>((ref) async {
  final songs = await ListeningHistoryService.getCompletedSongs();
  return songs;
});

final relatedToListeningProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(musicRepositoryProvider);
  final lastPlayed = await ListeningHistoryService.getLastPlayedSong();
  if (lastPlayed != null) {
    final related = await repo.getRelatedSongs(lastPlayed);
    if (related.isNotEmpty) return related;
  }
  return repo.getRecommendedSongs();
});

