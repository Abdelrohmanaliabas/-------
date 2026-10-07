import '../../domain/models/song.dart';
import '../../domain/models/artist.dart';
import '../../domain/models/album.dart';
import '../../domain/models/playlist.dart';
import '../../domain/models/genre.dart';
import '../../domain/repositories/music_repository.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../services/listening_history_service.dart';
import '../services/music_api_service.dart';

class MusicRepositoryImpl implements MusicRepository {
  final MusicApiService _apiService;
  final FavoritesRepository _favoritesRepository;

  MusicRepositoryImpl({
    required MusicApiService apiService,
    required FavoritesRepository favoritesRepository,
  })  : _apiService = apiService,
        _favoritesRepository = favoritesRepository;

  Future<List<Song>> _enrichSongsWithFavorites(List<Song> songs) async {
    final favorites = await _favoritesRepository.getFavorites();
    final favoriteIds = favorites.map((f) => f.id).toSet();
    return songs.map((s) => s.copyWith(isFavorite: favoriteIds.contains(s.id))).toList();
  }

  @override
  Future<List<Song>> getRecentlyPlayed() async {
    final history = await ListeningHistoryService.getRecentlyPlayed(limit: 15);
    if (history.isNotEmpty) {
      return _enrichSongsWithFavorites(history);
    }
    final songs = await _apiService.fetchRecentlyPlayed();
    return _enrichSongsWithFavorites(songs);
  }

  @override
  Future<List<Song>> getRecommendedSongs() async {
    final songs = await _apiService.fetchRecommendedSongs();
    return _enrichSongsWithFavorites(songs);
  }

  @override
  Future<List<Song>> getPopularSongs() async {
    final songs = await _apiService.fetchPopularSongs();
    return _enrichSongsWithFavorites(songs);
  }

  @override
  Future<List<Song>> getNewReleases() async {
    final songs = await _apiService.fetchNewReleases();
    return _enrichSongsWithFavorites(songs);
  }

  @override
  Future<List<Song>> getContinueListening() async {
    final songs = await _apiService.fetchContinueListening();
    return _enrichSongsWithFavorites(songs);
  }

  @override
  Future<List<Genre>> getGenres() {
    return _apiService.fetchGenres();
  }

  @override
  Future<List<Artist>> getFeaturedArtists() {
    return _apiService.fetchFeaturedArtists();
  }

  @override
  Future<List<Playlist>> getFeaturedPlaylists() {
    return _apiService.fetchFeaturedPlaylists();
  }

  @override
  Future<List<Song>> searchSongs(String query) async {
    final songs = await _apiService.searchSongs(query);
    return _enrichSongsWithFavorites(songs);
  }

  @override
  Future<List<Artist>> searchArtists(String query) {
    return _apiService.searchArtists(query);
  }

  @override
  Future<List<Album>> searchAlbums(String query) {
    return _apiService.searchAlbums(query);
  }

  @override
  Future<List<Playlist>> searchPlaylists(String query) {
    return _apiService.searchPlaylists(query);
  }

  @override
  Future<Song?> getSongById(String id) async {
    final song = await _apiService.getSongById(id);
    if (song == null) return null;
    final isFav = await _favoritesRepository.isFavorite(song.id);
    return song.copyWith(isFavorite: isFav);
  }

  @override
  Future<Artist?> getArtistById(String id) {
    return _apiService.getArtistById(id);
  }

  @override
  Future<List<Song>> getSongsByArtist(String artistId) async {
    final songs = await _apiService.getSongsByArtist(artistId);
    return _enrichSongsWithFavorites(songs);
  }

  @override
  Future<Album?> getAlbumById(String id) {
    return _apiService.getAlbumById(id);
  }

  @override
  Future<List<Song>> getSongsByAlbum(String albumId) async {
    final songs = await _apiService.getSongsByAlbum(albumId);
    return _enrichSongsWithFavorites(songs);
  }

  @override
  Future<List<Song>> getSongsByGenre(String genreId) async {
    final songs = await _apiService.getSongsByGenre(genreId);
    return _enrichSongsWithFavorites(songs);
  }

  @override
  Future<List<Song>> getRelatedSongs(Song song) async {
    final songs = await _apiService.getRelatedSongs(song);
    return _enrichSongsWithFavorites(songs);
  }
}
