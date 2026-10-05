import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/favorites_repository_impl.dart';
import '../../data/repositories/music_repository_impl.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../data/services/audio_player_service.dart';
import '../../data/services/download_service.dart';
import '../../data/services/music_api_service.dart';
import '../../data/services/multi_source_music_service.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/repositories/music_repository.dart';
import '../../domain/repositories/playlist_repository.dart';

final musicApiServiceProvider = Provider<MusicApiService>((ref) {
  return MultiSourceMusicApiService();
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepositoryImpl();
});

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepositoryImpl();
});

final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  final api = ref.watch(musicApiServiceProvider);
  final favoritesRepo = ref.watch(favoritesRepositoryProvider);
  return MusicRepositoryImpl(
    apiService: api,
    favoritesRepository: favoritesRepo,
  );
});

final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService();
});

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
