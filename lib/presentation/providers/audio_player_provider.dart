import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/services/audio_player_service.dart';
import '../../domain/models/song.dart';
import 'service_providers.dart';

class PlayerStateData {
  final Song? currentSong;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  final List<Song> queue;
  final int currentIndex;
  final bool isShuffleEnabled;
  final LoopMode loopMode;
  final String? errorMessage;

  const PlayerStateData({
    this.currentSong,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.currentIndex = -1,
    this.isShuffleEnabled = false,
    this.loopMode = LoopMode.off,
    this.errorMessage,
  });

  PlayerStateData copyWith({
    Song? currentSong,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? bufferedPosition,
    Duration? duration,
    List<Song>? queue,
    int? currentIndex,
    bool? isShuffleEnabled,
    LoopMode? loopMode,
    String? errorMessage,
    bool clearCurrentSong = false,
  }) {
    return PlayerStateData(
      currentSong: clearCurrentSong ? null : (currentSong ?? this.currentSong),
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      loopMode: loopMode ?? this.loopMode,
      errorMessage: errorMessage,
    );
  }
}

class AudioPlayerNotifier extends StateNotifier<PlayerStateData> {
  final AudioPlayerService _service;
  final Ref? _ref;
  final List<StreamSubscription> _subscriptions = [];

  AudioPlayerNotifier(this._service, {Ref? ref})
      : _ref = ref,
        super(const PlayerStateData()) {
    _initListeners();
  }

  void _initListeners() {
    _subscriptions.add(
      _service.currentSongStream.listen((song) {
        state = state.copyWith(
          currentSong: song,
          clearCurrentSong: song == null,
        );
      }),
    );

    _subscriptions.add(
      _service.queueStream.listen((q) {
        state = state.copyWith(
          queue: q,
          currentIndex: _service.currentIndex,
        );
      }),
    );

    _subscriptions.add(
      _service.playerStateStream.listen((playerState) {
        final isPlaying = playerState.playing;
        final isBuffering = playerState.processingState == ProcessingState.buffering ||
            playerState.processingState == ProcessingState.loading;
        state = state.copyWith(
          isPlaying: isPlaying,
          isBuffering: isBuffering,
        );
      }),
    );

    _subscriptions.add(
      _service.positionStream.listen((pos) {
        state = state.copyWith(position: pos);
      }),
    );

    _subscriptions.add(
      _service.bufferedPositionStream.listen((buf) {
        state = state.copyWith(bufferedPosition: buf);
      }),
    );

    _subscriptions.add(
      _service.durationStream.listen((dur) {
        if (dur != null) {
          state = state.copyWith(duration: dur);
        }
      }),
    );

    _subscriptions.add(
      _service.loopModeStream.listen((loop) {
        state = state.copyWith(loopMode: loop);
      }),
    );

    _subscriptions.add(
      _service.shuffleModeEnabledStream.listen((shuffle) {
        state = state.copyWith(isShuffleEnabled: shuffle);
      }),
    );
  }

