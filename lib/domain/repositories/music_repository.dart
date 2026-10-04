import '../models/song.dart';
import '../models/artist.dart';
import '../models/album.dart';
import '../models/playlist.dart';
import '../models/genre.dart';

abstract class MusicRepository {
  Future<List<Song>> getRecentlyPlayed();
  Future<List<Song>> getRecommendedSongs();
  Future<List<Song>> getPopularSongs();
  Future<List<Song>> getNewReleases();
  Future<List<Song>> getContinueListening();
  Future<List<Genre>> getGenres();
  Future<List<Artist>> getFeaturedArtists();
  Future<List<Playlist>> getFeaturedPlaylists();
  
  Future<List<Song>> searchSongs(String query);
  Future<List<Artist>> searchArtists(String query);
  Future<List<Album>> searchAlbums(String query);
  
  Future<Song?> getSongById(String id);
  Future<Artist?> getArtistById(String id);
  Future<List<Song>> getSongsByArtist(String artistId);
  Future<Album?> getAlbumById(String id);
  Future<List<Song>> getSongsByAlbum(String albumId);
  Future<List<Song>> getSongsByGenre(String genreId);
}
