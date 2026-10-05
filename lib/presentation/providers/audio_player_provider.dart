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
  final List<StreamSubscription> _subscriptions = [];

  AudioPlayerNotifier(this._service) : super(const PlayerStateData()) {
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

  Future<void> playSong(Song song, {List<Song>? playlist}) async {
    try {
      state = state.copyWith(
        currentSong: song,
        position: Duration.zero,
        duration: song.duration.inSeconds > 0 ? song.duration : state.duration,
        isBuffering: true,
        errorMessage: null,
      );
      await _service.playSong(song, playlist: playlist);
    } catch (e) {
      state = state.copyWith(
        isBuffering: false,
        errorMessage: 'تعذر تشغيل الأغنية، يرجى التأكد من الاتصال بالإنترنت',
      );
    }
  }

  Future<void> playPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    try {
      if (songs.isEmpty) return;
      final song = songs[initialIndex];
      state = state.copyWith(
        currentSong: song,
        position: Duration.zero,
        duration: song.duration.inSeconds > 0 ? song.duration : state.duration,
        isBuffering: true,
        errorMessage: null,
      );
      await _service.playPlaylist(songs, initialIndex: initialIndex);
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
    await _service.skipToNext();
  }

  Future<void> previous() async {
    await _service.skipToPrevious();
  }

  Future<void> skipToIndex(int index) async {
    await _service.skipToIndex(index);
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
  return AudioPlayerNotifier(service);
});
