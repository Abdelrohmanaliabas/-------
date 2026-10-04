import '../models/playlist.dart';
import '../models/song.dart';

abstract class PlaylistRepository {
  Future<List<Playlist>> getUserPlaylists();
  Future<Playlist?> getPlaylistById(String id);
  Future<Playlist> createPlaylist(String name, {String? description, String? artworkUrl});
  Future<void> renamePlaylist(String playlistId, String newName);
  Future<void> deletePlaylist(String playlistId);
  Future<void> addSongToPlaylist(String playlistId, Song song);
  Future<void> removeSongFromPlaylist(String playlistId, String songId);
}
