import '../../domain/models/song.dart';
import '../../domain/models/artist.dart';
import '../../domain/models/album.dart';
import '../../domain/models/playlist.dart';
import '../../domain/models/genre.dart';
import '../mock/sample_music_data.dart';

abstract class MusicApiService {
  Future<List<Song>> fetchRecentlyPlayed();
  Future<List<Song>> fetchRecommendedSongs();
  Future<List<Song>> fetchPopularSongs();
  Future<List<Song>> fetchNewReleases();
  Future<List<Song>> fetchContinueListening();
  Future<List<Genre>> fetchGenres();
  Future<List<Artist>> fetchFeaturedArtists();
  Future<List<Playlist>> fetchFeaturedPlaylists();
  
  Future<List<Song>> searchSongs(String query);
  Future<List<Artist>> searchArtists(String query);
  Future<List<Album>> searchAlbums(String query);
  Future<List<Playlist>> searchPlaylists(String query);

  Future<Song?> getSongById(String id);
  Future<Artist?> getArtistById(String id);
  Future<List<Song>> getSongsByArtist(String artistId);
  Future<Album?> getAlbumById(String id);
  Future<List<Song>> getSongsByAlbum(String albumId);
  Future<List<Song>> getSongsByGenre(String genreId);
  Future<List<Song>> getRelatedSongs(Song song);
}

/// Mock implementation that simulates network latency and serves demo catalog.
/// Easily swappable with a real HTTP/REST API service by implementing MusicApiService.
class MockMusicApiService implements MusicApiService {
  final int latencyMs;

  const MockMusicApiService({this.latencyMs = 300});

  Future<void> _simulateDelay() async {
    if (latencyMs > 0) {
      await Future.delayed(Duration(milliseconds: latencyMs));
    }
  }

  @override
  Future<List<Song>> fetchRecentlyPlayed() async {
    await _simulateDelay();
    return [
      SampleMusicData.songs[0],
      SampleMusicData.songs[1],
      SampleMusicData.songs[3],
      SampleMusicData.songs[4],
    ];
  }

  @override
  Future<List<Song>> fetchRecommendedSongs() async {
    await _simulateDelay();
    return SampleMusicData.songs;
  }

  @override
  Future<List<Song>> fetchPopularSongs() async {
    await _simulateDelay();
    final sorted = List<Song>.from(SampleMusicData.songs)
      ..sort((a, b) => b.playsCount.compareTo(a.playsCount));
    return sorted;
  }

  @override
  Future<List<Song>> fetchNewReleases() async {
    await _simulateDelay();
    return [
      SampleMusicData.songs[1],
      SampleMusicData.songs[3],
      SampleMusicData.songs[5],
      SampleMusicData.songs[6],
    ];
  }

  @override
  Future<List<Song>> fetchContinueListening() async {
    await _simulateDelay();
    return [
      SampleMusicData.songs[2],
      SampleMusicData.songs[6],
    ];
  }

  @override
  Future<List<Genre>> fetchGenres() async {
    await _simulateDelay();
    return SampleMusicData.genres;
  }

  @override
  Future<List<Artist>> fetchFeaturedArtists() async {
    await _simulateDelay();
    return SampleMusicData.artists;
  }

  @override
  Future<List<Playlist>> fetchFeaturedPlaylists() async {
    await _simulateDelay();
    return SampleMusicData.playlists;
  }

  @override
  Future<List<Song>> searchSongs(String query) async {
    await _simulateDelay();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return SampleMusicData.songs.where((s) {
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          s.album.toLowerCase().contains(q) ||
          s.genre.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<List<Artist>> searchArtists(String query) async {
    await _simulateDelay();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return SampleMusicData.artists.where((a) {
      return a.name.toLowerCase().contains(q) ||
          (a.bio?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Future<List<Album>> searchAlbums(String query) async {
    await _simulateDelay();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return SampleMusicData.albums.where((al) {
      return al.title.toLowerCase().contains(q) ||
          al.artist.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<List<Playlist>> searchPlaylists(String query) async {
    await _simulateDelay();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return SampleMusicData.curatedPlaylists.where((pl) {
      return pl.name.toLowerCase().contains(q) ||
          (pl.description?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Future<Song?> getSongById(String id) async {
    await _simulateDelay();
    try {
      return SampleMusicData.songs.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Artist?> getArtistById(String id) async {
    await _simulateDelay();
    try {
      return SampleMusicData.artists.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Song>> getSongsByArtist(String artistId) async {
    await _simulateDelay();
    return SampleMusicData.songs.where((s) => s.artistId == artistId).toList();
  }

  @override
  Future<Album?> getAlbumById(String id) async {
    await _simulateDelay();
    try {
      return SampleMusicData.albums.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Song>> getSongsByAlbum(String albumId) async {
    await _simulateDelay();
    return SampleMusicData.songs.where((s) => s.albumId == albumId).toList();
  }

  @override
  Future<List<Song>> getSongsByGenre(String genreId) async {
    await _simulateDelay();
    final genre = SampleMusicData.genres.firstWhere(
      (g) => g.id == genreId,
      orElse: () => SampleMusicData.genres.first,
    );
    return SampleMusicData.songs.where((s) => s.genre == genre.name).toList();
  }

  @override
  Future<List<Song>> getRelatedSongs(Song song) async {
    await _simulateDelay();
    return SampleMusicData.songs.where((s) => s.id != song.id).toList();
  }
}