  Future<void> playSong(Song song, {List<Song>? playlist, int? index}) async {
    if (playlist != null && playlist.isNotEmpty) {
      final initialIdx = (index != null && index >= 0 && index < playlist.length)
          ? index
          : playlist.indexWhere((s) => s.id == song.id);
      await playPlaylist(playlist, initialIndex: initialIdx >= 0 ? initialIdx : 0);
      return;
    }

    try {
      state = state.copyWith(
        currentSong: song,
        currentIndex: 0,
        queue: [song],
        position: Duration.zero,
        duration: song.duration.inSeconds > 0 ? song.duration : state.duration,
        isBuffering: true,
        errorMessage: null,
      );
      await _service.playSong(song);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isBuffering: false,
        isPlaying: false,
        errorMessage: msg.isNotEmpty ? msg : 'تعذر تشغيل الأغنية، يرجى التأكد من الاتصال بالإنترنت',
      );
    }
  }

  /// Plays a single song (e.g. from search) and automatically creates an Auto-Radio
  /// queue of similar songs and songs by the same artist, so tapping Next plays related songs.
  Future<void> playSongWithRadio(Song song) async {
    try {
      state = state.copyWith(
        currentSong: song,
        currentIndex: 0,
        queue: [song],
        position: Duration.zero,
        duration: song.duration.inSeconds > 0 ? song.duration : state.duration,
        isBuffering: true,
        errorMessage: null,
      );
      await _service.playPlaylist([song], initialIndex: 0);

      // Asynchronously fetch related songs and populate upcoming queue
      if (_ref != null) {
        final repo = _ref.read(musicRepositoryProvider);
        final related = await repo.getRelatedSongs(song);
        final cleanRelated = related.where((s) => s.id != song.id).toList();
        if (cleanRelated.isNotEmpty) {
          final newQueue = [song, ...cleanRelated];
          _service.setQueue(newQueue, currentIndex: 0);
          state = state.copyWith(queue: newQueue, currentIndex: 0);
        }
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isBuffering: false,
        isPlaying: false,
        errorMessage: msg.isNotEmpty ? msg : 'تعذر تشغيل الأغنية',
      );
    }
  }

  Future<void> playPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    try {
      if (songs.isEmpty) return;
      final idx = (initialIndex >= 0 && initialIndex < songs.length) ? initialIndex : 0;
      final song = songs[idx];
      state = state.copyWith(
        currentSong: song,
        currentIndex: idx,
        queue: songs,
        position: Duration.zero,
        duration: song.duration.inSeconds > 0 ? song.duration : state.duration,
        isBuffering: true,
        errorMessage: null,
      );
      await _service.playPlaylist(songs, initialIndex: idx);
    } catch (e) {
      state = state.copyWith(
        isBuffering: false,
        errorMessage: 'تعذر تشغيل قائمة الأغاني',
      );
    }
  }

  Future<void> playOrPause() async {
    await _service.playOrPause();
  }

  Future<void> play() async {
    await _service.play();
  }

  Future<void> pause() async {
    await _service.pause();
  }

  Future<void> seek(Duration position) async {
    state = state.copyWith(position: position);
    await _service.seek(position);
  }

  Future<void> next() async {
    final q = state.queue.isNotEmpty ? state.queue : _service.queue;
    if (q.isEmpty) return;

    // If queue only has 1 song (e.g. single track play), fetch related radio tracks on the fly
    if (q.length == 1 && state.currentSong != null && _ref != null) {
      try {
        state = state.copyWith(isBuffering: true);
        final repo = _ref.read(musicRepositoryProvider);
        final related = await repo.getRelatedSongs(state.currentSong!);
        final cleanRelated = related.where((s) => s.id != state.currentSong!.id).toList();
        if (cleanRelated.isNotEmpty) {
          final newQueue = [state.currentSong!, ...cleanRelated];
          _service.setQueue(newQueue, currentIndex: 0);
          state = state.copyWith(queue: newQueue, currentIndex: 0);
          await skipToIndex(1);
          return;
        }
      } catch (_) {}
    }

    final nextIdx = (state.currentIndex >= 0 && state.currentIndex < q.length - 1)
        ? state.currentIndex + 1
        : 0;
    await skipToIndex(nextIdx);
  }

  Future<void> previous() async {
    final q = state.queue.isNotEmpty ? state.queue : _service.queue;
    if (q.isEmpty) return;
    if (state.position.inSeconds > 3) {
      state = state.copyWith(position: Duration.zero);
      await _service.seek(Duration.zero);
      return;
    }
    final prevIdx = (state.currentIndex > 0 && state.currentIndex < q.length)
        ? state.currentIndex - 1
        : (q.length - 1);
    await skipToIndex(prevIdx);
  }

  Future<void> skipToIndex(int index) async {
    final q = state.queue.isNotEmpty ? state.queue : _service.queue;
    if (index >= 0 && index < q.length) {
      final song = q[index];
      state = state.copyWith(
        currentSong: song,
        currentIndex: index,
        queue: q,
        position: Duration.zero,
        duration: song.duration.inSeconds > 0 ? song.duration : state.duration,
        isBuffering: true,
        errorMessage: null,
      );
      await _service.skipToIndex(index);
    }
  }

  Future<void> toggleShuffle() async {
    await _service.toggleShuffle();
  }

  Future<void> toggleLoopMode() async {
    await _service.toggleLoopMode();
  }

  void addToQueue(Song song) {
    _service.addToQueue(song);
  }

  void removeFromQueue(int index) {
    _service.removeFromQueue(index);
  }

  Future<void> closePlayer() async {
    await _service.stop();
    state = state.copyWith(clearCurrentSong: true, isPlaying: false);
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }
}

final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, PlayerStateData>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return AudioPlayerNotifier(service, ref: ref);
});
