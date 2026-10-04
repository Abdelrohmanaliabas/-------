import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/download_service.dart';
import '../../domain/models/song.dart';
import 'service_providers.dart';

class DownloadsNotifier extends StateNotifier<AsyncValue<List<Song>>> {
  final DownloadService _service;

  DownloadsNotifier(this._service) : super(const AsyncValue.loading()) {
    loadDownloads();
  }

  Future<void> loadDownloads() async {
    try {
      state = const AsyncValue.loading();
      final songs = await _service.getDownloadedSongs();
      state = AsyncValue.data(songs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> downloadSong(Song song) async {
    try {
      final downloaded = await _service.downloadSong(song);
      if (downloaded != null) {
        final current = state.value ?? [];
        state = AsyncValue.data([downloaded, ...current.where((s) => s.id != downloaded.id)]);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDownload(String songId) async {
    try {
      await _service.deleteDownloadedSong(songId);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((s) => s.id != songId).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool isDownloaded(String songId) {
    return state.value?.any((s) => s.id == songId) ?? false;
  }
}

final downloadsProvider =
    StateNotifierProvider<DownloadsNotifier, AsyncValue<List<Song>>>((ref) {
  final service = ref.watch(downloadServiceProvider);
  return DownloadsNotifier(service);
});

final downloadProgressStreamProvider =
    StreamProvider.autoDispose<Map<String, double>>((ref) {
  final service = ref.watch(downloadServiceProvider);
  return service.progressStream;
});
